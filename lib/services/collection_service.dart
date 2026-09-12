import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/collection.dart';
import '../models/recycler.dart';

/// Service for managing collections, status updates, and recycler coordination
/// via existing ScrapLink Backend APIs.
class CollectionService {
  final ApiClient _client;

  CollectionService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Retrieve collections assigned to a specific collector
  /// Calls existing GET /api/lots?collector_id=:collectorId
  Future<List<Collection>> getAssignedCollections(int collectorId) async {
    final response = await _client.get(
      ApiConstants.lots,
      queryParameters: {'collector_id': collectorId},
    );

    final collections = <Collection>[];
    if (response is Map<String, dynamic> && response['data'] is List) {
      for (final item in response['data']) {
        if (item is Map<String, dynamic>) {
          collections.add(Collection.fromJson(item));
        }
      }
    }

    return collections;
  }

  /// Retrieve complete collection details by Lot ID (e.g. 'SCRAP-0005')
  /// Calls existing GET /api/lots/:lotId
  Future<Collection> getCollectionDetail(String lotId) async {
    final response = await _client.get(ApiConstants.lotById(lotId));

    if (response is Map<String, dynamic>) {
      final data = response['data'] ?? response;
      if (data is Map<String, dynamic>) {
        return Collection.fromJson(data);
      }
    }

    throw const FormatException('Unexpected response format for collection details');
  }

  /// Update collection status in the existing database via existing backend
  /// Calls existing PUT /api/lots/:lotId/status
  Future<Collection> updateCollectionStatus(
    String lotId, {
    required String status,
    double? latitude,
    double? longitude,
    String? notes,
    int? recyclerId,
  }) async {
    final payload = <String, dynamic>{
      'status': status,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (notes != null) 'notes': notes,
      if (recyclerId != null) 'recycler_id': recyclerId,
    };

    final response = await _client.put(
      ApiConstants.lotStatus(lotId),
      body: payload,
    );

    if (response is Map<String, dynamic>) {
      final data = response['data'] ?? response;
      if (data is Map<String, dynamic>) {
        return Collection.fromJson(data);
      }
    }

    // If data payload was minimal, refetch full collection detail
    return getCollectionDetail(lotId);
  }

  /// Retrieve recycler details by recycler ID
  /// Calls existing GET /api/recyclers/:id
  Future<Recycler> getRecyclerDetail(int recyclerId) async {
    final response = await _client.get(ApiConstants.recyclerById(recyclerId));

    if (response is Map<String, dynamic>) {
      final data = response['data'] ?? response;
      if (data is Map<String, dynamic>) {
        return Recycler.fromJson(data);
      }
    }

    throw const FormatException('Unexpected response format for recycler details');
  }
}
