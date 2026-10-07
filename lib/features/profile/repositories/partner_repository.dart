import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/partner_model.dart';
import '../models/partner_profile_model.dart';
import '../models/truck_model.dart';
import '../models/return_requirement_model.dart';
import '../models/partner_document_model.dart';
import '../models/truck_document_model.dart';
import '../models/contact_event_model.dart';

final partnerRepositoryProvider = Provider<PartnerRepository>((ref) {
  return PartnerRepository(Supabase.instance.client);
});

class PartnerRepository {
  final SupabaseClient _supabase;

  PartnerRepository(this._supabase);

  Future<Partner?> getPartnerById(String id) async {
    try {
      final response = await _supabase
          .from('partners')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        return Partner.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error fetching partner: $e');
      return null;
    }
  }

  Future<void> createPartner(Partner partner) async {
    try {
      await _supabase.from('partners').insert(partner.toJson());
    } catch (e) {
      print('Error creating partner: $e');
      rethrow;
    }
  }

  Future<PartnerProfile?> getPartnerProfile(String partnerId) async {
    try {
      // partnerId here is the auth_user_id
      final profileResp = await _supabase
          .from('profiles')
          .select()
          .eq('auth_user_id', partnerId)
          .maybeSingle();

      if (profileResp == null) return null;

      final partnerResp = await _supabase
          .from('partners')
          .select()
          .eq('profile_id', profileResp['id'])
          .maybeSingle();

      if (partnerResp != null) {
        final merged = {...partnerResp, ...profileResp, 'id': profileResp['auth_user_id']};
        return PartnerProfile.fromJson(merged);
      }
      return null;
    } catch (e) {
      print('Error fetching partner profile: $e');
      return null;
    }
  }

  Future<void> createPartnerProfile(PartnerProfile profile) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Insert/update into profiles table
      final profileResp = await _supabase.from('profiles').upsert({
        'auth_user_id': profile.partnerId,
        'role': 'partner',
        'full_name': profile.ownerName,
        if (profile.mobileNumber != null) 'mobile_number': profile.mobileNumber,
        if (user.email != null) 'email': user.email,
        'city': profile.city,
        'state': profile.state,
        if (profile.profilePic != null) 'profile_photo_url': profile.profilePic,
      }, onConflict: 'auth_user_id').select().single();

