/// Recycler model mapped directly to the existing ScrapLink `recyclers` table.
class Recycler {
  final int id;
  final int? userId;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final double? latitude;
  final double? longitude;
  final bool authorized;
  final String? acceptedMaterials;
  final double ratePerKg;
  final bool pickupAvailable;
  final String status;
  final String verificationStatus;

  const Recycler({
    required this.id,
    this.userId,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.latitude,
    this.longitude,
    this.authorized = true,
    this.acceptedMaterials,
    this.ratePerKg = 0.0,
    this.pickupAvailable = true,
    this.status = 'ACTIVE',
    this.verificationStatus = 'APPROVED',
  });

  factory Recycler.fromJson(Map<String, dynamic> json) {
    return Recycler(
      id: _parseInt(json['id'] ?? json['recycler_id']),
      userId: json['user_id'] != null ? _parseInt(json['user_id']) : null,
      name: (json['name'] ?? json['recycler_name'] ?? json['company_name'] ?? '').toString(),
      phone: (json['phone'] ?? json['recycler_phone'])?.toString(),
      email: (json['email'] ?? json['recycler_email'])?.toString(),
      address: (json['address'] ?? json['recycler_address'])?.toString(),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      authorized: json['authorized'] == 1 || json['authorized'] == true,
      acceptedMaterials: json['accepted_materials']?.toString(),
      ratePerKg: _parseDouble(json['rate_per_kg'] ?? json['price_per_kg']),
      pickupAvailable: json['pickup_available'] == 1 || json['pickup_available'] == true,
      status: (json['status'] ?? 'ACTIVE').toString(),
      verificationStatus: (json['verification_status'] ?? 'APPROVED').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'authorized': authorized ? 1 : 0,
      'accepted_materials': acceptedMaterials,
      'rate_per_kg': ratePerKg,
      'pickup_available': pickupAvailable ? 1 : 0,
      'status': status,
      'verification_status': verificationStatus,
    };
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
