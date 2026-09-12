import '../models/collector.dart';
import '../services/collector_service.dart';

/// Repository abstracting Collector data retrieval and state.
class CollectorRepository {
  final CollectorService _service;
  Collector? _cachedCurrentCollector;

  CollectorRepository({CollectorService? service})
      : _service = service ?? CollectorService();

  /// Get current cached collector (if loaded)
  Collector? get currentCollector => _cachedCurrentCollector;

  /// Fetch collector profile by [collectorId]
  Future<Collector> getCollectorProfile(int collectorId) async {
    final collector = await _service.getCollectorById(collectorId);
    _cachedCurrentCollector = collector;
    return collector;
  }

  /// Fetch all collectors from existing backend
  Future<List<Collector>> getAllCollectors() async {
    return _service.getCollectors();
  }

  /// Clear in-memory collector cache
  void clearCache() {
    _cachedCurrentCollector = null;
  }
}
