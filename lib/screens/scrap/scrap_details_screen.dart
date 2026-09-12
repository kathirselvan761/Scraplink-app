import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../models/collection.dart';
import '../../repositories/collection_repository.dart';
import '../../widgets/app_status_chip.dart';
import '../../widgets/error_state_view.dart';
import '../handover/handover_screen.dart';
import '../tracking/scrap_tracking_screen.dart';

/// Screen displaying comprehensive details for a single Scrap lot owned by the collector
class ScrapDetailsScreen extends StatefulWidget {
  final String lotId;

  const ScrapDetailsScreen({super.key, required this.lotId});

  @override
  State<ScrapDetailsScreen> createState() => _ScrapDetailsScreenState();
}

class _ScrapDetailsScreenState extends State<ScrapDetailsScreen> {
  final CollectionRepository _repo = CollectionRepository();

  bool _isLoading = true;
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
      final details = await _repo.getCollectionDetails(widget.lotId);
      if (mounted) {
        setState(() {
          _collection = details;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Text(
          widget.lotId,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF94A3B8)),
            onPressed: _fetchDetails,
            tooltip: 'Refresh',
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
        onRetry: _fetchDetails,
      );
    }

    if (_collection == null) {
      return const Center(
        child: Text('Scrap not found', style: TextStyle(color: Colors.white)),
      );
    }

    final col = _collection!;
    final scrap = col.scrap;

    return RefreshIndicator(
      onRefresh: _fetchDetails,
      color: const Color(0xFF10B981),
      backgroundColor: const Color(0xFF1E293B),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Scrap Lot ID', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                        Text(
                          scrap.lotId,
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
                if (scrap.id != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'MySQL Record ID: #${scrap.id}',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Photo preview if available
          if (scrap.imageUrl != null && scrap.imageUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                '${AppConfig.current.baseUrl.replaceAll('/api', '')}${scrap.imageUrl}',
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Scrap Specifications
          _buildCard(
            title: 'Material Specifications',
            icon: Icons.recycling_outlined,
            child: Column(
              children: [
                _buildRow('Material Category', scrap.material),
                _buildRow('Estimated Weight', '${scrap.weight.toStringAsFixed(2)} kg'),
                if (scrap.finalWeight != null)
                  _buildRow('Verified Final Weight', '${scrap.finalWeight!.toStringAsFixed(2)} kg'),
                _buildRow(
                  'Estimated Value',
                  '₹${scrap.estimatedPrice.toStringAsFixed(2)}',
                  valueColor: const Color(0xFF10B981),
                ),
                if (scrap.confidence > 0)
                  _buildRow(
                    'AI Verification Confidence',
                    '${(scrap.confidence * 100).toStringAsFixed(1)}%',
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Recycler Information
          _buildCard(
            title: 'Recycler Hub Assignment',
            icon: Icons.business_outlined,
            child: Column(
              children: [
                _buildRow(
                  'Recycler Hub',
                  col.recyclerName?.isNotEmpty == true
                      ? col.recyclerName!
                      : 'Awaiting Recycler Request',
                ),
                if (col.recyclerPhone != null)
                  _buildRow('Recycler Phone', col.recyclerPhone!),
                if (col.recyclerAddress != null)
                  _buildRow('Facility Address', col.recyclerAddress!),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Notes
          if (scrap.notes != null && scrap.notes!.isNotEmpty) ...[
            _buildCard(
              title: 'Collection Notes',
              icon: Icons.note_alt_outlined,
              child: Text(
                scrap.notes!,
                style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Action Buttons: Track Scrap & Handover
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ScrapTrackingScreen(lotId: scrap.lotId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.timeline, size: 18),
                  label: const Text('Track Scrap'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF475569)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HandoverScreen(lotId: scrap.lotId, initialWeight: scrap.weight),
                      ),
                    ).then((_) => _fetchDetails());
                  },
                  icon: const Icon(Icons.qr_code_scanner, size: 18),
                  label: const Text('Handover'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
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
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
