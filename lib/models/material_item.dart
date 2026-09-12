/// Model representing an active scrap material category and its baseline rate per kg
/// from the backend material_prices table.
class MaterialItem {
  final int? id;
  final String material;
  final double pricePerKg;
  final DateTime? effectiveDate;
  final bool isActive;

  const MaterialItem({
    this.id,
    required this.material,
    required this.pricePerKg,
    this.effectiveDate,
    this.isActive = true,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      material: (json['material'] ?? '').toString().trim(),
      pricePerKg: double.tryParse(json['price_per_kg']?.toString() ?? '0.0') ?? 0.0,
      effectiveDate: json['effective_date'] != null
          ? DateTime.tryParse(json['effective_date'].toString())
          : null,
      isActive: json['is_active'] == 1 || json['is_active'] == true || json['is_active'] == null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'material': material,
      'price_per_kg': pricePerKg,
      if (effectiveDate != null) 'effective_date': effectiveDate?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  /// Default materials fallback matching backend priceService.js
  static List<MaterialItem> get defaultMaterials => const [
        MaterialItem(material: 'Copper', pricePerKg: 650.0),
        MaterialItem(material: 'Aluminum', pricePerKg: 180.0),
        MaterialItem(material: 'E-waste', pricePerKg: 220.0),
        MaterialItem(material: 'Plastic', pricePerKg: 45.0),
        MaterialItem(material: 'Steel', pricePerKg: 38.0),
        MaterialItem(material: 'Brass', pricePerKg: 420.0),
        MaterialItem(material: 'Lead', pricePerKg: 160.0),
        MaterialItem(material: 'Paper', pricePerKg: 15.0),
      ];
}
