class ReturnRequirement {
  final String? id;
  final String partnerId;
  final String? truckId;
  final String? routeId; // Maps to route_id
  final String origin; // Maps to origin_city/location
  final String destination; // Maps to destination_city/location
  final DateTime routeDate; // Maps to available_date
  final DateTime? expectedAvailability; // Maps to available_from_time
  final double? currentLocationLat; // Not in spec, kept for UI
  final double? currentLocationLng; // Not in spec, kept for UI
  final String? loadType; // Not in spec, kept for UI
  final String? notes; // Maps to notes
  final String status; // Maps to status
  final int contactCount;
  final double? price; // Not in spec (violates MVP), kept for UI fallback
  
  // New spec fields for truck_availability
  final String? originState;
  final double? originLatitude;
  final double? originLongitude;
  final String? destinationState;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final int? totalCapacityKg;
  final int? availableCapacityKg;
  final DateTime? availableUntilTime;

  ReturnRequirement({
    this.id,
    required this.partnerId,
    this.truckId,
    this.routeId,
    required this.origin,
    required this.destination,
    required this.routeDate,
    this.expectedAvailability,
    this.currentLocationLat,
    this.currentLocationLng,
    this.loadType,
    this.notes,
    this.status = 'available',
    this.contactCount = 0,
    this.price,
    this.originState,
    this.originLatitude,
    this.originLongitude,
    this.destinationState,
    this.destinationLatitude,
    this.destinationLongitude,
    this.totalCapacityKg,
    this.availableCapacityKg,
    this.availableUntilTime,
  });

  factory ReturnRequirement.fromJson(Map<String, dynamic> json) {
    int count = 0;
    if (json['contact_events'] != null && json['contact_events'] is List && json['contact_events'].isNotEmpty) {
      count = json['contact_events'][0]['count'] ?? 0;
    }

    return ReturnRequirement(
      id: json['id'],
      partnerId: json['partner_id'],
      truckId: json['truck_id'],
      routeId: json['route_id'],
      origin: json['origin_city'] ?? json['origin_location'] ?? json['origin'] ?? '',
      destination: json['destination_city'] ?? json['destination_location'] ?? json['destination'] ?? '',
      routeDate: json['available_date'] != null 
          ? DateTime.parse(json['available_date']) 
          : (json['route_date'] != null ? DateTime.parse(json['route_date']) : DateTime.now()),
      expectedAvailability: json['available_from_time'] != null 
          ? DateTime.tryParse("1970-01-01T${json['available_from_time']}") 
          : (json['availability_time'] != null ? DateTime.parse(json['availability_time']) : null),
      availableUntilTime: json['available_until_time'] != null 
          ? DateTime.tryParse("1970-01-01T${json['available_until_time']}") : null,
      currentLocationLat: json['current_location'] != null ? double.tryParse(json['current_location'].toString().split(',')[0]) : null,
      currentLocationLng: json['current_location'] != null ? double.tryParse(json['current_location'].toString().split(',')[1]) : null,
      notes: json['notes'],
      status: json['status'] ?? 'available',
      contactCount: count,
      price: json['price'] != null ? double.tryParse(json['price'].toString()) : null,
      originState: json['origin_state'],
      originLatitude: json['origin_latitude'] != null ? double.tryParse(json['origin_latitude'].toString()) : null,
      originLongitude: json['origin_longitude'] != null ? double.tryParse(json['origin_longitude'].toString()) : null,
      destinationState: json['destination_state'],
      destinationLatitude: json['destination_latitude'] != null ? double.tryParse(json['destination_latitude'].toString()) : null,
      destinationLongitude: json['destination_longitude'] != null ? double.tryParse(json['destination_longitude'].toString()) : null,
      totalCapacityKg: json['total_capacity_kg'],
      availableCapacityKg: json['available_capacity_kg'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'partner_id': partnerId,
      if (truckId != null) 'truck_id': truckId,
      if (routeId != null) 'route_id': routeId,
      'origin_city': origin,
      'destination_city': destination,
      'available_date': routeDate.toIso8601String().split('T').first,
      if (expectedAvailability != null) 'available_from_time': "${expectedAvailability!.hour.toString().padLeft(2, '0')}:${expectedAvailability!.minute.toString().padLeft(2, '0')}:00",
      if (availableUntilTime != null) 'available_until_time': "${availableUntilTime!.hour.toString().padLeft(2, '0')}:${availableUntilTime!.minute.toString().padLeft(2, '0')}:00",
      if (originState != null) 'origin_state': originState,
      if (originLatitude != null) 'origin_latitude': originLatitude,
      if (originLongitude != null) 'origin_longitude': originLongitude,
      if (destinationState != null) 'destination_state': destinationState,
      if (destinationLatitude != null) 'destination_latitude': destinationLatitude,
      if (destinationLongitude != null) 'destination_longitude': destinationLongitude,
      if (totalCapacityKg != null) 'total_capacity_kg': totalCapacityKg,
      if (availableCapacityKg != null) 'available_capacity_kg': availableCapacityKg,
      'status': status,
      if (notes != null) 'notes': notes,
      // currentLocation, price, loadType are omitted from DB JSON
    };
  }
}
