import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/collection.dart';

/// Service for querying tracking history and lifecycle milestones from backend
class TrackingService {
  final ApiClient _client;

  TrackingService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Retrieve full tracking history for a scrap lot
  /// Calls existing GET /api/tracking/:lotId
  Future<Map<String, dynamic>> getTrackingDetails(String lotId) async {
    final response = await _client.get(ApiConstants.tracking(lotId));

    if (response is Map<String, dynamic>) {
      return response;
    }

    throw const FormatException('Unexpected response format from tracking endpoint');
  }

  /// Retrieve tracking events as typed list
  Future<List<TrackingEvent>> getTrackingEvents(String lotId) async {
    try {
      final response = await getTrackingDetails(lotId);
      final events = <TrackingEvent>[];

      final history = response['status_history'] ?? response['tracking_history'] ?? response['data'];
      if (history is List) {
        for (final item in history) {
          if (item is Map<String, dynamic>) {
            events.add(TrackingEvent.fromJson(item));
          }
        }
      }

      return events;
    } catch (_) {
      return [];
    }
  }
}
