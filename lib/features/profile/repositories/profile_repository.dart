// profile_repository.dart — Rewritten to use Supabase only.
// No Firestore, no Firebase Storage (uses Supabase Storage).

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});

class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository(this._supabase);

  Future<UserProfile?> getUserProfile(String authId) async {
    try {
      final profile = await _supabase
          .from('profiles')
          .select('*, partners(*)')
          .eq('auth_user_id', authId)
          .maybeSingle();
      if (profile == null) return null;
      final rawPartners = profile['partners'];
      Map<String, dynamic> partner = {};
      if (rawPartners is List && rawPartners.isNotEmpty) {
        partner = rawPartners[0] as Map<String, dynamic>;
      } else if (rawPartners is Map) {
        partner = Map<String, dynamic>.from(rawPartners);
      }
      final data = {...partner, ...profile};
      return UserProfile.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  Future<void> createUserProfile(UserProfile profile) async {
    final profileResp = await _supabase.from('profiles').upsert({
      'auth_user_id': profile.uid,
      'full_name': profile.fullName,
      'mobile_number': profile.phoneNumber,
      'city': profile.city,
      if (profile.profileImageUrl != null) 'profile_photo_url': profile.profileImageUrl,
    }, onConflict: 'auth_user_id').select('id').maybeSingle();
    
    if (profileResp != null) {
      await _supabase.from('partners').insert({
        'profile_id': profileResp['id'],
        'owner_name': profile.fullName,
        'mobile_number': profile.phoneNumber,
        'city': profile.city,
        if (profile.profileImageUrl != null) 'profile_photo_url': profile.profileImageUrl,
        'status': 'NEW',
      });
    }
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    final profileResp = await _supabase.from('profiles').update({
      'full_name': profile.fullName,
      'city': profile.city,
      if (profile.profileImageUrl != null) 'profile_photo_url': profile.profileImageUrl,
    }).eq('auth_user_id', profile.uid).select('id').maybeSingle();

    if (profileResp != null) {
      await _supabase.from('partners').update({
        'owner_name': profile.fullName,
        'city': profile.city,
        if (profile.profileImageUrl != null) 'profile_photo_url': profile.profileImageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('profile_id', profileResp['id']);
    }
  }

  Future<String> uploadProfileImage(String uid, File imageFile) async {
    final path = 'profiles/$uid/avatar.jpg';
    await _supabase.storage
        .from('partner-documents')
        .upload(path, imageFile, fileOptions: const FileOptions(upsert: true));
    return _supabase.storage.from('partner-documents').getPublicUrl(path);
  }
}
