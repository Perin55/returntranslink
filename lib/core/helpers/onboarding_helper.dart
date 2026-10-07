// lib/core/helpers/onboarding_helper.dart
// Checks how far the user has completed onboarding and returns the correct route.
// Step 1: Profile complete (owner_name != 'Pending' && != null)
// Step 2: At least one truck added
// Step 3: At least one document uploaded for that truck

import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingHelper {
  static final _supabase = Supabase.instance.client;
  static bool _isOnboardedCached = false;
  static String? _cachedUserId;

  static bool get isOnboarded => _isOnboardedCached;

  static void resetCache() {
    _isOnboardedCached = false;
    _cachedUserId = null;
  }

  /// Returns the route the user should be on based on their onboarding progress.
  /// '/dashboard'       → all 3 steps done
  /// '/document_upload' → step 3 incomplete
  /// '/add_vehicle'     → step 2 incomplete
  /// '/profile_setup'   → step 1 incomplete
  /// '/login'           → not logged in
  static Future<String> getOnboardingRoute() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        _isOnboardedCached = false;
        _cachedUserId = null;
        return '/login';
      }

      // If user is already verified onboarded in current session, immediately return dashboard
      if (_isOnboardedCached && _cachedUserId == user.id) {
        return '/dashboard';
      }

      // Fetch profile + nested partner + nested trucks + nested truck_documents
      final profileResp = await _supabase
          .from('profiles')
          .select('id, full_name, mobile_number, city, partners(id, owner_name, trucks(id, truck_documents(id)))')
          .eq('auth_user_id', user.id)
          .maybeSingle();

      if (profileResp == null) return '/profile_setup';

      final partnersRaw = profileResp['partners'];
      Map<String, dynamic>? partner;
      if (partnersRaw is List && partnersRaw.isNotEmpty) {
        partner = partnersRaw[0] as Map<String, dynamic>;
      } else if (partnersRaw is Map) {
        partner = Map<String, dynamic>.from(partnersRaw);
      }

      if (partner == null) return '/profile_setup';

      final ownerName = partner['owner_name'] as String?;

      // Step 1 check: Profile complete?
      final fullName = profileResp['full_name'] as String?;
      if (ownerName == null || ownerName == 'Pending' || ownerName.trim().isEmpty ||
          fullName == null || fullName == 'Pending' || fullName.trim().isEmpty) {
        return '/profile_setup';
      }

      // Step 2 check: Truck added?
      final trucksRaw = partner['trucks'];
      List<dynamic> trucks = [];
      if (trucksRaw is List) {
        trucks = trucksRaw;
      } else if (trucksRaw is Map) {
        trucks = [trucksRaw];
      }

      if (trucks.isEmpty) return '/add_vehicle';

      // Step 3 check: Documents uploaded?
      final truck = trucks[0];
      final truckId = truck['id'];
      final truckDocs = truck['truck_documents'] as List?;
      
      bool hasDocs = truckDocs != null && truckDocs.isNotEmpty;
      if (!hasDocs && truckId != null) {
        // Fallback check: check documents table or direct truck_documents count
        try {
          final docCount = await _supabase
              .from('truck_documents')
              .select('id')
              .eq('truck_id', truckId)
              .limit(1);
          if ((docCount as List).isNotEmpty) {
            hasDocs = true;
          }
        } catch (_) {}

        if (!hasDocs) {
          try {
            final oldDocCount = await _supabase
                .from('documents')
                .select('id')
                .eq('partner_id', partner['id'])
                .limit(1);
            if ((oldDocCount as List).isNotEmpty) {
              hasDocs = true;
            }
          } catch (_) {}
        }
      }

      if (!hasDocs) return '/document_upload';

      // All done!
      _isOnboardedCached = true;
      _cachedUserId = user.id;
      return '/dashboard';
    } catch (e) {
      print('OnboardingHelper error: $e');
      return '/profile_setup';
    }
  }
}
