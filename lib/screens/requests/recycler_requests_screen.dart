import 'package:flutter/material.dart';
import '../../core/network/api_exception.dart';
import '../../models/recycler_request.dart';
import '../../services/offer_service.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_state_view.dart';
import '../handover/handover_screen.dart';

/// Screen displaying incoming Recycler Requests submitted from the Recycler Portal
/// for the collector's scrap lots (via `GET /api/offers`).
class RecyclerRequestsScreen extends StatefulWidget {
  const RecyclerRequestsScreen({super.key});

  @override
  State<RecyclerRequestsScreen> createState() => _RecyclerRequestsScreenState();
}

class _RecyclerRequestsScreenState extends State<RecyclerRequestsScreen> {
  final OfferService _offerService = OfferService();

  List<RecyclerRequest> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final offers = await _offerService.getOffers();

      if (mounted) {
        setState(() {
          _requests = offers;
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
          _errorMessage = 'Failed to fetch recycler requests: $e';
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
        title: const Text(
          'Recycler Requests',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF94A3B8)),
            onPressed: _fetchRequests,
            tooltip: 'Refresh Requests',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRequests,
        color: const Color(0xFF10B981),
        backgroundColor: const Color(0xFF1E293B),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      );
    }

    if (_errorMessage != null) {
      return ErrorStateView(
        message: _errorMessage!,
        onRetry: _fetchRequests,
      );
    }

    if (_requests.isEmpty) {
      return EmptyStateView(
        title: 'No Recycler Requests',
        message: 'No recyclers have submitted requests for your collected scraps yet.',
        icon: Icons.assignment_late_outlined,
        onAction: _fetchRequests,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final req = _requests[index];
        final dt = req.createdAt ?? DateTime.now();
        final dateStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

        final isPending = req.isPending;
        final isCompleted = req.isCompleted;

        Color badgeColor;
        Color badgeBg;
        if (isCompleted) {
          badgeColor = const Color(0xFF10B981);
          badgeBg = const Color(0xFF10B981).withValues(alpha: 0.15);
        } else if (isPending) {
          badgeColor = const Color(0xFFF59E0B);
          badgeBg = const Color(0xFFF59E0B).withValues(alpha: 0.15);
        } else {
          badgeColor = const Color(0xFF38BDF8);
          badgeBg = const Color(0xFF38BDF8).withValues(alpha: 0.15);
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          elevation: 0,
          color: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF334155)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Scrap ID + Request Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF38BDF8), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Scrap Lot ID', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                            Text(
                              req.lotId,
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: badgeColor),
                      ),
                      child: Text(
                        req.status.toUpperCase(),
                        style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF334155), height: 20),

                // Recycler Info
                Row(
                  children: [
                    const Icon(Icons.business_outlined, color: Color(0xFF10B981), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        req.recyclerName,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Specs Grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetric('Material', req.material),
                    _buildMetric('Weight', '${req.weight.toStringAsFixed(1)} kg'),
                    _buildMetric('Offer Rate', '₹${req.offeredRate.toStringAsFixed(0)}/kg'),
                    _buildMetric(
                      'Total Offer',
                      '₹${req.offerAmount.toStringAsFixed(0)}',
                      valueColor: const Color(0xFF10B981),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Request Date & Handover Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Requested: $dateStr',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                    if (!isCompleted)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => HandoverScreen(
                                lotId: req.lotId,
                                initialWeight: req.weight,
                              ),
                            ),
                          ).then((_) => _fetchRequests());
                        },
                        icon: const Icon(Icons.qr_code_scanner, size: 16),
                        label: const Text('Proceed to Handover'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetric(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
