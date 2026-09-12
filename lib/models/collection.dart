import 'collection_status.dart';
import 'scrap.dart';

/// Tracking event entry from lot_tracking or scrap_status_history
class TrackingEvent {
  final String status;
  final String? notes;
  final double? latitude;
  final double? longitude;
  final String? address;
  final DateTime? timestamp;

  const TrackingEvent({
    required this.status,
    this.notes,
    this.latitude,
    this.longitude,
    this.address,
    this.timestamp,
  });

  factory TrackingEvent.fromJson(Map<String, dynamic> json) {
    return TrackingEvent(
      status: (json['status'] ?? '').toString(),
      notes: (json['notes'] ?? json['description'])?.toString(),
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      address: (json['address'] ?? json['location'])?.toString(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : (json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString())
              : (json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      if (notes != null) 'notes': notes,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (address != null) 'address': address,
      if (timestamp != null) 'timestamp': timestamp?.toIso8601String(),
    };
  }
}

/// Collection model encapsulating the complete collection entity
/// as returned across the ScrapLink API.
class Collection {
  final Scrap scrap;
  final CollectionStatus status;
  final String? customerName;
  final String? customerPhone;
  final String? collectorName;
  final String? collectorPhone;
  final String? collectorEmail;
  final String? recyclerName;
  final String? recyclerPhone;
  final String? recyclerAddress;
  final DateTime? requestedAt;
  final DateTime? acceptedAt;
  final DateTime? collectedAt;
  final DateTime? weighedAt;
  final DateTime? receivedAt;
  final DateTime? completedAt;
  final String? paymentStatus;
  final double? paymentAmount;
  final String? transactionId;
  final List<TrackingEvent> trackingHistory;

  const Collection({
    required this.scrap,
    required this.status,
    this.customerName,
    this.customerPhone,
    this.collectorName,
    this.collectorPhone,
    this.collectorEmail,
    this.recyclerName,
    this.recyclerPhone,
    this.recyclerAddress,
    this.requestedAt,
    this.acceptedAt,
    this.collectedAt,
    this.weighedAt,
    this.receivedAt,
    this.completedAt,
    this.paymentStatus,
    this.paymentAmount,
    this.transactionId,
    this.trackingHistory = const [],
  });

  /// Convenience getter for Lot ID (e.g. 'SCRAP-0005')
  String get lotId => scrap.lotId;

  /// Convenience getter for Material
  String get material => scrap.material;

  /// Convenience getter for Weight
  double get weight => scrap.weight;

  /// Convenience getter for Final Weight
  double? get finalWeight => scrap.finalWeight;

  /// Convenience getter for Estimated Price
  double get estimatedPrice => scrap.estimatedPrice;

  /// Scheduled pickup date & time
  DateTime? get scheduledDateTime => requestedAt ?? scrap.createdAt;

  /// Effective pickup address (from location notes or collection point)
  String get pickupAddress {
    if (scrap.notes != null && scrap.notes!.trim().isNotEmpty) {
      return scrap.notes!.trim();
    }
    if (recyclerAddress != null && recyclerAddress!.trim().isNotEmpty) {
      return recyclerAddress!.trim();
    }
    return 'Regional Collection Point, Chennai';
  }

  /// Display customer or source name
  String get displayCustomerName {
    if (customerName != null && customerName!.trim().isNotEmpty) {
      return customerName!.trim();
    }
    return 'Residential Collection';
  }

  factory Collection.fromJson(Map<String, dynamic> json) {
    // Parse underlying Scrap object
    final scrap = Scrap.fromJson(json);

    // Parse status string
    final statusStr = json['status']?.toString();
    final status = CollectionStatus.fromString(statusStr);

    // Parse customer info if present
    String? customerName = json['customer_name']?.toString() ??
        json['client_name']?.toString() ??
        json['submitted_by']?.toString();
    String? customerPhone = json['customer_phone']?.toString();

    // Parse nested collector info if present
    String? collectorName = json['collector_name']?.toString();
    String? collectorPhone = json['collector_phone']?.toString();
    String? collectorEmail = json['collector_email']?.toString();

    if (json['collector_details'] is Map<String, dynamic>) {
      final cd = json['collector_details'] as Map<String, dynamic>;
      collectorName ??= cd['name']?.toString();
      collectorPhone ??= cd['phone']?.toString();
      collectorEmail ??= cd['email']?.toString();
    }

    // Parse payment details
    String? paymentStatus = json['payment_status']?.toString();
    double? paymentAmount = json['payment_amount'] != null
        ? double.tryParse(json['payment_amount'].toString())
        : null;
    String? txnId = json['transaction_id']?.toString();

    if (json['payment'] is Map<String, dynamic>) {
      final p = json['payment'] as Map<String, dynamic>;
      paymentStatus ??= p['payment_status']?.toString();
      if (p['total_amount'] != null) {
        paymentAmount ??= double.tryParse(p['total_amount'].toString());
      }
      txnId ??= p['transaction_id']?.toString();
    }

    // Parse tracking history
    final historyList = <TrackingEvent>[];
    if (json['tracking_history'] is List) {
      for (final item in json['tracking_history']) {
        if (item is Map<String, dynamic>) {
          historyList.add(TrackingEvent.fromJson(item));
        }
      }
    } else if (json['history'] is List) {
      for (final item in json['history']) {
        if (item is Map<String, dynamic>) {
          historyList.add(TrackingEvent.fromJson(item));
        }
      }
    }

    return Collection(
      scrap: scrap,
      status: status,
      customerName: customerName,
      customerPhone: customerPhone,
      collectorName: collectorName,
      collectorPhone: collectorPhone,
      collectorEmail: collectorEmail,
      recyclerName: json['recycler_name']?.toString(),
      recyclerPhone: json['recycler_phone']?.toString(),
      recyclerAddress: json['recycler_address']?.toString(),
      requestedAt: json['requested_at'] != null
          ? DateTime.tryParse(json['requested_at'].toString())
          : null,
      acceptedAt: json['accepted_at'] != null
          ? DateTime.tryParse(json['accepted_at'].toString())
          : null,
      collectedAt: json['collected_at'] != null
          ? DateTime.tryParse(json['collected_at'].toString())
          : null,
      weighedAt: json['weighed_at'] != null
          ? DateTime.tryParse(json['weighed_at'].toString())
          : null,
      receivedAt: json['received_at'] != null
          ? DateTime.tryParse(json['received_at'].toString())
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
      paymentStatus: paymentStatus,
      paymentAmount: paymentAmount,
      transactionId: txnId,
      trackingHistory: historyList,
    );
  }

  Map<String, dynamic> toJson() {
    final map = scrap.toJson();
    map['status'] = status.toBackendString();
    if (customerName != null) map['customer_name'] = customerName;
    if (customerPhone != null) map['customer_phone'] = customerPhone;
    if (collectorName != null) map['collector_name'] = collectorName;
    if (collectorPhone != null) map['collector_phone'] = collectorPhone;
    if (collectorEmail != null) map['collector_email'] = collectorEmail;
    if (recyclerName != null) map['recycler_name'] = recyclerName;
    if (recyclerPhone != null) map['recycler_phone'] = recyclerPhone;
    if (recyclerAddress != null) map['recycler_address'] = recyclerAddress;
    if (requestedAt != null) map['requested_at'] = requestedAt?.toIso8601String();
    if (acceptedAt != null) map['accepted_at'] = acceptedAt?.toIso8601String();
    if (collectedAt != null) map['collected_at'] = collectedAt?.toIso8601String();
    if (weighedAt != null) map['weighed_at'] = weighedAt?.toIso8601String();
    if (receivedAt != null) map['received_at'] = receivedAt?.toIso8601String();
    if (completedAt != null) map['completed_at'] = completedAt?.toIso8601String();
    if (paymentStatus != null) map['payment_status'] = paymentStatus;
    if (paymentAmount != null) map['payment_amount'] = paymentAmount;
    if (transactionId != null) map['transaction_id'] = transactionId;
    if (trackingHistory.isNotEmpty) {
      map['tracking_history'] = trackingHistory.map((e) => e.toJson()).toList();
    }
    return map;
  }

  Collection copyWith({
    Scrap? scrap,
    CollectionStatus? status,
    String? customerName,
    String? customerPhone,
    String? collectorName,
    String? collectorPhone,
    String? collectorEmail,
    String? recyclerName,
    String? recyclerPhone,
    String? recyclerAddress,
    DateTime? requestedAt,
    DateTime? acceptedAt,
    DateTime? collectedAt,
    DateTime? weighedAt,
    DateTime? receivedAt,
    DateTime? completedAt,
    String? paymentStatus,
    double? paymentAmount,
    String? transactionId,
    List<TrackingEvent>? trackingHistory,
  }) {
    return Collection(
      scrap: scrap ?? this.scrap,
      status: status ?? this.status,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      collectorName: collectorName ?? this.collectorName,
      collectorPhone: collectorPhone ?? this.collectorPhone,
      collectorEmail: collectorEmail ?? this.collectorEmail,
      recyclerName: recyclerName ?? this.recyclerName,
      recyclerPhone: recyclerPhone ?? this.recyclerPhone,
      recyclerAddress: recyclerAddress ?? this.recyclerAddress,
      requestedAt: requestedAt ?? this.requestedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      collectedAt: collectedAt ?? this.collectedAt,
      weighedAt: weighedAt ?? this.weighedAt,
      receivedAt: receivedAt ?? this.receivedAt,
      completedAt: completedAt ?? this.completedAt,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      transactionId: transactionId ?? this.transactionId,
      trackingHistory: trackingHistory ?? this.trackingHistory,
    );
  }
}
