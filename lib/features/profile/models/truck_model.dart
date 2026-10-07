class Truck {
  final String? id;
  final String partnerId;
  final String truckNumber;
  final String? vehicleType; // Maps to truck_type
  final String? bodyType;
  final double? capacity; // Maps to capacity_tons
  final String? capacityUnit; // Not in spec, kept for UI
  final double? length; // Maps to length_ft
  final double? width; // Maps to width_ft
  final double? height; // Maps to height_ft
  final String status; // Maps to availability_status
  final bool isActive; // Usually matches operational_status or general active flag
  final String? currentLocation; // Should be in truck_locations, kept for UI
  final String? regularStartingLocation; // Kept for UI
  final String? regularRoutes; // Kept for UI
  final String? driverName; // Kept for UI
  final String? driverMobileNumber; // Kept for UI
  
  // New Spec fields
  final int? capacityKg;
  final String? vehicleMake;
  final String? vehicleModel;
  final int? manufacturingYear;
  final String? fuelType;
  final String? currentDriverId;
  final String? truckPhotoUrl;
  final String? operationalStatus;
  final bool isVerified;

  Truck({
    this.id,
    required this.partnerId,
    required this.truckNumber,
    this.vehicleType,
    this.bodyType,
    this.capacity,
    this.capacityUnit,
    this.length,
    this.width,
    this.height,
    this.status = 'available',
    this.isActive = false,
    this.currentLocation,
    this.regularStartingLocation,
    this.regularRoutes,
    this.driverName,
    this.driverMobileNumber,
    this.capacityKg,
    this.vehicleMake,
    this.vehicleModel,
    this.manufacturingYear,
    this.fuelType,
    this.currentDriverId,
    this.truckPhotoUrl,
    this.operationalStatus,
    this.isVerified = false,
  });

  factory Truck.fromJson(Map<String, dynamic> json) {
    return Truck(
      id: json['id'],
      partnerId: json['partner_id'],
      truckNumber: json['truck_number'],
      vehicleType: json['truck_type'] ?? json['vehicle_type'],
      bodyType: json['body_type'],
      capacity: json['capacity_tons'] != null 
          ? double.tryParse(json['capacity_tons'].toString()) 
          : json['capacity']?.toDouble(),
      capacityKg: json['capacity_kg'],
      capacityUnit: json['capacity_unit'], // Local UI fallback
      length: json['length_ft'] != null 
          ? double.tryParse(json['length_ft'].toString()) 
          : json['length']?.toDouble(),
      width: json['width_ft'] != null 
          ? double.tryParse(json['width_ft'].toString()) 
          : json['width']?.toDouble(),
      height: json['height_ft'] != null 
          ? double.tryParse(json['height_ft'].toString()) 
          : json['height']?.toDouble(),
      status: json['availability_status'] ?? json['status'] ?? 'available',
      isActive: json['is_active'] == true || json['operational_status'] == 'active',
      currentLocation: json['current_location'], // Legacy
      regularStartingLocation: json['regular_starting_location'], // Legacy
      regularRoutes: json['regular_routes'], // Legacy
      driverName: json['driver_name'], // Legacy
      driverMobileNumber: json['driver_mobile_number'], // Legacy
      vehicleMake: json['vehicle_make'],
      vehicleModel: json['vehicle_model'],
      manufacturingYear: json['manufacturing_year'],
      fuelType: json['fuel_type'],
      currentDriverId: json['current_driver_id'],
      truckPhotoUrl: json['truck_photo_url'],
      operationalStatus: json['operational_status'],
      isVerified: json['is_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'partner_id': partnerId,
      'truck_number': truckNumber,
      if (vehicleType != null) 'truck_type': vehicleType,
      'body_type': bodyType,
      'capacity_tons': capacity,
      if (capacityKg != null) 'capacity_kg': capacityKg,
      'length_ft': length,
      'width_ft': width,
      'height_ft': height,
      'availability_status': status,
      if (operationalStatus != null) 'operational_status': operationalStatus,
      'is_verified': isVerified,
      if (vehicleMake != null) 'vehicle_make': vehicleMake,
      if (vehicleModel != null) 'vehicle_model': vehicleModel,
      if (manufacturingYear != null) 'manufacturing_year': manufacturingYear,
      if (fuelType != null) 'fuel_type': fuelType,
      if (currentDriverId != null) 'current_driver_id': currentDriverId,
      if (truckPhotoUrl != null) 'truck_photo_url': truckPhotoUrl,
      // The following are excluded from DB as per spec, they belong in other tables:
      // currentLocation, regularStartingLocation, regularRoutes, driverName, driverMobileNumber
    };
  }
}
