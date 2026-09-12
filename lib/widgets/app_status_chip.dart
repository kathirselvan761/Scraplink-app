import 'package:flutter/material.dart';
import '../models/collection_status.dart';

/// Reusable widget for displaying collection status badges
class AppStatusChip extends StatelessWidget {
  final CollectionStatus status;

  const AppStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case CollectionStatus.requested:
      case CollectionStatus.created:
      case CollectionStatus.available:
        backgroundColor = const Color(0xFF3B82F6).withOpacity(0.15);
        textColor = const Color(0xFF60A5FA);
        break;
      case CollectionStatus.accepted:
      case CollectionStatus.collectionAssigned:
      case CollectionStatus.pickupScheduled:
      case CollectionStatus.pickupInProgress:
      case CollectionStatus.inTransit:
        backgroundColor = const Color(0xFFF59E0B).withOpacity(0.15);
        textColor = const Color(0xFFFBBF24);
        break;
      case CollectionStatus.collected:
      case CollectionStatus.qrGenerated:
      case CollectionStatus.weighed:
      case CollectionStatus.received:
      case CollectionStatus.handedOver:
      case CollectionStatus.processing:
        backgroundColor = const Color(0xFF8B5CF6).withOpacity(0.15);
        textColor = const Color(0xFFA78BFA);
        break;
      case CollectionStatus.recycled:
      case CollectionStatus.paid:
      case CollectionStatus.completed:
        backgroundColor = const Color(0xFF10B981).withOpacity(0.15);
        textColor = const Color(0xFF34D399);
        break;
      default:
        backgroundColor = const Color(0xFF64748B).withOpacity(0.15);
        textColor = const Color(0xFF94A3B8);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
