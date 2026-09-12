import 'package:flutter/material.dart';
import '../../models/collection.dart';
import '../../models/collection_status.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/collection_repository.dart';
import '../../widgets/collection_card.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_state_view.dart';
import 'collection_details_screen.dart';

/// Screen displaying the complete filterable list of collections assigned to this collector
class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  final CollectionRepository _collectionRepo = CollectionRepository();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<Collection> _allCollections = [];
  String _selectedFilter = 'ALL'; // ALL, PENDING, IN_PROGRESS, COMPLETED

  @override
  void initState() {
    super.initState();
    _fetchCollections();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCollections() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final collectorId = AuthRepository.instance.currentCollector?.id ?? 2;
      final data = await _collectionRepo.getAssignedCollections(collectorId);

      if (mounted) {
        setState(() {
          _allCollections = data;
          _isLoading = false;
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

  List<Collection> get _filteredCollections {
    final query = _searchController.text.trim().toLowerCase();

    return _allCollections.where((col) {
      // Status Filter
      if (_selectedFilter == 'PENDING') {
        final isPending = col.status == CollectionStatus.requested ||
            col.status == CollectionStatus.created ||
            col.status == CollectionStatus.available ||
            col.status == CollectionStatus.matched ||
            col.status == CollectionStatus.accepted ||
            col.status == CollectionStatus.collectionAssigned ||
            col.status == CollectionStatus.pickupScheduled;
        if (!isPending) return false;
      } else if (_selectedFilter == 'IN_PROGRESS') {
        final isInProg = col.status == CollectionStatus.pickupInProgress ||
            col.status == CollectionStatus.inTransit;
        if (!isInProg) return false;
      } else if (_selectedFilter == 'COMPLETED') {
        final isDone = col.status == CollectionStatus.collected ||
            col.status == CollectionStatus.weighed ||
            col.status == CollectionStatus.received ||
            col.status == CollectionStatus.handedOver ||
            col.status == CollectionStatus.processing ||
            col.status == CollectionStatus.recycled ||
            col.status == CollectionStatus.paid ||
            col.status == CollectionStatus.completed;
        if (!isDone) return false;
      }

      // Search Query Filter
      if (query.isNotEmpty) {
        final matchesId = col.lotId.toLowerCase().contains(query);
        final matchesCustomer = col.displayCustomerName.toLowerCase().contains(query);
        final matchesMaterial = col.material.toLowerCase().contains(query);
        final matchesAddress = col.pickupAddress.toLowerCase().contains(query);
        return matchesId || matchesCustomer || matchesMaterial || matchesAddress;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCollections;

    final pendingCount = _allCollections.where((c) {
      return c.status == CollectionStatus.requested ||
          c.status == CollectionStatus.created ||
          c.status == CollectionStatus.available ||
          c.status == CollectionStatus.matched ||
          c.status == CollectionStatus.accepted ||
          c.status == CollectionStatus.collectionAssigned ||
          c.status == CollectionStatus.pickupScheduled;
    }).length;

    final inProgCount = _allCollections.where((c) {
      return c.status == CollectionStatus.pickupInProgress ||
          c.status == CollectionStatus.inTransit;
    }).length;

    final completedCount = _allCollections.where((c) {
      return c.status == CollectionStatus.collected ||
          c.status == CollectionStatus.weighed ||
          c.status == CollectionStatus.received ||
          c.status == CollectionStatus.handedOver ||
          c.status == CollectionStatus.processing ||
          c.status == CollectionStatus.recycled ||
          c.status == CollectionStatus.paid ||
          c.status == CollectionStatus.completed;
    }).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'Assigned Collections',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF94A3B8)),
            onPressed: _fetchCollections,
            tooltip: 'Refresh Collections',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1E293B),
            child: Column(
              children: [
                // Search Input Field
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search by Scrap ID, customer, address...',
                    hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Color(0xFF94A3B8), size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Status Filter Chips (Single horizontal scroll to prevent overflow)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('ALL', 'All (${_allCollections.length})'),
                      const SizedBox(width: 8),
                      _buildFilterChip('PENDING', 'Pending ($pendingCount)'),
                      const SizedBox(width: 8),
                      _buildFilterChip('IN_PROGRESS', 'In-Progress ($inProgCount)'),
                      const SizedBox(width: 8),
                      _buildFilterChip('COMPLETED', 'Completed ($completedCount)'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Collections Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchCollections,
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
    final isSelected = _selectedFilter == filterKey;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = filterKey;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildListContent(List<Collection> collections) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      );
    }

    if (_errorMessage != null) {
      return ErrorStateView(
        message: _errorMessage!,
        onRetry: _fetchCollections,
      );
    }

    if (collections.isEmpty) {
      return EmptyStateView(
        title: 'No Collections Found',
        message: _searchController.text.isNotEmpty
            ? 'No assigned collections match your search filter.'
            : 'No collections currently found for this status tab.',
        onAction: _fetchCollections,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: collections.length,
      itemBuilder: (context, index) {
        final col = collections[index];
        return CollectionCard(
          collection: col,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CollectionDetailsScreen(lotId: col.lotId),
              ),
            ).then((_) {
              // Refresh collections when returning in case status was changed
              _fetchCollections();
            });
          },
        );
      },
    );
  }
}
