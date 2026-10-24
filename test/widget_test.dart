import 'package:flutter_test/flutter_test.dart';
import 'package:return_translink/features/profile/models/user_profile.dart';
import 'package:return_translink/features/profile/models/truck_model.dart';

void main() {
  group('UserProfile model', () {
    test('maps Supabase snake_case profile columns', () {
      final profile = UserProfile.fromMap({
        'auth_user_id': 'auth-123',
        'full_name': 'Test Owner',
        'mobile_number': '+919999999999',
        'city': 'Ahmedabad',
        'profile_photo_url': 'https://example.test/avatar.jpg',
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-02T00:00:00.000Z',
      });

      expect(profile.uid, 'auth-123');
      expect(profile.fullName, 'Test Owner');
      expect(profile.phoneNumber, '+919999999999');
      expect(profile.city, 'Ahmedabad');
      expect(profile.profileImageUrl, 'https://example.test/avatar.jpg');
    });

    test('serializes profile timestamps as ISO-8601 strings', () {
      final profile = UserProfile(
        uid: 'auth-123',
        fullName: 'Test Owner',
        phoneNumber: '+919999999999',
        city: 'Ahmedabad',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
      );

      final map = profile.toMap();
      expect(map['uid'], 'auth-123');
      expect(DateTime.parse(map['createdAt'] as String).toUtc(), DateTime.utc(2026, 1, 1));
      expect(DateTime.parse(map['updatedAt'] as String).toUtc(), DateTime.utc(2026, 1, 2));
    });
  });

  group('Truck model', () {
    test('parses Supabase truck columns and serializes canonical field names', () {
      final truck = Truck.fromJson({
        'id': 'truck-1',
        'partner_id': 'partner-1',
        'truck_number': 'GJ01AB1234',
        'truck_type': 'Tata Ace',
        'capacity_tons': 0.75,
        'availability_status': 'available',
        'operational_status': 'active',
        'is_verified': true,
      });

      expect(truck.partnerId, 'partner-1');
      expect(truck.truckNumber, 'GJ01AB1234');
      expect(truck.vehicleType, 'Tata Ace');
      expect(truck.capacity, 0.75);
      expect(truck.isActive, isTrue);

      final payload = truck.toJson();
      expect(payload['partner_id'], 'partner-1');
      expect(payload['truck_number'], 'GJ01AB1234');
      expect(payload['truck_type'], 'Tata Ace');
      expect(payload.containsKey('current_location'), isFalse);
    });
  });
}
