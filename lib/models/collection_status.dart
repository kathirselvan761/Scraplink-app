/// Collection status enumeration mapped directly to the existing
/// ScrapLink backend and database status values.
enum CollectionStatus {
  requested('REQUESTED', 'Requested'),
  created('CREATED', 'Created'),
  available('AVAILABLE', 'Available'),
  matched('MATCHED', 'Matched'),
  accepted('ACCEPTED', 'Accepted'),
  collectionAssigned('COLLECTION_ASSIGNED', 'Collection Assigned'),
  pickupScheduled('PICKUP_SCHEDULED', 'Pickup Scheduled'),
  pickupInProgress('PICKUP_IN_PROGRESS', 'Pickup in Progress'),
  inTransit('IN_TRANSIT', 'In Transit'),
  collected('COLLECTED', 'Collected'),
  qrGenerated('QR_GENERATED', 'QR Generated'),
  weighed('WEIGHED', 'Weighed'),
  received('RECEIVED', 'Received'),
  handedOver('HANDED_OVER', 'Handed Over'),
  processing('PROCESSING', 'Processing'),
  recycled('RECYCLED', 'Recycled'),
  paid('PAID', 'Paid'),
  completed('COMPLETED', 'Completed');

  final String backendValue;
  final String displayName;

  const CollectionStatus(this.backendValue, this.displayName);

  /// Convert backend string representation to strongly-typed enum
  static CollectionStatus fromString(String? value) {
    if (value == null || value.trim().isEmpty) {
      return CollectionStatus.requested;
    }

    final normalized = value.trim().toUpperCase();

    for (final status in CollectionStatus.values) {
      if (status.backendValue == normalized) {
        return status;
      }
    }

    // Common backend aliases
    switch (normalized) {
      case 'PENDING':
      case 'PENDING_APPROVAL':
        return CollectionStatus.requested;
      case 'ASSIGNED':
        return CollectionStatus.collectionAssigned;
      case 'TRANSIT':
        return CollectionStatus.inTransit;
      default:
        return CollectionStatus.requested;
    }
  }

  /// Format as backend wire format string
  String toBackendString() => backendValue;

  /// Whether collection is pending pickup or active
  bool get isActive =>
      this != CollectionStatus.completed &&
      this != CollectionStatus.paid &&
      this != CollectionStatus.recycled;

  /// Whether collection is finalized
  bool get isFinalized =>
      this == CollectionStatus.completed ||
      this == CollectionStatus.paid ||
      this == CollectionStatus.recycled;

  /// Whether collection is currently assigned / in progress
  bool get isInProgress =>
      this == CollectionStatus.accepted ||
      this == CollectionStatus.collectionAssigned ||
      this == CollectionStatus.pickupInProgress ||
      this == CollectionStatus.inTransit ||
      this == CollectionStatus.collected;
}
