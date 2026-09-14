import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/scrap_lot_model.dart';
import '../../providers/lot_provider.dart';
import '../../widgets/lot_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_box.dart';
import '../scrap/create_lot_screen.dart';
import '../scrap/lot_detail_screen.dart';

class MyLotsTab extends StatefulWidget {
  const MyLotsTab({super.key});

  @override
  State<MyLotsTab> createState() => _MyLotsTabState();
}

class _MyLotsTabState extends State<MyLotsTab> {
  String _selectedFilter = 'All';

  final List<String> _filters = const [
    'All',
    'Requested',
    'Accepted',
    'Collected',
    'In Transit',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LotProvider>().loadMyLots();
    });
  }

  bool _matchesFilter(ScrapLotModel lot, String filter) {
    final status = lot.status.toUpperCase();
    switch (filter) {
      case 'Requested':
        return status == 'REQUESTED';
      case 'Accepted':
        return status == 'ACCEPTED';
      case 'Collected':
        return status == 'COLLECTED';
      case 'In Transit':
        return ['HANDED_OVER', 'IN_TRANSIT', 'RECEIVED', 'PROCESSING'].contains(status);
      case 'Completed':
        return ['RECYCLED', 'COMPLETED'].contains(status);
      case 'All':
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lotProvider = context.watch<LotProvider>();
    final allLots = lotProvider.myLots;
    final filteredLots = allLots.where((lot) => _matchesFilter(lot, _selectedFilter)).toList();
    final isLoading = lotProvider.isLoading;

    return Scaffold(
      body: Column(
        children: [
          // Filter Chips Row
          Container(
            height: 56,
            color: Colors.white,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;

                return ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryGreen.withAlpha(30),
                  backgroundColor: Colors.grey.shade100,
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.primaryGreen : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedFilter = filter);
                    }
                  },
                );
              },
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

          // Lots List with Pull to Refresh
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context.read<LotProvider>().loadMyLots(),
              color: AppTheme.primaryGreen,
              child: isLoading && allLots.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: List.generate(4, (_) => const LotCardSkeleton()),
                    )
                  : filteredLots.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: EmptyState(
                                icon: Icons.inventory_2_outlined,
                                title: _selectedFilter == 'All'
                                    ? 'No Lots Yet'
                                    : 'No $_selectedFilter Lots',
                                message: _selectedFilter == 'All'
                                    ? 'No lots yet. Tap + to add your first scrap.'
                                    : 'There are no scrap lots matching "$_selectedFilter".',
                                buttonText: _selectedFilter == 'All' ? 'Add Scrap' : null,
                                onAction: _selectedFilter == 'All'
                                    ? () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => const CreateLotScreen(),
                                          ),
                                        );
                                      }
                                    : null,
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: filteredLots.length,
                          itemBuilder: (context, index) {
                            final lot = filteredLots[index];
                            return LotCard(
                              lot: lot,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => LotDetailScreen(lotId: lot.id),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateLotScreen()),
          );
        },
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        tooltip: 'Add Scrap Lot',
        child: const Icon(Icons.add),
      ),
    );
  }
}
