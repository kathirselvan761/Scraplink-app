/// Collector model mapped to the existing ScrapLink `users` table
/// where role = 'collector' and related collector profile data.
class Collector {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final bool isActive;
  final DateTime? createdAt;
  final int totalLots;

  const Collector({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role = 'collector',
    this.isActive = true,
    this.createdAt,
    this.totalLots = 0,
  });

  factory Collector.fromJson(Map<String, dynamic> json) {
    // Backend can return collector directly or wrapped under { collector: { ... }, total_lots: N }
    final source = json.containsKey('collector') && json['collector'] is Map<String, dynamic>
        ? json['collector'] as Map<String, dynamic>
        : json;

    return Collector(
      id: _parseInt(source['id'] ?? json['id']),
      name: source['name']?.toString() ?? '',
      email: source['email']?.toString() ?? '',
      phone: source['phone']?.toString(),
      role: source['role']?.toString() ?? 'collector',
      isActive: source['is_active'] == 1 || source['is_active'] == true,
      createdAt: source['created_at'] != null
          ? DateTime.tryParse(source['created_at'].toString())
          : null,
      totalLots: _parseInt(json['total_lots'] ?? source['total_lots'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'total_lots': totalLots,
    };
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Collector copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    int? totalLots,
  }) {
    return Collector(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      totalLots: totalLots ?? this.totalLots,
    );
  }
}
