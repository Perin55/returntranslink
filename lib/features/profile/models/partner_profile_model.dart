class PartnerProfile {
  final String? id;
  final String partnerId; // Maps to profile_id in DB
  final String? partnerCode;
  final String? ownerName;
  final String? mobileNumber;
  final String? alternateMobile;
  final String? email;
  final String? businessName;
  final String? address; // Maps to business_address in DB
  final String? city;
  final String? state;
  final String? pincode;
  final String? panNumber;
  final String? gstNumber;
  final String? profilePic; // Maps to profile_photo_url in DB
  final String? gender; // Not in spec, kept for UI
  final double rating;
  final bool isVerified; // Maps from verification_status == 'verified'
  final String? partnerType;
  final String? onboardingStatus;
  final String? verificationStatus;
  final bool isActive;
  final int totalTrucks;
  final int totalTrips;

  PartnerProfile({
    this.id,
    required this.partnerId,
    this.partnerCode,
    this.ownerName,
    this.mobileNumber,
    this.alternateMobile,
    this.email,
    this.gender,
    this.businessName,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.panNumber,
    this.gstNumber,
    this.profilePic,
    this.rating = 0.0,
    this.isVerified = false,
    this.partnerType,
    this.onboardingStatus,
    this.verificationStatus,
    this.isActive = true,
    this.totalTrucks = 0,
    this.totalTrips = 0,
  });

  factory PartnerProfile.fromJson(Map<String, dynamic> json) {
    return PartnerProfile(
      id: json['id'],
      partnerId: json['id'] ?? json['profile_id'] ?? json['partner_id'] ?? '',
      partnerCode: json['partner_code'],
      ownerName: json['owner_name'],
      mobileNumber: json['mobile_number'],
      alternateMobile: json['alternate_mobile'],
      email: json['email'],
      gender: json['gender'], // Not in spec, kept for backward compatibility if local
      businessName: json['business_name'],
      address: json['business_address'] ?? json['address'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      panNumber: json['pan_number'],
      gstNumber: json['gst_number'],
      profilePic: json['profile_photo_url'] ?? json['profile_pic'],
      rating: json['rating'] != null ? double.tryParse(json['rating'].toString()) ?? 0.0 : 0.0,
      verificationStatus: json['verification_status'],
      isVerified: json['verification_status'] == 'verified' || (json['is_verified'] ?? false),
      partnerType: json['partner_type'],
      onboardingStatus: json['onboarding_status'],
      isActive: json['is_active'] ?? true,
      totalTrucks: json['total_trucks'] ?? 0,
      totalTrips: json['total_trips'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': partnerId,
      if (partnerCode != null) 'partner_code': partnerCode,
      'owner_name': ownerName,
      if (mobileNumber != null) 'mobile_number': mobileNumber,
      if (alternateMobile != null) 'alternate_mobile': alternateMobile,
      'email': email,
      'business_name': businessName,
      'business_address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'pan_number': panNumber,
      'gst_number': gstNumber,
      'profile_photo_url': profilePic,
      'rating': rating,
      'verification_status': isVerified ? 'verified' : verificationStatus ?? 'pending',
      if (partnerType != null) 'partner_type': partnerType,
      if (onboardingStatus != null) 'onboarding_status': onboardingStatus,
      'is_active': isActive,
      'total_trucks': totalTrucks,
      'total_trips': totalTrips,
      // gender is omitted since it is not in the database spec
    };
  }
}
