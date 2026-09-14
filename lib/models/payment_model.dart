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

class PaymentModel {
  final int? id;
  final String? scrapId;
  final String? recyclerName;
  final double? finalWeight;
  final double? pricePerKg;
  final double? totalAmount;
  final String? paymentStatus;
  final String? transactionId;
  final DateTime? paymentDate;

  PaymentModel({
    this.id,
    this.scrapId,
    this.recyclerName,
    this.finalWeight,
    this.pricePerKg,
    this.totalAmount,
    this.paymentStatus,
    this.transactionId,
    this.paymentDate,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      scrapId: json['scrap_id']?.toString() ?? json['scrapId']?.toString() ?? json['lot_id']?.toString(),
      recyclerName: json['recycler_name']?.toString() ?? json['recyclerName']?.toString(),
      finalWeight: (json['final_weight'] as num?)?.toDouble() ?? (json['weight'] as num?)?.toDouble(),
      pricePerKg: (json['price_per_kg'] as num?)?.toDouble() ?? (json['price'] as num?)?.toDouble(),
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? (json['amount'] as num?)?.toDouble(),
      paymentStatus: json['payment_status']?.toString() ?? json['status']?.toString(),
      transactionId: json['transaction_id']?.toString() ?? json['transactionId']?.toString(),
      paymentDate: _parseDate(json['payment_date'] ?? json['paymentDate'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scrap_id': scrapId,
      'recycler_name': recyclerName,
      'final_weight': finalWeight,
      'price_per_kg': pricePerKg,
      'total_amount': totalAmount,
      'payment_status': paymentStatus,
      'transaction_id': transactionId,
      'payment_date': paymentDate != null
          ? DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(paymentDate!.toUtc())
          : null,
    };
  }
}
