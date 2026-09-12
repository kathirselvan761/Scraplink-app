import 'package:flutter/material.dart';
import '../../core/network/api_exception.dart';
import '../../models/collection.dart';
import '../../models/collection_status.dart';
import '../../models/collector.dart';
import '../../models/recycler_request.dart';
import '../../repositories/auth_repository.dart';
import '../../services/collection_service.dart';
import '../../services/offer_service.dart';
import '../../widgets/app_status_chip.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_state_view.dart';
import '../../widgets/stat_card.dart';
import '../handover/handover_screen.dart';
import '../scrap/add_scrap_screen.dart';
import '../scrap/scrap_details_screen.dart';

/// Collector Dashboard displaying real backend metrics, live KPI statistics,
/// recent scraps, pending handovers, and a prominent "+ ADD SCRAP" primary action.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final CollectionService _collectionService = CollectionService();
  final OfferService _offerService = OfferService();

  bool _isLoading = true;
  String? _errorMessage;

  List<Collection> _allCollections = [];
  List<RecyclerRequest> _allRequests = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final collector = AuthRepository.instance.currentCollector;
      final collectorId = collector?.id ?? 2;

      final results = await Future.wait([
        _collectionService.getAssignedCollections(collectorId),
        _offerService.getOffers(),
      ]);

      if (mounted) {
        setState(() {
          _allCollections = results[0] as List<Collection>;
          _allRequests = results[1] as List<RecyclerRequest>;
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
          _errorMessage = 'Failed to load dashboard: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final collector = AuthRepository.instance.currentCollector ??
        const Collector(
          id: 2,
          name: 'DEMO - Collector User',
          email: 'collector@demo.scraplink.local',
        );

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.recycling_rounded, color: Color(0xFF10B981), size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'ScrapLink Collector',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF94A3B8)),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh Dashboard',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddScrapScreen()),
          ).then((_) => _loadDashboardData());
        },
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 22),
        label: const Text('+ ADD SCRAP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ),
      body: _buildBody(collector),
    );
  }

  Widget _buildBody(Collector collector) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      );
    }

    if (_errorMessage != null) {
      return ErrorStateView(
        message: _errorMessage!,
        onRetry: _loadDashboardData,
      );
    }

    // Dynamic metrics calculation
    final totalScraps = _allCollections.length;

    final now = DateTime.now();
    final todaysCollections = _allCollections.where((c) {
      final dt = c.requestedAt ?? c.scrap.createdAt;
      if (dt == null) return false;
      return dt.year == now.year && dt.month == now.month && dt.day == now.day;
    }).length;

    final pendingRequests = _allRequests.where((r) => r.isPending).length;

    final completedHandovers = _allCollections.where((c) {
      return c.status == CollectionStatus.received ||
          c.status == CollectionStatus.handedOver ||
          c.status == CollectionStatus.processing ||
          c.status == CollectionStatus.recycled ||
          c.status == CollectionStatus.completed;
    }).length;

    double totalWeight = 0.0;
    double totalValue = 0.0;
    for (final col in _allCollections) {
      totalWeight += col.weight;
      totalValue += col.estimatedPrice;
    }

    final recentScraps = _allCollections.take(3).toList();
    final pendingHandovers = _allRequests.where((r) => r.isPending || r.isAccepted).take(2).toList();

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: const Color(0xFF10B981),
      backgroundColor: const Color(0xFF1E293B),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Collector Welcome Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Color(0xFF10B981), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, ${collector.name}!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Collector ID: COL-${collector.id.toString().padLeft(4, '0')} • Active Duty',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Primary Hero Action: + ADD SCRAP
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddScrapScreen()),
                ).then((_) => _loadDashboardData());
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '+ ADD SCRAP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Register new collected e-waste & generate canonical Scrap ID',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Live Metrics Section Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Performance & Summary Metrics',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),

          // 6 KPI Cards Grid (Total Scraps, Today's Collections, Pending Requests, Completed Handovers, Total Weight, Total Value)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Total Scraps',
                        value: '$totalScraps',
                        icon: Icons.inventory_2_outlined,
                        accentColor: const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: "Today's Collections",
                        value: '$todaysCollections',
                        icon: Icons.today_outlined,
                        accentColor: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Pending Requests',
                        value: '$pendingRequests',
                        icon: Icons.pending_actions_outlined,
                        accentColor: const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: 'Completed Handovers',
                        value: '$completedHandovers',
                        icon: Icons.task_alt_outlined,
                        accentColor: const Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Total Weight',
                        value: '${totalWeight.toStringAsFixed(1)} kg',
                        icon: Icons.scale_outlined,
                        accentColor: const Color(0xFF06B6D4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: 'Total Value',
                        value: '₹${totalValue.toStringAsFixed(0)}',
                        icon: Icons.currency_rupee,
                        accentColor: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Pending Handovers Section
          if (pendingHandovers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pending Handovers',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: Text(
                      '${pendingHandovers.length} Action Needed',
                      style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ...pendingHandovers.map((req) => _buildPendingHandoverCard(req)),
            const SizedBox(height: 16),
          ],

          // Recent Scraps Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Scraps',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Showing ${recentScraps.length} of $totalScraps',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          if (recentScraps.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: EmptyStateView(
                title: 'No Scraps Registered',
                message: 'No scrap collections have been recorded yet. Tap "+ ADD SCRAP" to get started.',
                icon: Icons.inventory_2_outlined,
              ),
            )
          else
            ...recentScraps.map((col) => _buildRecentScrapCard(col)),

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildRecentScrapCard(Collection col) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF334155)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ScrapDetailsScreen(lotId: col.lotId)),
          ).then((_) => _loadDashboardData());
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.recycling_rounded, color: Color(0xFF10B981), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      col.lotId,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${col.material} • ${col.weight.toStringAsFixed(1)} kg • ₹${col.estimatedPrice.toStringAsFixed(0)}',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                  ],
                ),
              ),
              AppStatusChip(status: col.status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingHandoverCard(RecyclerRequest req) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFF59E0B)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.qr_code_scanner, color: Color(0xFFF59E0B), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    req.lotId,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'To: ${req.recyclerName} (${req.weight} kg)',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => HandoverScreen(lotId: req.lotId, initialWeight: req.weight),
                  ),
                ).then((_) => _loadDashboardData());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Handover', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
