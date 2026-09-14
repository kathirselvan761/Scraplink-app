import 'package:intl/intl.dart';

DateTime? _parseDate(dynamic dateValue) {
  if (dateValue == null) return null;
  if (dateValue is DateTime) return dateValue;
  final str = dateValue.toString();
  final parsed = DateTime.tryParse(str);
  if (parsed != null) return parsed;
  try {
    return DateFormat('yyyy-MM-dd HH:mm:ss').parse(str);
  } catch (_) {
    return null;
  }
}

class NotificationModel {
  final int? id;
  final String title;
  final String message;
  final String? type;
  final bool isRead;
  final int? relatedId;
  final DateTime? createdAt;

  NotificationModel({
    this.id,
    required this.title,
    required this.message,
    this.type,
    this.isRead = false,
    this.relatedId,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString(),
      isRead: json['is_read'] == true || json['isRead'] == true || json['is_read'] == 1,
      relatedId: json['related_id'] is int
          ? json['related_id'] as int
          : int.tryParse(json['related_id']?.toString() ?? ''),
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
    );
  }

  NotificationModel copyWith({
    int? id,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    int? relatedId,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId ?? this.relatedId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'related_id': relatedId,
      'created_at': createdAt != null
          ? DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(createdAt!.toUtc())
          : null,
    };
  }
}
