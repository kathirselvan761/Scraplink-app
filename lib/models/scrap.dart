import 'collection_status.dart';

/// Scrap model mapped directly to the existing ScrapLink `scrap_lots` table.
///
/// NOTE: The [lotId] is the primary domain identifier across Admin, Recycler,
/// Collector, and Backend (e.g. 'SCRAP-0005' or 'SL-2026-00001'). No secondary
/// or client-generated ID is created.
class Scrap {
  final int? id;
  final String lotId;
  final int collectorId;
  final int? recyclerId;
  final String material;
  final double weight;
  final double? finalWeight;
  final double estimatedPrice;
  final double confidence;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final String? qrCode;
  final CollectionStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Scrap({
    this.id,
    required this.lotId,
    required this.collectorId,
    this.recyclerId,
    required this.material,
    required this.weight,
    this.finalWeight,
    this.estimatedPrice = 0.0,
    this.confidence = 0.95,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.notes,
    this.qrCode,
    this.status = CollectionStatus.available,
    this.createdAt,
    this.updatedAt,
  });

  factory Scrap.fromJson(Map<String, dynamic> json) {
    // Resolve lot_id from lot_id, request_id, scrap_id, or format from numeric id
    String resolvedLotId = (json['lot_id'] ??
            json['scrap_id'] ??
            json['request_id'] ??
            json['scrap_request_id'])
        ?.toString() ?? '';

    if (resolvedLotId.isEmpty && json['id'] != null) {
      resolvedLotId = 'SCRAP-${json['id'].toString().padLeft(4, '0')}';
    }

    return Scrap(
      id: json['id'] != null ? _parseInt(json['id']) : null,
      lotId: resolvedLotId,
      collectorId: _parseInt(json['collector_id'] ?? 1),
      recyclerId: json['recycler_id'] != null ? _parseInt(json['recycler_id']) : null,
      material: (json['material'] ?? json['scrap_type'] ?? 'Unknown').toString(),
      weight: _parseDouble(json['weight'] ?? json['approximate_weight'] ?? json['estimated_weight']),
      finalWeight: json['final_weight'] != null ? _parseDouble(json['final_weight']) : null,
      estimatedPrice: _parseDouble(json['estimated_price'] ?? json['total_amount'] ?? json['amount']),
      confidence: _parseDouble(json['confidence'] ?? 0.95),
      imageUrl: json['image_url']?.toString(),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      notes: (json['notes'] ?? json['location'] ?? json['collection_location'])?.toString(),
      qrCode: (json['qr_code'] ?? json['qr_code_value'])?.toString(),
      status: CollectionStatus.fromString(json['status']?.toString()),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'lot_id': lotId,
      'collector_id': collectorId,
      if (recyclerId != null) 'recycler_id': recyclerId,
      'material': material,
      'weight': weight,
      if (finalWeight != null) 'final_weight': finalWeight,
      'estimated_price': estimatedPrice,
      'confidence': confidence,
      if (imageUrl != null) 'image_url': imageUrl,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (notes != null) 'notes': notes,
      'status': status.toBackendString(),
      if (qrCode != null) 'qr_code': qrCode,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt?.toIso8601String(),
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
