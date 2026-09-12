import 'package:flutter/material.dart';
import '../../core/network/api_exception.dart';
import '../../models/collection.dart';
import '../../models/collection_status.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/collection_repository.dart';
import '../../widgets/app_status_chip.dart';
import '../../widgets/error_state_view.dart';

/// Screen displaying complete collection details, customer info, recycler data,
/// lifecycle milestones, and the collector-authorized workflow:
/// START PICKUP ➔ PICKUP IN PROGRESS ➔ SCRAP VERIFICATION ➔ MARK COLLECTED
class CollectionDetailsScreen extends StatefulWidget {
  final String lotId;

  const CollectionDetailsScreen({super.key, required this.lotId});

  @override
  State<CollectionDetailsScreen> createState() => _CollectionDetailsScreenState();
}

class _CollectionDetailsScreenState extends State<CollectionDetailsScreen> {
  final CollectionRepository _collectionRepo = CollectionRepository();

  bool _isLoading = true;
  bool _isUpdatingStatus = false;
  bool _hasStatusChanged = false;
  bool _isScrapVerified = false;
  String? _errorMessage;
  Collection? _collection;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final details = await _collectionRepo.getCollectionDetails(widget.lotId);

      if (mounted) {
        setState(() {
          _collection = details;
          _isLoading = false;
          // Reset scrap verification checkbox if status has changed
          if (_collection?.status != CollectionStatus.pickupInProgress &&
              _collection?.status != CollectionStatus.inTransit) {
            _isScrapVerified = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Handles "Start Pickup" action with full confirmation and backend integration
  Future<void> _handleStartPickup(Collection col) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_shipping, color: Color(0xFFF59E0B), size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'Start Pickup',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you ready to head to the collection location for ${col.lotId}?',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDialogRow('Customer', col.displayCustomerName),
                  _buildDialogRow('Address', col.pickupAddress),
                  _buildDialogRow('Scrap', '${col.material} (${col.weight.toStringAsFixed(1)} kg)'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '• Status will update to PICKUP_IN_PROGRESS\n• Customer & dispatch will be notified that you are en route',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.navigation, size: 16),
            label: const Text('Confirm Start Pickup'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _executeStatusUpdate(
      targetStatus: CollectionStatus.pickupInProgress,
      notes: 'Collector began pickup en route to site: ${col.pickupAddress}',
      successMessage: '🚗 Pickup started! Status updated to PICKUP_IN_PROGRESS.',
    );
  }

  /// Handles "Mark as Collected" action with full confirmation and backend integration
  Future<void> _handleMarkCollected(Collection col) async {
    if (!_isScrapVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFEF4444),
          content: Text('⚠️ Please confirm the Scrap Verification Checklist before marking as collected.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'Confirm Collection',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Have you received and loaded the verified scrap for ${col.lotId}?',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDialogRow('Material', col.material),
                  _buildDialogRow('Est. Weight', '${col.weight.toStringAsFixed(2)} kg'),
                  _buildDialogRow('From', col.displayCustomerName),
                  _buildDialogRow('Verified', 'Yes, physically inspected'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '• Status will update to COLLECTED in shared database\n• Recycler facility dock will be alerted for incoming intake',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.inventory_2, size: 16),
            label: const Text('Confirm Collected'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _executeStatusUpdate(
      targetStatus: CollectionStatus.collected,
      notes: 'Collector verified scrap on-site and confirmed collection from ${col.displayCustomerName}',
      successMessage: '✅ Scrap collected! Status updated to COLLECTED in database.',
    );
  }

  /// Core helper to update status via repository with comprehensive error handling
  Future<void> _executeStatusUpdate({
    required CollectionStatus targetStatus,
    required String notes,
    required String successMessage,
  }) async {
    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      final currentCollectorId = AuthRepository.instance.currentCollector?.id;

      final updated = await _collectionRepo.updateStatus(
        widget.lotId,
        targetStatus,
        notes: notes,
        collectorIdVerification: currentCollectorId,
      );

      if (mounted) {
        setState(() {
          _collection = updated;
          _isUpdatingStatus = false;
          _hasStatusChanged = true;
          _isScrapVerified = false; // Reset verification after collection
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text(
              successMessage,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });

        String userMsg;
        switch (e.statusCode) {
          case 401:
            userMsg = 'Authentication session expired. Please log in again.';
            break;
          case 403:
            userMsg = 'Permission Denied: You are not authorized to update this collection.';
            break;
          case 404:
            userMsg = 'Collection not found in the ScrapLink database.';
            break;
          case 409:
            userMsg = 'Status Conflict: This collection status was already updated by another user.';
            break;
          case 500:
            userMsg = 'Server Error: Failed to save status update. Please try again.';
            break;
          default:
            userMsg = e.userFriendlyMessage;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text('❌ $userMsg'),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _fetchDetails(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text('❌ Update failed: $e'),
          ),
        );
      }
    }
  }

  Widget _buildDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 75,
            child: Text(
              '$label:',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Parent screen will receive _hasStatusChanged
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(_hasStatusChanged),
          ),
          title: Text(
            widget.lotId,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF94A3B8)),
              onPressed: _isLoading ? null : _fetchDetails,
              tooltip: 'Refresh Details',
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      );
    }

    if (_errorMessage != null) {
      return ErrorStateView(
        message: _errorMessage!,
        onRetry: _fetchDetails,
      );
    }

    if (_collection == null) {
      return const Center(
        child: Text(
          'Collection not found in database',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final col = _collection!;
    final sched = col.scheduledDateTime;
    final schedDateStr = sched != null
        ? '${sched.day.toString().padLeft(2, '0')}/${sched.month.toString().padLeft(2, '0')}/${sched.year} ${sched.hour.toString().padLeft(2, '0')}:${sched.minute.toString().padLeft(2, '0')}'
        : 'Pending Scheduling';

    return RefreshIndicator(
      onRefresh: _fetchDetails,
      color: const Color(0xFF10B981),
      backgroundColor: const Color(0xFF1E293B),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Scrap ID & Status Header Card
          _buildHeaderCard(col),

          const SizedBox(height: 12),

          // 2. Workflow Progress Steps Tracker
          _buildWorkflowStepper(col.status),

          const SizedBox(height: 12),

          // 3. Collector Action & Verification Section
          _buildCollectorWorkflowSection(col),

          const SizedBox(height: 12),

          // 4. Customer & Pickup Details
          _buildCard(
            title: 'Customer & Pickup Details',
            icon: Icons.person_pin_circle_outlined,
            child: Column(
              children: [
                _buildRow('Customer / Source', col.displayCustomerName),
                _buildRow('Customer Phone', col.customerPhone ?? 'Available via dispatch'),
                _buildRow('Pickup Address', col.pickupAddress),
                _buildRow('Scheduled Pickup', schedDateStr),
                if (col.scrap.latitude != null && col.scrap.longitude != null)
                  _buildRow(
                    'GPS Location',
                    '${col.scrap.latitude!.toStringAsFixed(4)}, ${col.scrap.longitude!.toStringAsFixed(4)}',
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 5. Scrap Material & Weight Specifications
          _buildCard(
            title: 'Scrap Specifications',
            icon: Icons.recycling_outlined,
            child: Column(
              children: [
                _buildRow('Scrap Category / Type', col.material),
                _buildRow('Estimated Quantity', '${col.weight.toStringAsFixed(2)} kg'),
                if (col.finalWeight != null)
                  _buildRow('Verified Final Weight', '${col.finalWeight!.toStringAsFixed(2)} kg'),
                _buildRow(
                  'Estimated Value',
                  '₹${col.estimatedPrice.toStringAsFixed(2)}',
                  valueColor: const Color(0xFF10B981),
                ),
                if (col.scrap.confidence > 0)
                  _buildRow(
                    'AI Verification Confidence',
                    '${(col.scrap.confidence * 100).toStringAsFixed(1)}%',
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 6. Recycler Facility Information
          _buildCard(
            title: 'Assigned Recycler Facility',
            icon: Icons.business_outlined,
            child: Column(
              children: [
                _buildRow(
                  'Recycler Facility',
                  col.recyclerName?.isNotEmpty == true
                      ? col.recyclerName!
                      : 'Pending Assignment to Hub',
                ),
                _buildRow(
                  'Recycler Phone',
                  col.recyclerPhone?.isNotEmpty == true ? col.recyclerPhone! : 'Not Available',
                ),
                _buildRow(
                  'Yard / Processing Address',
                  col.recyclerAddress?.isNotEmpty == true
                      ? col.recyclerAddress!
                      : 'Regional Recycling Facility, Chennai',
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 7. Collection Notes
          _buildCard(
            title: 'Collection Notes',
            icon: Icons.notes_outlined,
            child: Text(
              col.scrap.notes?.isNotEmpty == true
                  ? col.scrap.notes!
                  : 'No specific notes recorded for this collection.',
              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, height: 1.4),
            ),
          ),

          const SizedBox(height: 12),

          // 8. Assigned Collector
          _buildCard(
            title: 'Assigned Collector Profile',
            icon: Icons.badge_outlined,
            child: Column(
              children: [
                _buildRow(
                  'Collector Name',
                  col.collectorName?.isNotEmpty == true
                      ? col.collectorName!
                      : 'Assigned Field Collector',
                ),
                _buildRow('Collector ID', 'COL-${col.scrap.collectorId.toString().padLeft(4, '0')}'),
                if (col.collectorPhone != null)
                  _buildRow('Phone', col.collectorPhone!),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 9. Lifecycle Milestones
          _buildCard(
            title: 'Lifecycle Milestones',
            icon: Icons.calendar_month_outlined,
            child: Column(
              children: [
                _buildRow('Requested Date', _formatDate(col.requestedAt ?? col.scrap.createdAt)),
                if (col.acceptedAt != null)
                  _buildRow('Accepted Date', _formatDate(col.acceptedAt)),
                if (col.collectedAt != null)
                  _buildRow('Collected Date', _formatDate(col.collectedAt)),
                if (col.weighedAt != null)
                  _buildRow('Weighed Date', _formatDate(col.weighedAt)),
                if (col.completedAt != null)
                  _buildRow('Completed Date', _formatDate(col.completedAt)),
              ],
            ),
          ),

          // 10. Tracking Events History Log
          if (col.trackingHistory.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildCard(
              title: 'Tracking Events Audit Log (${col.trackingHistory.length})',
              icon: Icons.history_outlined,
              child: Column(
                children: col.trackingHistory.map((event) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.status,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (event.notes != null && event.notes!.isNotEmpty)
                                Text(
                                  event.notes!,
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 12,
                                  ),
                                ),
                              if (event.timestamp != null)
                                Text(
                                  _formatDate(event.timestamp),
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Header Card showing Scrap ID, MySQL Record ID, and Status Badge
  Widget _buildHeaderCard(Collection col) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scrap Lot ID',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                  Text(
                    col.lotId,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              AppStatusChip(status: col.status),
            ],
          ),
          if (col.scrap.id != null) ...[
            const SizedBox(height: 6),
            Text(
              'MySQL Record ID: #${col.scrap.id}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  /// Visual 5-Stage Stepper for the collection workflow
  Widget _buildWorkflowStepper(CollectionStatus status) {
    int currentStep = 1;
    if (_collectionRepo.isPickupInProgress(status)) {
      currentStep = 2;
    } else if (status == CollectionStatus.collected) {
      currentStep = 3;
    } else if (status == CollectionStatus.weighed ||
        status == CollectionStatus.received ||
        status == CollectionStatus.processing) {
      currentStep = 4;
    } else if (status.isFinalized) {
      currentStep = 5;
    }

    final steps = [
      'Assigned',
      'En Route',
      'Collected',
      'Facility',
      'Done',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Collection Progress',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index.isOdd) {
                final lineIndex = index ~/ 2;
                final isPassed = currentStep > lineIndex + 1;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: isPassed ? const Color(0xFF10B981) : const Color(0xFF334155),
                  ),
                );
              }

              final stepIndex = index ~/ 2 + 1;
              final isCompleted = currentStep > stepIndex;
              final isCurrent = currentStep == stepIndex;

              Color circleBg;
              Color circleBorder;
              Widget iconOrNumber;

              if (isCompleted) {
                circleBg = const Color(0xFF10B981);
                circleBorder = const Color(0xFF10B981);
                iconOrNumber = const Icon(Icons.check, size: 12, color: Colors.white);
              } else if (isCurrent) {
                circleBg = const Color(0xFFF59E0B);
                circleBorder = const Color(0xFFF59E0B);
                iconOrNumber = Text(
                  '$stepIndex',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                );
              } else {
                circleBg = const Color(0xFF0F172A);
                circleBorder = const Color(0xFF475569);
                iconOrNumber = Text(
                  '$stepIndex',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                );
              }

              return Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: circleBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: circleBorder, width: 1.5),
                    ),
                    child: Center(child: iconOrNumber),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    steps[index ~/ 2],
                    style: TextStyle(
                      color: isCurrent
                          ? const Color(0xFFFBBF24)
                          : (isCompleted ? Colors.white : const Color(0xFF64748B)),
                      fontSize: 10,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Dynamic Collector Workflow section handling:
  /// 1. "Start Pickup"
  /// 2. "Pickup In Progress" + "Scrap Verification" + "Mark Collected"
  /// 3. Read-only informational states
  Widget _buildCollectorWorkflowSection(Collection col) {
    // 1. Can Start Pickup State
    if (_collectionRepo.canStartPickup(col.status)) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.local_shipping_outlined, color: Color(0xFFF59E0B), size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ready for Pickup',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Collection assigned. Tap below to notify dispatch that you are en route.',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isUpdatingStatus ? null : () => _handleStartPickup(col),
                icon: _isUpdatingStatus
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.navigation_outlined, size: 18),
                label: Text(
                  _isUpdatingStatus ? 'Starting Pickup...' : 'Start Pickup',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 2. Active Pickup In Progress + Verification Section
    if (_collectionRepo.isPickupInProgress(col.status)) {
      return Column(
        children: [
          // En Route Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFD97706).withValues(alpha: 0.25),
                  const Color(0xFF1E293B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.directions_car, color: Color(0xFFFBBF24), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pickup In Progress • En Route',
                        style: TextStyle(
                          color: Color(0xFFFBBF24),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Proceeding to ${col.pickupAddress}. When arrived, inspect scrap and complete the verification checklist below.',
                        style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Scrap Verification Section (Mandatory before marking collected)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isScrapVerified ? const Color(0xFF10B981) : const Color(0xFF334155),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isScrapVerified ? Icons.verified : Icons.fact_check_outlined,
                      color: _isScrapVerified ? const Color(0xFF10B981) : const Color(0xFF38BDF8),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Scrap Verification Checklist',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Verify material specifications with the customer on-site:',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
                const SizedBox(height: 10),

                // Verification Specs Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    children: [
                      _buildVerificationItem('Scrap Lot ID', col.lotId),
                      _buildVerificationItem('Scrap Category', col.material),
                      _buildVerificationItem('Expected Weight', '${col.weight.toStringAsFixed(2)} kg'),
                      _buildVerificationItem('Customer Name', col.displayCustomerName),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Interactive Verification Checkbox
                InkWell(
                  onTap: () {
                    setState(() {
                      _isScrapVerified = !_isScrapVerified;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isScrapVerified
                          ? const Color(0xFF10B981).withValues(alpha: 0.12)
                          : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isScrapVerified ? const Color(0xFF10B981) : const Color(0xFF475569),
                      ),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _isScrapVerified,
                          activeColor: const Color(0xFF10B981),
                          onChanged: (val) {
                            setState(() {
                              _isScrapVerified = val ?? false;
                            });
                          },
                        ),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scrap verified and ready for collection',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'I have inspected the materials and confirmed the lot details on site.',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Mark as Collected Button (Gated by verification checkbox)
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (_isScrapVerified && !_isUpdatingStatus)
                        ? () => _handleMarkCollected(col)
                        : null,
                    icon: _isUpdatingStatus
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(
                      _isUpdatingStatus
                          ? 'Updating to Collected...'
                          : 'Mark as Collected',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF334155),
                      disabledForegroundColor: const Color(0xFF64748B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

                if (!_isScrapVerified) ...[
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      '⚠️ Check "Scrap verified" above to enable collection confirmation',
                      style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    // 3. Informational card for stages where collector has no pending action
    String infoMessage;
    IconData infoIcon;
    Color infoColor;

    if (col.status == CollectionStatus.collected) {
      infoMessage = 'Scrap Collected. Awaiting Recycler Receipt & Weighing at facility dock.';
      infoIcon = Icons.inventory_2_rounded;
      infoColor = const Color(0xFF10B981);
    } else if (col.status.isFinalized) {
      infoMessage = 'Collection Lifecycle Finalized and archived.';
      infoIcon = Icons.task_alt;
      infoColor = const Color(0xFF3B82F6);
    } else {
      infoMessage = 'Stage is currently managed by Recycler / Processing Facility.';
      infoIcon = Icons.factory_outlined;
      infoColor = const Color(0xFF94A3B8);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Icon(infoIcon, color: infoColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              infoMessage,
              style: TextStyle(
                color: infoColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    String? title,
    IconData? icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: const Color(0xFF10B981), size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(color: Color(0xFF334155), height: 20),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'N/A';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
