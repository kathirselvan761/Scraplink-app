import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/material_item.dart';

/// Service for fetching active scrap materials and baseline price rates from existing backend
class MaterialService {
  final ApiClient _client;

  MaterialService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Retrieve all active material categories and prices
  /// Calls existing GET /api/prices
  Future<List<MaterialItem>> getActiveMaterials() async {
    try {
      final response = await _client.get(ApiConstants.prices);

      if (response is Map<String, dynamic> && response['data'] is List) {
        final list = <MaterialItem>[];
        for (final item in response['data']) {
          if (item is Map<String, dynamic>) {
            list.add(MaterialItem.fromJson(item));
          }
        }
        if (list.isNotEmpty) return list;
      }
    } catch (_) {
      // Return default backend materials if network error occurs
    }

    return MaterialItem.defaultMaterials;
  }

  /// Calculate estimated price for a specific material and weight
  /// Calls existing GET /api/prices/:material?weight=:weight
  Future<double> calculateEstimatedPrice(String material, double weight) async {
    try {
      final response = await _client.get(
        '${ApiConstants.prices}/$material',
        queryParameters: {'weight': weight},
      );

      if (response is Map<String, dynamic> && response['data'] is Map<String, dynamic>) {
        final est = response['data']['estimated_price'];
        if (est != null) {
          return double.tryParse(est.toString()) ?? 0.0;
        }
      }
    } catch (_) {
      // Fallback locally using default rates
    }

    // Local estimation fallback matching backend priceService.js
    final fallbackRate = MaterialItem.defaultMaterials.firstWhere(
      (m) => m.material.toLowerCase() == material.toLowerCase(),
      orElse: () => const MaterialItem(material: 'Other', pricePerKg: 50.0),
    ).pricePerKg;

    return double.parse((weight * fallbackRate).toStringAsFixed(2));
  }
}
