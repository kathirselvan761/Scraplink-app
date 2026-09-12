import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/scrap.dart';

/// Service for fetching and querying scrap lots directly from the existing backend.
class ScrapService {
  final ApiClient _client;

  ScrapService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Query scrap lots with optional filters matching backend `getScrapLots`
  Future<List<Scrap>> getScrapLots({
    int? collectorId,
    int? recyclerId,
    String? status,
    String? material,
  }) async {
    final queryParams = <String, dynamic>{
      if (collectorId != null) 'collector_id': collectorId,
      if (recyclerId != null) 'recycler_id': recyclerId,
      if (status != null) 'status': status,
      if (material != null) 'material': material,
    };

    final response = await _client.get(
      ApiConstants.lots,
      queryParameters: queryParams,
    );

    final lots = <Scrap>[];
    if (response is Map<String, dynamic> && response['data'] is List) {
      for (final item in response['data']) {
        if (item is Map<String, dynamic>) {
          lots.add(Scrap.fromJson(item));
        }
      }
    }

    return lots;
  }

  /// Get single scrap lot details by [lotId] (e.g. 'SCRAP-0005')
  Future<Scrap> getScrapLotById(String lotId) async {
    final response = await _client.get(ApiConstants.lotById(lotId));

    if (response is Map<String, dynamic>) {
      final data = response['data'] ?? response;
      if (data is Map<String, dynamic>) {
        return Scrap.fromJson(data);
      }
    }

    throw const FormatException('Unexpected response format for scrap lot details');
  }

  /// Get next sequential Lot ID preview (e.g. 'SL-2026-00001')
  Future<String> getNextLotId() async {
    final response = await _client.get(ApiConstants.nextLotId);

    if (response is Map<String, dynamic> && response.containsKey('next_id')) {
      return response['next_id'] as String;
    }

    return 'SL-2026-00001';
  }

  /// Create and submit a new scrap lot to the existing backend
  /// Calls existing POST /api/lots (supports multipart photo upload or JSON)
  Future<Scrap> createScrapLot({
    required String material,
    required double weight,
    double? estimatedPrice,
    String? notes,
    int? collectorId,
    String? imagePath,
    double? latitude,
    double? longitude,
  }) async {
    final fields = <String, String>{
      'material': material,
      'weight': weight.toString(),
      if (estimatedPrice != null && estimatedPrice > 0)
        'estimated_price': estimatedPrice.toString(),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      if (collectorId != null) 'collector_id': collectorId.toString(),
      if (latitude != null) 'latitude': latitude.toString(),
      if (longitude != null) 'longitude': longitude.toString(),
    };

    dynamic response;
    if (imagePath != null && imagePath.isNotEmpty) {
      response = await _client.multipartPost(
        ApiConstants.lots,
        fields: fields,
        fileField: 'image',
        filePath: imagePath,
      );
    } else {
      response = await _client.post(
        ApiConstants.lots,
        body: fields,
      );
    }

    if (response is Map<String, dynamic>) {
      final data = response['data'] ?? response;
      if (data is Map<String, dynamic>) {
        return Scrap.fromJson(data);
      }
    }

    throw const FormatException('Unexpected response format when creating scrap lot');
  }

  /// Get tracking timeline details for a lot
  Future<Map<String, dynamic>> getTracking(String lotId) async {
    final response = await _client.get(ApiConstants.tracking(lotId));

    if (response is Map<String, dynamic> && response.containsKey('data')) {
      return response['data'] as Map<String, dynamic>;
    }

    return response is Map<String, dynamic> ? response : {};
  }
}
