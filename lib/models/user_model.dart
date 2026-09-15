import 'package:intl/intl.dart';

class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['created_at'] != null || json['createdAt'] != null) {
      final dateStr = (json['created_at'] ?? json['createdAt']).toString();
      parsedDate = DateTime.tryParse(dateStr);
      if (parsedDate == null) {
        try {
          parsedDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateStr);
        } catch (_) {}
      }
    }

    final rawId = json['id'] ?? json['userId'] ?? json['user_id'];
    int parsedId = 0;
    if (rawId is int) {
      parsedId = rawId;
    } else if (rawId is num) {
      parsedId = rawId.toInt();
    } else if (rawId is String) {
      parsedId = int.tryParse(rawId) ?? 0;
    }

    return UserModel(
      id: parsedId,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? 'collector',
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'created_at': createdAt != null
          ? DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(createdAt!.toUtc())
          : null,
    };
  }
}
