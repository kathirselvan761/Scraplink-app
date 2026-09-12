import '../core/network/api_client.dart';
import '../models/recycler_request.dart';

/// Service for querying Recycler Requests and executing authorized Handovers
/// via existing ScrapLink Backend APIs.
class OfferService {
  final ApiClient _client;

  OfferService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Retrieve incoming recycler requests/offers
  /// Calls existing GET /api/offers
  Future<List<RecyclerRequest>> getOffers({
    String? lotId,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{
      if (lotId != null) 'lot_id': lotId,
      if (status != null) 'status': status,
    };

    final response = await _client.get(
      '/offers',
      queryParameters: queryParams,
    );

    final offers = <RecyclerRequest>[];
    if (response is Map<String, dynamic> && response['data'] is List) {
      for (final item in response['data']) {
        if (item is Map<String, dynamic>) {
          offers.add(RecyclerRequest.fromJson(item));
        }
      }
    }

    return offers;
  }

  /// Confirm scrap handover to recycler facility
  /// Calls existing POST /api/qr/handover
  Future<Map<String, dynamic>> confirmHandover({
    required String scrapRequestId,
    required double finalWeight,
    double? latitude,
    double? longitude,
  }) async {
    final payload = <String, dynamic>{
      'scrap_request_id': scrapRequestId,
      'final_weight': finalWeight,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };

    final response = await _client.post(
      '/qr/handover',
      body: payload,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw const FormatException('Unexpected response from handover endpoint');
  }
}