      await _supabase.from('partners').upsert({
        'profile_id': profileResp['id'],
        'owner_name': profile.ownerName,
        'city': profile.city,
        'state': profile.state,
        if (profile.mobileNumber != null) 'mobile_number': profile.mobileNumber,
        if (profile.profilePic != null) 'profile_photo_url': profile.profilePic,
        if (user.email != null) 'email': user.email,
      }, onConflict: 'profile_id');
    } catch (e) {
      print('Error creating/updating partner profile: $e');
      rethrow;
    }
  }

  Future<void> createTruck(Truck truck) async {
    try {
      final pResp = await _supabase.from('profiles').select('id, partners(id)').eq('auth_user_id', truck.partnerId).maybeSingle();
      if (pResp == null || pResp['partners'] == null || pResp['partners'].isEmpty) throw Exception('Partner not found');
      
      final payload = truck.toJson();
      payload['partner_id'] = pResp['partners'][0]['id'];
      
      await _supabase.from('trucks').insert(payload);
    } catch (e) {
      print('Error creating truck: $e');
      rethrow;
    }
  }

  Future<Truck?> getActiveTruck(String partnerId) async {
    try {
      final pResp = await _supabase.from('profiles').select('id, partners(id)').eq('auth_user_id', partnerId).maybeSingle();
      if (pResp == null || pResp['partners'] == null || pResp['partners'].isEmpty) return null;
      
      final internalId = pResp['partners'][0]['id'];

      final response = await _supabase
          .from('trucks')
          .select()
          .eq('partner_id', internalId)
          .eq('operational_status', 'active')
          .maybeSingle();

      if (response != null) {
        return Truck.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error fetching active truck: $e');
      return null;
    }
  }

  Future<List<Truck>> getPartnerTrucks(String authUserId) async {
    try {
      // 1. Try finding partner by profile join
      String? internalPartnerId;
      final profileResp = await _supabase
          .from('profiles')
          .select('id, partners(id)')
          .eq('auth_user_id', authUserId)
          .maybeSingle();

      if (profileResp != null && profileResp['partners'] != null) {
        final raw = profileResp['partners'];
        if (raw is List && raw.isNotEmpty && raw[0] != null) {
          internalPartnerId = raw[0]['id']?.toString();
        } else if (raw is Map) {
          internalPartnerId = raw['id']?.toString();
        }
      }

      // 2. If not found via profile, try finding directly in partners table by profile_id
      if (internalPartnerId == null && profileResp != null && profileResp['id'] != null) {
        final partnerDirect = await _supabase
            .from('partners')
            .select('id')
            .eq('profile_id', profileResp['id'])
            .maybeSingle();
        if (partnerDirect != null) {
          internalPartnerId = partnerDirect['id']?.toString();
        }
      }

      // 3. Fallback: maybe authUserId was already a partner id
      if (internalPartnerId == null) {
        final directCheck = await _supabase
            .from('partners')
            .select('id')
            .eq('id', authUserId)
            .maybeSingle();
        if (directCheck != null) {
          internalPartnerId = directCheck['id']?.toString();
        }
      }

      if (internalPartnerId == null) return [];

      final response = await _supabase
          .from('trucks')
          .select()
          .eq('partner_id', internalPartnerId)
          .order('created_at', ascending: false);

      return (response as List).map((t) => Truck.fromJson(t)).toList();
    } catch (e) {
      print('Error fetching partner trucks: $e');
      return [];
    }
  }

  Future<void> createReturnRequirement(ReturnRequirement req) async {
    try {
      final pResp = await _supabase.from('profiles').select('id, partners(id)').eq('auth_user_id', req.partnerId).maybeSingle();
      if (pResp == null || pResp['partners'] == null || pResp['partners'].isEmpty) throw Exception('Partner not found');
      
      final internalPartnerId = pResp['partners'][0]['id'];
      
      final payload = req.toJson();
      payload['partner_id'] = internalPartnerId; // Override with internal ID
      
      await _supabase.from('truck_availability').insert(payload);
    } catch (e) {
      print('Error creating requirement: $e');
      rethrow;
    }
  }

  Future<void> createPartnerDocument(PartnerDocument doc) async {
    try {
      // In the new schema, we consolidated this into the 'documents' table
      await _supabase.from('documents').insert({
        'partner_id': doc.partnerId,
        'document_type': doc.documentType,
        'file_path': doc.fileUrl,
      });
    } catch (e) {
      print('Error creating partner document: $e');
      rethrow;
    }
  }

  Future<void> createTruckDocument(TruckDocument doc) async {
    try {
      // Consolidated into 'truck_documents' table as per spec
      await _supabase.from('truck_documents').insert(doc.toJson());
    } catch (e) {
      print('Error creating truck document: $e');
      rethrow;
    }
  }

  Future<List<ReturnRequirement>> getReturnRequirementsHistory(String partnerId) async {
    try {
      // Get partner internal id first
      final pResp = await _supabase.from('profiles').select('id, partners(id)').eq('auth_user_id', partnerId).maybeSingle();
      if (pResp == null || pResp['partners'] == null || pResp['partners'].isEmpty) return [];
      
      final internalPartnerId = pResp['partners'][0]['id'];

      final response = await _supabase
          .from('truck_availability')
          .select('*, contact_logs(count)')
          .eq('partner_id', internalPartnerId)
          .order('available_date', ascending: false);
          
      return (response as List).map((req) => ReturnRequirement.fromJson(req)).toList();
    } catch (e) {
      print('Error fetching history: $e');
      return [];
    }
  }

  Future<void> deleteReturnRequirement(String id) async {
    try {
      await _supabase
          .from('truck_availability')
          .delete()
          .eq('id', id);
    } catch (e) {
      print('Error deleting requirement: $e');
      rethrow;
    }
  }

  Future<void> createContactEvent(ContactEvent event) async {
    try {
      await _supabase.from('contact_logs').insert(event.toJson());
    } catch (e) {
      print('Error logging contact event: $e');
      rethrow;
    }
  }
}





