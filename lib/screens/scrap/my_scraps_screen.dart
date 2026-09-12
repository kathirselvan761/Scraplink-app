import 'package:flutter/material.dart';
import '../../core/network/api_exception.dart';
import '../../models/collection.dart';
import '../../models/collection_status.dart';
import '../../repositories/auth_repository.dart';
import '../../services/collection_service.dart';
import '../../widgets/app_status_chip.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_state_view.dart';
import 'add_scrap_screen.dart';
import 'scrap_details_screen.dart';

/// Screen displaying only scraps relevant to the logged-in Collector,
/// fetched live from `GET /api/lots?collector_id=:id`.
class MyScrapsScreen extends StatefulWidget {
  const MyScrapsScreen({super.key});

  @override
  State<MyScrapsScreen> createState() => _MyScrapsScreenState();
}

class _MyScrapsScreenState extends State<MyScrapsScreen> {
  final CollectionService _collectionService = CollectionService();
  final TextEditingController _searchController = TextEditingController();

  List<Collection> _allScraps = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _fetchMyScraps();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyScraps() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final collectorId = AuthRepository.instance.currentCollector?.id ?? 2;
      final scraps = await _collectionService.getAssignedCollections(collectorId);

      if (mounted) {
        setState(() {
          _allScraps = scraps;
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
          _errorMessage = 'Failed to load scraps: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<Collection> get _filteredScraps {
    final query = _searchController.text.trim().toLowerCase();

    return _allScraps.where((col) {
      // Status filter
      if (_selectedStatusFilter == 'AVAILABLE') {
        if (col.status != CollectionStatus.available && col.status != CollectionStatus.requested) {
          return false;
        }
      } else if (_selectedStatusFilter == 'IN_PROGRESS') {
        final inProg = col.status == CollectionStatus.collectionAssigned ||
            col.status == CollectionStatus.pickupInProgress ||
            col.status == CollectionStatus.inTransit ||
            col.status == CollectionStatus.accepted;
        if (!inProg) return false;
      } else if (_selectedStatusFilter == 'COMPLETED') {
        final done = col.status == CollectionStatus.collected ||
            col.status == CollectionStatus.received ||
            col.status == CollectionStatus.weighed ||
            col.status == CollectionStatus.completed;
        if (!done) return false;
      }

      // Query filter
      if (query.isNotEmpty) {
        final matchId = col.lotId.toLowerCase().contains(query);
        final matchMaterial = col.material.toLowerCase().contains(query);
        final matchNotes = (col.scrap.notes ?? '').toLowerCase().contains(query);
        return matchId || matchMaterial || matchNotes;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredScraps;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'My Scraps',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF94A3B8)),
            onPressed: _fetchMyScraps,
            tooltip: 'Refresh Scraps',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddScrapScreen()),
          ).then((_) => _fetchMyScraps());
        },
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Scrap', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: const Color(0xFF1E293B),
            child: Column(
              children: [
                // Search Field
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search by Scrap ID, material...',
                    hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Color(0xFF94A3B8), size: 18),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('ALL', 'All Scraps (${_allScraps.length})'),
                      const SizedBox(width: 8),
                      _buildFilterChip('AVAILABLE', 'Available'),
                      const SizedBox(width: 8),
                      _buildFilterChip('IN_PROGRESS', 'In Progress'),
                      const SizedBox(width: 8),
                      _buildFilterChip('COMPLETED', 'Completed'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main List View
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchMyScraps,
              color: const Color(0xFF10B981),
              backgroundColor: const Color(0xFF1E293B),
              child: _buildListContent(filtered),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedStatusFilter == filterKey;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatusFilter = filterKey;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : const Color(0xFF334155),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildListContent(List<Collection> scraps) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      );
    }

    if (_errorMessage != null) {
      return ErrorStateView(
        message: _errorMessage!,
        onRetry: _fetchMyScraps,
      );
    }

    if (scraps.isEmpty) {
      return EmptyStateView(
        title: 'No Scraps Found',
        message: _searchController.text.isNotEmpty
            ? 'No scraps match your search criteria.'
            : 'You have not added any scrap lots yet. Tap below to create your first collection.',
        actionLabel: '+ Add Scrap',
        onAction: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddScrapScreen()),
          ).then((_) => _fetchMyScraps());
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      itemCount: scraps.length,
      itemBuilder: (context, index) {
        final item = scraps[index];
        final dt = item.scrap.createdAt ?? DateTime.now();
        final dateStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF334155)),
          ),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ScrapDetailsScreen(lotId: item.lotId),
                ),
              ).then((_) => _fetchMyScraps());
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Scrap ID and Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.recycling_rounded, color: Color(0xFF10B981), size: 18),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            item.lotId,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      AppStatusChip(status: item.status),
                    ],
                  ),
                  const Divider(color: Color(0xFF334155), height: 20),

                  // Material & Weight
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoColumn('Material', item.material),
                      _buildInfoColumn('Weight', '${item.weight.toStringAsFixed(1)} kg'),
                      _buildInfoColumn(
                        'Estimated Value',
                        '₹${item.estimatedPrice.toStringAsFixed(0)}',
                        valueColor: const Color(0xFF10B981),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Created Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, color: Color(0xFF64748B), size: 13),
                          const SizedBox(width: 6),
                          Text(
                            'Added: $dateStr',
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                        ],
                      ),
                      const Row(
                        children: [
                          Text(
                            'View Details',
                            style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Icon(Icons.chevron_right, color: Color(0xFF10B981), size: 16),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoColumn(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
