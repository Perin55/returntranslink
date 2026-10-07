class Partner {
  final String? id; // Supabase UUID
  final String? email;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Partner({
    this.id,
    this.email,
    this.status = 'Draft',
    this.createdAt,
    this.updatedAt,
  });

  factory Partner.fromJson(Map<String, dynamic> json) {
    return Partner(
      id: json['id'],
      email: json['email'],
      status: json['status'] ?? 'Draft',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      'owner_name': 'Pending', // Default required by partners table
    };
  }
}
