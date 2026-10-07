// profile_provider.dart — Rewritten to use Riverpod v3 (Notifier) + Supabase.
// No Firestore, no StateNotifier, no missing deps.

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_profile.dart';

// ── Current partner profile from Supabase ──────────────────────────────────
final currentProfileProvider = FutureProvider.autoDispose<UserProfile?>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;

  final profile = await Supabase.instance.client
      .from('profiles')
      .select('*, partners(*)')
      .eq('auth_user_id', user.id)
      .maybeSingle();

  if (profile == null) return null;
  
  final rawPartners = profile['partners'];
  Map<String, dynamic> partner = {};
  if (rawPartners is List && rawPartners.isNotEmpty) {
    partner = rawPartners[0] as Map<String, dynamic>;
  } else if (rawPartners is Map) {
    partner = Map<String, dynamic>.from(rawPartners);
  }
  final merged = {...partner, ...profile};
  
  return UserProfile.fromMap(merged);
});

// ── Profile update controller ──────────────────────────────────────────────
final profileControllerProvider =
    NotifierProvider<ProfileController, AsyncValue<void>>(ProfileController.new);

class ProfileController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> updateProfile({
    required String fullName,
    required String city,
    String? whatsappNumber,
    String? email,
    String? state,
    String? language,
    File? imageFile,
    required void Function() onSuccess,
    required void Function(String) onError,
  }) async {
    this.state = const AsyncValue.loading();
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        this.state = const AsyncValue.data(null);
        onError('User not authenticated.');
        return;
      }

      String? imageUrl;
      if (imageFile != null) {
        final path = 'profiles/${user.id}/avatar.jpg';
        await Supabase.instance.client.storage
            .from('partner-documents')
            .upload(path, imageFile, fileOptions: const FileOptions(upsert: true));
        imageUrl = Supabase.instance.client.storage
            .from('partner-documents')
            .getPublicUrl(path);
      }

      final updates = <String, dynamic>{
        'full_name': fullName,
        'city': city,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (whatsappNumber != null) updates['whatsapp_number'] = whatsappNumber;
      if (email != null) updates['email'] = email;
      if (state != null) updates['state'] = state;
      if (language != null) updates['language'] = language;
      if (imageUrl != null) updates['profile_photo_url'] = imageUrl;

      final profileResp = await Supabase.instance.client
          .from('profiles')
          .update({
            'full_name': fullName,
            'city': city,
            if (email != null) 'email': email,
            if (imageUrl != null) 'profile_photo_url': imageUrl,
          })
          .eq('auth_user_id', user.id)
          .select('id')
          .maybeSingle();

      if (profileResp != null) {
        await Supabase.instance.client
            .from('partners')
            .update(updates)
            .eq('profile_id', profileResp['id']);
      }

      ref.invalidate(currentProfileProvider);
      this.state = const AsyncValue.data(null);
      onSuccess();
    } catch (e) {
      this.state = AsyncValue.error(e, StackTrace.current);
      onError('Failed to update profile. Please try again.');
    }
  }
}
