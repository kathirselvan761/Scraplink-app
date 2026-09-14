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

class StatusHistoryItem {
  final String status;
  final DateTime? timestamp;
  final String? actor;
  final String? notes;

  StatusHistoryItem({
    required this.status,
    this.timestamp,
    this.actor,
    this.notes,
  });

  factory StatusHistoryItem.fromJson(Map<String, dynamic> json) {
    return StatusHistoryItem(
      status: json['status']?.toString() ?? '',
      timestamp: _parseDate(json['timestamp'] ?? json['created_at']),
      actor: json['actor']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'timestamp': timestamp != null
          ? DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(timestamp!.toUtc())
          : null,
      'actor': actor,
      'notes': notes,
    };
  }
}

class ScrapLotModel {
  final String id;
  final int? collectorId;
  final String material;
  final double estimatedWeight;
  final double? finalWeight;
  final String status;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final String? notes;
  final int? recyclerId;
  final String? recyclerName;
  final String? qrToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<StatusHistoryItem> statusHistory;

  ScrapLotModel({
    required this.id,
    this.collectorId,
    required this.material,
    required this.estimatedWeight,
    this.finalWeight,
    required this.status,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.notes,
    this.recyclerId,
    this.recyclerName,
    this.qrToken,
    this.createdAt,
    this.updatedAt,
    this.statusHistory = const [],
  });

  factory ScrapLotModel.fromJson(Map<String, dynamic> json) {
    var rawHistory = json['status_history'] ?? json['statusHistory'];
    List<StatusHistoryItem> historyList = [];
    if (rawHistory is List) {
      historyList = rawHistory
          .whereType<Map<String, dynamic>>()
          .map((item) => StatusHistoryItem.fromJson(item))
          .toList();
    }

    final idVal = json['id'] ?? json['lot_id'] ?? json['lotId'];

    return ScrapLotModel(
      id: idVal?.toString() ?? '',
      collectorId: json['collector_id'] is int
          ? json['collector_id'] as int
          : int.tryParse(json['collector_id']?.toString() ?? ''),
      material: json['material']?.toString() ?? json['material_type']?.toString() ?? '',
      estimatedWeight: (json['estimated_weight'] as num?)?.toDouble() ??
          (json['weight'] as num?)?.toDouble() ??
          0.0,
      finalWeight: (json['final_weight'] as num?)?.toDouble(),
      status: json['status']?.toString() ?? 'pending',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      imageUrl: json['image_url']?.toString() ?? json['imageUrl']?.toString(),
      notes: json['notes']?.toString(),
      recyclerId: json['recycler_id'] is int
          ? json['recycler_id'] as int
          : int.tryParse(json['recycler_id']?.toString() ?? ''),
      recyclerName: json['recycler_name']?.toString() ?? json['recyclerName']?.toString(),
      qrToken: json['qr_token']?.toString() ?? json['qrToken']?.toString(),
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDate(json['updated_at'] ?? json['updatedAt']),
      statusHistory: historyList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collector_id': collectorId,
      'material': material,
      'estimated_weight': estimatedWeight,
      'final_weight': finalWeight,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'image_url': imageUrl,
      'notes': notes,
      'recycler_id': recyclerId,
      'recycler_name': recyclerName,
      'qr_token': qrToken,
      'created_at': createdAt != null
          ? DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(createdAt!.toUtc())
          : null,
      'updated_at': updatedAt != null
          ? DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(updatedAt!.toUtc())
          : null,
      'status_history': statusHistory.map((item) => item.toJson()).toList(),
    };
  }
}
