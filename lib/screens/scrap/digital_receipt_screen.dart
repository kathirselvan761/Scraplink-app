import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../models/scrap.dart';
import '../../repositories/auth_repository.dart';
import '../main_scaffold_screen.dart';
import '../tracking/scrap_tracking_screen.dart';
import 'scrap_details_screen.dart';

/// Screen displaying the official Digital Receipt / Scrap Summary immediately after
/// successful submission with the canonical backend Scrap ID.
class DigitalReceiptScreen extends StatelessWidget {
  final Scrap scrap;
  final File? localImageFile;

  const DigitalReceiptScreen({
    super.key,
    required this.scrap,
    this.localImageFile,
  });

  @override
  Widget build(BuildContext context) {
    final collector = AuthRepository.instance.currentCollector;
    final createdDate = scrap.createdAt ?? DateTime.now();
    final dateStr =
        '${createdDate.day.toString().padLeft(2, '0')}/${createdDate.month.toString().padLeft(2, '0')}/${createdDate.year}';
    final timeStr =
        '${createdDate.hour.toString().padLeft(2, '0')}:${createdDate.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Digital Receipt',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MainScaffoldScreen(initialIndex: 1)),
                (route) => false,
              );
            },
            tooltip: 'Close to My Scraps',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Success Header Icon
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF10B981), width: 2),
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 48),
            ),
            const SizedBox(height: 14),
            const Text(
              'Scrap Successfully Registered!',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Official ScrapLink Transaction & Traceability Receipt',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(height: 24),

            // Receipt Container Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF334155)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Scrap ID Banner
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Canonical Scrap ID', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                          Text(
                            scrap.lotId,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF10B981)),
                        ),
                        child: Text(
                          scrap.status.displayName,
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFF334155), height: 24),

                  // Image Preview if available
                  if (localImageFile != null && localImageFile!.existsSync()) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        localImageFile!,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else if (scrap.imageUrl != null && scrap.imageUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        '${AppConfig.current.baseUrl.replaceAll('/api', '')}${scrap.imageUrl}',
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Receipt Key-Values
                  _buildReceiptRow('Collector Name', collector?.name ?? 'Authorized Collector'),
                  _buildReceiptRow('Collector ID', 'COL-${(collector?.id ?? scrap.collectorId).toString().padLeft(4, '0')}'),
                  _buildReceiptRow('Scrap Category', scrap.material),
                  _buildReceiptRow('Verified Weight', '${scrap.weight.toStringAsFixed(2)} kg'),
                  _buildReceiptRow(
                    'Estimated Value',
                    '₹${scrap.estimatedPrice.toStringAsFixed(2)}',
                    valueColor: const Color(0xFF10B981),
                    isBold: true,
                  ),
                  _buildReceiptRow('Registration Date', dateStr),
                  _buildReceiptRow('Registration Time', timeStr),
                  if (scrap.notes != null && scrap.notes!.isNotEmpty)
                    _buildReceiptRow('Notes', scrap.notes!),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ScrapDetailsScreen(lotId: scrap.lotId),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('View Scrap Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),

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
                    icon: const Icon(Icons.timeline_outlined, size: 18),
                    label: const Text('Track Scrap'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF475569)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const MainScaffoldScreen(initialIndex: 1),
                        ),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.inbox_outlined, size: 18),
                    label: const Text('My Scraps'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                      side: const BorderSide(color: Color(0xFF10B981)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
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
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                fontSize: isBold ? 15 : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
