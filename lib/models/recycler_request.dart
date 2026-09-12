/// Model representing an incoming Recycler Request / Match for a collected scrap lot
/// from the backend recycler_matches table.
class RecyclerRequest {
  final int id;
  final String lotId;
  final int recyclerId;
  final String recyclerName;
  final String? recyclerPhone;
  final String material;
  final double weight;
  final double offeredRate;
  final double offerAmount;
  final String status;
  final DateTime? createdAt;

  const RecyclerRequest({
    required this.id,
    required this.lotId,
    required this.recyclerId,
    required this.recyclerName,
    this.recyclerPhone,
    required this.material,
    required this.weight,
    required this.offeredRate,
    required this.offerAmount,
    required this.status,
    this.createdAt,
  });

  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isAccepted => status.toUpperCase() == 'ACCEPTED';
  bool get isCompleted =>
      status.toUpperCase() == 'COMPLETED' ||
      status.toUpperCase() == 'RECEIVED' ||
      status.toUpperCase() == 'HANDED_OVER';

  factory RecyclerRequest.fromJson(Map<String, dynamic> json) {
    final weightVal = double.tryParse(json['weight']?.toString() ?? '0.0') ?? 0.0;
    final rateVal = double.tryParse(json['offered_rate']?.toString() ?? '0.0') ?? 0.0;
    final calcAmount = json['offer_amount'] != null
        ? (double.tryParse(json['offer_amount'].toString()) ?? (weightVal * rateVal))
        : (weightVal * rateVal);

    return RecyclerRequest(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      lotId: (json['lot_id'] ?? '').toString(),
      recyclerId: json['recycler_id'] is int
          ? json['recycler_id'] as int
          : int.tryParse(json['recycler_id']?.toString() ?? '1') ?? 1,
      recyclerName: (json['recycler_name'] ?? 'Authorized Recycler Hub').toString(),
      recyclerPhone: json['recycler_phone']?.toString(),
      material: (json['material'] ?? 'E-Waste').toString(),
      weight: weightVal,
      offeredRate: rateVal,
      offerAmount: calcAmount,
      status: (json['status'] ?? 'PENDING').toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lot_id': lotId,
      'recycler_id': recyclerId,
      'recycler_name': recyclerName,
      if (recyclerPhone != null) 'recycler_phone': recyclerPhone,
      'material': material,
      'weight': weight,
      'offered_rate': offeredRate,
      'offer_amount': offerAmount,
      'status': status,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
    };
  }
}
