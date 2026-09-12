import '../models/scrap.dart';
import '../services/scrap_service.dart';

/// Repository abstracting Scrap lot queries and tracking operations.
class ScrapRepository {
  final ScrapService _service;

  ScrapRepository({ScrapService? service})
      : _service = service ?? ScrapService();

  /// Retrieve list of scrap lots with optional filters
  Future<List<Scrap>> getScrapLots({
    int? collectorId,
    int? recyclerId,
    String? status,
    String? material,
  }) async {
    return _service.getScrapLots(
      collectorId: collectorId,
      recyclerId: recyclerId,
      status: status,
      material: material,
    );
  }

  /// Get specific scrap lot by its unique identifier (e.g. 'SCRAP-0005')
  Future<Scrap> getScrapById(String lotId) async {
    return _service.getScrapLotById(lotId);
  }

  /// Request the next unique sequential lot ID (e.g. 'SL-2026-00001')
  Future<String> getNextSequentialLotId() async {
    return _service.getNextLotId();
  }

  /// Get timeline tracking records for a scrap lot
  Future<Map<String, dynamic>> getTrackingHistory(String lotId) async {
    return _service.getTracking(lotId);
  }
}
