import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/collector.dart';

/// Service for interacting with collector endpoints on the existing ScrapLink API.
class CollectorService {
  final ApiClient _client;

  CollectorService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Fetch collector profile, statistics, and submissions by ID
  Future<Collector> getCollectorById(int id) async {
    final response = await _client.get(ApiConstants.collectorById(id));

    if (response is Map<String, dynamic>) {
      final data = response['data'] ?? response;
      if (data is Map<String, dynamic>) {
        return Collector.fromJson(data);
      }
    }

    throw const FormatException('Unexpected response format for collector profile');
  }

  /// Fetch list of all collectors
  Future<List<Collector>> getCollectors() async {
    final response = await _client.get(ApiConstants.collectors);

    final collectors = <Collector>[];
    if (response is Map<String, dynamic> && response['data'] is List) {
      for (final item in response['data']) {
        if (item is Map<String, dynamic>) {
          collectors.add(Collector.fromJson(item));
        }
      }
    }

    return collectors;
  }
}
