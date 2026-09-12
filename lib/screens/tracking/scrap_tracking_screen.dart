import 'package:flutter/material.dart';
import '../../core/network/api_exception.dart';
import '../../models/collection.dart';
import '../../models/collection_status.dart';
import '../../services/tracking_service.dart';
import '../../widgets/app_status_chip.dart';
import '../../widgets/error_state_view.dart';

/// Screen displaying the end-to-end traceability journey and audit timeline
/// for a scrap lot from `GET /api/tracking/:lotId`.
class ScrapTrackingScreen extends StatefulWidget {
  final String lotId;

  const ScrapTrackingScreen({super.key, required this.lotId});

  @override
  State<ScrapTrackingScreen> createState() => _ScrapTrackingScreenState();
}

class _ScrapTrackingScreenState extends State<ScrapTrackingScreen> {
  final TrackingService _trackingService = TrackingService();

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _trackingData;
  List<TrackingEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _fetchTracking();
  }

  Future<void> _fetchTracking() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final details = await _trackingService.getTrackingDetails(widget.lotId);
      final events = await _trackingService.getTrackingEvents(widget.lotId);

      if (mounted) {
        setState(() {
          _trackingData = details;
          _events = events;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.userFriendlyMessage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load tracking data: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Text(
          'Tracking: ${widget.lotId}',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF94A3B8)),
            onPressed: _fetchTracking,
            tooltip: 'Refresh Timeline',
          ),
        ],
      ),
      body: _buildBody(),
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
        onRetry: _fetchTracking,
      );
    }

    final rawStatus = _trackingData?['lot']?['status'] ??
        _trackingData?['status'] ??
        (_events.isNotEmpty ? _events.last.status : 'AVAILABLE');
    final status = CollectionStatus.fromString(rawStatus.toString());

    return RefreshIndicator(
      onRefresh: _fetchTracking,
      color: const Color(0xFF10B981),
      backgroundColor: const Color(0xFF1E293B),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Status Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current Lifecycle Stage', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      status.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                AppStatusChip(status: status),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Lifecycle Milestone Progression
          _buildLifecycleProgressCard(status),

          const SizedBox(height: 20),

          // Detailed Audit Log Timeline
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              'Audit Trail & Verification Events',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),

          if (_events.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: const Center(
                child: Text(
                  'Initial tracking record registered. Further status updates will appear as the scrap progresses through collection and recycling.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
              ),
            )
          else
            ..._events.map((event) => _buildTimelineEventTile(event)),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLifecycleProgressCard(CollectionStatus current) {
    // Canonical backend stages in sequence
    final stages = [
      {'label': 'Registered', 'key': 'AVAILABLE'},
      {'label': 'Requested', 'key': 'ACCEPTED'},
      {'label': 'Collected', 'key': 'COLLECTED'},
      {'label': 'Received', 'key': 'RECEIVED'},
      {'label': 'Completed', 'key': 'COMPLETED'},
    ];

    int currentIndex = 0;
    if (current == CollectionStatus.accepted || current == CollectionStatus.collectionAssigned) {
      currentIndex = 1;
    } else if (current == CollectionStatus.pickupInProgress || current == CollectionStatus.collected) {
      currentIndex = 2;
    } else if (current == CollectionStatus.received || current == CollectionStatus.weighed || current == CollectionStatus.processing) {
      currentIndex = 3;
    } else if (current.isFinalized) {
      currentIndex = 4;
    }

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
          const Text('Lifecycle Traceability', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(
            children: List.generate(stages.length * 2 - 1, (index) {
              if (index.isOdd) {
                final lineIdx = index ~/ 2;
                final isDone = currentIndex > lineIdx;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: isDone ? const Color(0xFF10B981) : const Color(0xFF334155),
                  ),
                );
              }

              final stageIdx = index ~/ 2;
              final isDone = currentIndex > stageIdx;
              final isCurrent = currentIndex == stageIdx;

              Color bg = isDone
                  ? const Color(0xFF10B981)
                  : (isCurrent ? const Color(0xFFF59E0B) : const Color(0xFF0F172A));
              Color border = isDone
                  ? const Color(0xFF10B981)
                  : (isCurrent ? const Color(0xFFF59E0B) : const Color(0xFF475569));

              return Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: bg,
                      shape: BoxShape.circle,
                      border: Border.all(color: border, width: 1.5),
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check, color: Colors.white, size: 12)
                          : Text(
                              '${stageIdx + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stages[stageIdx]['label']!,
                    style: TextStyle(
                      color: isCurrent
                          ? const Color(0xFFFBBF24)
                          : (isDone ? Colors.white : const Color(0xFF64748B)),
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

  Widget _buildTimelineEventTile(TrackingEvent event) {
    final dt = event.timestamp;
    final dateStr = dt != null
        ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
        : 'Timestamp Recorded';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.status,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                if (event.notes != null && event.notes!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    event.notes!,
                    style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
