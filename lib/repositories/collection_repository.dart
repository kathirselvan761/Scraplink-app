import '../models/collection.dart';
import '../models/collection_status.dart';
import '../models/recycler.dart';
import '../services/collection_service.dart';

/// Repository managing collection workflows, status transitions, and data freshness.
///
/// NOTE: Direct MySQL queries are strictly forbidden. All operations flow through
/// the existing ScrapLink Backend API to ensure immediate consistency across
/// the Admin Web Portal, Recycler Web Portal, and Collector Mobile App.
class CollectionRepository {
  final CollectionService _service;

  CollectionRepository({CollectionService? service})
      : _service = service ?? CollectionService();

  /// Retrieve only collections assigned to the specified collector.
  /// Enforces collector isolation so Collector A only retrieves their collections.
  Future<List<Collection>> getAssignedCollections(int collectorId) async {
    return _service.getAssignedCollections(collectorId);
  }

  /// Retrieve fresh collection details by Lot ID (e.g. 'SCRAP-0005')
  Future<Collection> getCollectionDetails(String lotId) async {
    return _service.getCollectionDetail(lotId);
  }

  /// Evaluates which next status a Collector is permitted to transition to.
  ///
  /// Authorized Flow:
  /// REQUESTED / ACCEPTED / COLLECTION_ASSIGNED ➔ PICKUP_IN_PROGRESS
  /// PICKUP_IN_PROGRESS ➔ COLLECTED
  ///
  /// Subsequent stages (WEIGHED, RECEIVED, RECYCLED, COMPLETED, PAID)
  /// are strictly reserved for Recyclers and Admins.
  CollectionStatus? getCollectorAllowedNextStatus(CollectionStatus current) {
    switch (current) {
      case CollectionStatus.requested:
      case CollectionStatus.created:
      case CollectionStatus.available:
      case CollectionStatus.matched:
      case CollectionStatus.accepted:
      case CollectionStatus.collectionAssigned:
      case CollectionStatus.pickupScheduled:
        return CollectionStatus.pickupInProgress;

      case CollectionStatus.pickupInProgress:
      case CollectionStatus.inTransit:
        return CollectionStatus.collected;

      default:
        // No further collector-initiated transitions permitted
        return null;
    }
  }

  /// Whether a Collector is permitted to trigger an action button for this status
  bool isCollectorActionAllowed(CollectionStatus current) {
    return getCollectorAllowedNextStatus(current) != null;
  }

  /// Whether the collector is authorized to start pickup for this collection
  bool canStartPickup(CollectionStatus current) {
    return getCollectorAllowedNextStatus(current) == CollectionStatus.pickupInProgress;
  }

  /// Whether the collection pickup is actively in progress
  bool isPickupInProgress(CollectionStatus current) {
    return current == CollectionStatus.pickupInProgress ||
        current == CollectionStatus.inTransit;
  }

  /// Whether the collector is authorized to mark the collection as collected
  bool canMarkCollected(CollectionStatus current) {
    return getCollectorAllowedNextStatus(current) == CollectionStatus.collected;
  }

  /// Human-readable action label for the Collector action button
  String getCollectorActionLabel(CollectionStatus current) {
    final next = getCollectorAllowedNextStatus(current);
    if (next == CollectionStatus.pickupInProgress) {
      return 'Start Pickup (En Route)';
    }
    if (next == CollectionStatus.collected) {
      return 'Confirm Scrap Collected';
    }
    if (current == CollectionStatus.collected) {
      return 'Collected (Awaiting Recycler Receipt)';
    }
    if (current.isFinalized) {
      return 'Collection Completed';
    }
    return 'Processing by Recycler';
  }

  /// Update the status of a collection.
  ///
  /// The update is sent to the existing backend API (`PUT /api/lots/:lotId/status`),
  /// which writes directly to the shared MySQL `scrap_lots` and `lot_tracking` tables.
  Future<Collection> updateStatus(
    String lotId,
    CollectionStatus newStatus, {
    double? latitude,
    double? longitude,
    String? notes,
    int? recyclerId,
    int? collectorIdVerification,
  }) async {
    // Optional pre-check if collector ID verification is supplied
    if (collectorIdVerification != null) {
      final existing = await _service.getCollectionDetail(lotId);
      if (existing.scrap.collectorId != collectorIdVerification) {
        throw StateError(
          'Security Violation: Collector $collectorIdVerification cannot update collection assigned to Collector ${existing.scrap.collectorId}',
        );
      }
    }

    final defaultNotes = notes ?? (newStatus == CollectionStatus.pickupInProgress
        ? 'Collector began pickup en route to location'
        : (newStatus == CollectionStatus.collected
            ? 'Collector confirmed scrap picked up at collection site'
            : 'Collector updated status to ${newStatus.toBackendString()}'));

    return _service.updateCollectionStatus(
      lotId,
      status: newStatus.toBackendString(),
      latitude: latitude,
      longitude: longitude,
      notes: defaultNotes,
      recyclerId: recyclerId,
    );
  }

  /// Fetch details of the recycler associated with a collection
  Future<Recycler> getRecycler(int recyclerId) async {
    return _service.getRecyclerDetail(recyclerId);
  }

  /// Poll / refresh assigned collections to retrieve the latest backend state
  Future<List<Collection>> refreshAssignedCollections(int collectorId) async {
    return getAssignedCollections(collectorId);
  }
}
