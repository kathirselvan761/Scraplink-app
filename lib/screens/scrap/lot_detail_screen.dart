import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_theme.dart';
import '../../models/scrap_lot_model.dart';
import '../../providers/lot_provider.dart';
import '../../widgets/status_badge.dart';
import '../qr/qr_display_screen.dart';

class LotDetailScreen extends StatefulWidget {
  final dynamic lotId;
  final ScrapLotModel? lot;

  const LotDetailScreen({super.key, required this.lotId, this.lot});

  @override
  State<LotDetailScreen> createState() => _LotDetailScreenState();
}

class _LotDetailScreenState extends State<LotDetailScreen> {
  ScrapLotModel? _lot;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _lot = widget.lot;
    if (_lot != null) {
      _isLoading = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLotDetail();
    });
  }

  Future<void> _fetchLotDetail() async {
    final lotProvider = context.read<LotProvider>();
    
    // Check in cache if not yet set
    final cached = lotProvider.myLots.cast<ScrapLotModel?>().firstWhere(
      (l) => l?.id.toString() == widget.lotId.toString(),
      orElse: () => null,
    );
    if (cached != null && _lot == null) {
      setState(() {
        _lot = cached;
        _isLoading = false;
      });
    }

    final result = await lotProvider.loadLotDetail(widget.lotId);

    if (!mounted) return;

    if (result != null) {
      setState(() {
        _lot = result;
        _isLoading = false;
      });
    } else if (_lot == null) {
      setState(() {
        _errorMessage = lotProvider.errorMessage ?? 'Unable to load lot details.';
        _isLoading = false;
      });
    }
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFF0F0F0)),
          child,
        ],
      ),
    );
  }

  Widget _buildTimeline(ScrapLotModel lot) {
    final history = lot.statusHistory;

    if (history.isEmpty) {
      // Default generated status history from current status
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'No history logged yet. Updates will appear as recyclers process this lot.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    }

    return Column(
      children: List.generate(history.length, (index) {
        final item = history[index];
        final isLast = index == history.length - 1;
        final isCompleted = item.status.toUpperCase() != 'PENDING';
        final timeStr = item.timestamp != null
            ? DateFormat('MMM d, yyyy • h:mm a').format(item.timestamp!)
            : 'Logged';

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline line + dot
            Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isCompleted ? AppTheme.primaryGreen : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryGreen,
                      width: 2.5,
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 48,
                    color: Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.status.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          timeStr,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    if (item.actor != null && item.actor!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'By: ${item.actor}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                    if (item.notes != null && item.notes!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.notes!,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Lot #${widget.lotId}')),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
          ),
        ),
      );
    }

    if (_lot == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lot Detail')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 56, color: AppTheme.errorRed),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Lot not found',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _fetchLotDetail,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                  child: const Text('Retry', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final lot = _lot!;
    final statusUpper = lot.status.toUpperCase();
    final canShowQr = statusUpper == 'ACCEPTED' || statusUpper == 'COLLECTED';
    final dateStr = lot.createdAt != null
        ? DateFormat('MMMM d, yyyy • h:mm a').format(lot.createdAt!)
        : 'Unknown Date';

    return Scaffold(
      appBar: AppBar(
        title: Text('Lot #${lot.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchLotDetail,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLotDetail,
        color: AppTheme.primaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lot ID: ${lot.id}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        StatusBadge(status: lot.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lot.material,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Created: $dateStr',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),

              // 2. Photo Section
              if (lot.imageUrl != null && lot.imageUrl!.isNotEmpty) ...[
                _buildSectionCard(
                  title: 'Scrap Photo',
                  icon: Icons.photo_outlined,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: lot.imageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 200,
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Image unavailable', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              // 3. Weight Card
              _buildSectionCard(
                title: 'Weight Verification',
                icon: Icons.scale_outlined,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estimated Weight',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${lot.estimatedWeight} kg',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 40, width: 1, color: Colors.grey.shade200),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Final Weight',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lot.finalWeight != null ? '${lot.finalWeight} kg' : 'Pending',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: lot.finalWeight != null
                                    ? AppTheme.primaryGreen
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Location Card
              if (lot.latitude != null && lot.longitude != null) ...[
                _buildSectionCard(
                  title: 'Collection Coordinates',
                  icon: Icons.location_on_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lat: ${lot.latitude!.toStringAsFixed(5)}, Lng: ${lot.longitude!.toStringAsFixed(5)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          final query = '${lot.latitude},${lot.longitude}';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Coordinates: $query'),
                              action: SnackBarAction(
                                label: 'OK',
                                onPressed: () {},
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.map_outlined, size: 18),
                        label: const Text('Open in Maps'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryGreen,
                          side: const BorderSide(color: AppTheme.primaryGreen),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 5. Recycler Card (if assigned)
              if (lot.recyclerName != null && lot.recyclerName!.isNotEmpty) ...[
                _buildSectionCard(
                  title: 'Assigned Recycler',
                  icon: Icons.business_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lot.recyclerName!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (lot.recyclerId != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Partner ID: #${lot.recyclerId}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // 6. Notes Card (if present)
              if (lot.notes != null && lot.notes!.isNotEmpty) ...[
                _buildSectionCard(
                  title: 'Collector Notes',
                  icon: Icons.notes_outlined,
                  child: Text(
                    lot.notes!,
                    style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                  ),
                ),
              ],

              // 7. Journey Timeline
              _buildSectionCard(
                title: 'Journey Timeline',
                icon: Icons.timeline,
                child: _buildTimeline(lot),
              ),

              const SizedBox(height: 80), // Padding for sticky bottom button
            ],
          ),
        ),
      ),

      // 8. Bottom Action
      bottomNavigationBar: canShowQr
          ? Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  final qrToken = lot.qrToken ?? 'SCRAPLINK:LOT:${lot.id}';
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QrDisplayScreen(
                        qrData: qrToken,
                        lotId: lot.id,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code, size: 22),
                label: const Text(
                  'Show Handover QR',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
