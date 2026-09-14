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

class MaterialPriceModel {
  final String material;
  final double pricePerKg;
  final String unit;
  final DateTime? updatedAt;

  MaterialPriceModel({
    required this.material,
    required this.pricePerKg,
    this.unit = 'kg',
    this.updatedAt,
  });

  factory MaterialPriceModel.fromJson(Map<String, dynamic> json) {
    return MaterialPriceModel(
      material: json['material']?.toString() ?? json['name']?.toString() ?? '',
      pricePerKg: (json['price_per_kg'] as num?)?.toDouble() ??
          (json['pricePerKg'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ??
          0.0,
      unit: json['unit']?.toString() ?? 'kg',
      updatedAt: _parseDate(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'material': material,
      'price_per_kg': pricePerKg,
      'unit': unit,
      'updated_at': updatedAt != null
          ? DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(updatedAt!.toUtc())
          : null,
    };
  }
}
