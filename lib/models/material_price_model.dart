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

double _toDouble(dynamic v, [double defaultValue = 0.0]) {
  if (v == null) return defaultValue;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? defaultValue;
  return defaultValue;
}

class MaterialPriceModel {
  final int? id;
  final String material;
  final double pricePerKg;
  final String unit;
  final bool isActive;
  final DateTime? updatedAt;

  MaterialPriceModel({
    this.id,
    required this.material,
    required this.pricePerKg,
    this.unit = 'kg',
    this.isActive = true,
    this.updatedAt,
  });

  factory MaterialPriceModel.fromJson(Map<String, dynamic> json) {
    print('MODEL: raw price_per_kg = ${json['price_per_kg']} (${json['price_per_kg'].runtimeType})');

    final rawPrice = json['price_per_kg'] ?? json['pricePerKg'] ?? json['price'];
    final rawActive = json['is_active'] ?? json['isActive'] ?? json['active'];
    bool active = true;
    if (rawActive != null) {
      if (rawActive is bool) {
        active = rawActive;
      } else if (rawActive is num) {
        active = rawActive != 0;
      } else if (rawActive is String) {
        active = rawActive == '1' || rawActive.toLowerCase() == 'true';
      }
    }

    final rawId = json['id'];
    int? parsedId;
    if (rawId != null) {
      if (rawId is int) {
        parsedId = rawId;
      } else if (rawId is num) {
        parsedId = rawId.toInt();
      } else if (rawId is String) {
        parsedId = int.tryParse(rawId);
      }
    }

    return MaterialPriceModel(
      id: parsedId,
      material: json['material']?.toString() ?? json['name']?.toString() ?? '',
      pricePerKg: _toDouble(rawPrice),
      unit: json['unit']?.toString() ?? 'kg',
      isActive: active,
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
