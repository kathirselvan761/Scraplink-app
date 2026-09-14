import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/scrap_lot_model.dart';
import '../screens/scrap/lot_detail_screen.dart';
import 'status_badge.dart';

class LotCard extends StatelessWidget {
  final ScrapLotModel lot;
  final VoidCallback? onTap;

  const LotCard({
    super.key,
    required this.lot,
    this.onTap,
  });

  IconData _getMaterialIcon(String material) {
    final m = material.toLowerCase();
    if (m.contains('copper') || m.contains('aluminum') || m.contains('steel') || m.contains('metal') || m.contains('iron')) {
      return Icons.hardware;
    } else if (m.contains('plastic')) {
      return Icons.local_drink;
    } else if (m.contains('paper') || m.contains('cardboard')) {
      return Icons.inventory_2_outlined;
    } else if (m.contains('electronic') || m.contains('e-waste')) {
      return Icons.devices;
    } else if (m.contains('glass')) {
      return Icons.wine_bar;
    }
    return Icons.recycling_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = lot.createdAt != null
        ? DateFormat('MMM d, yyyy • h:mm a').format(lot.createdAt!)
        : 'Recently added';

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap ??
            () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LotDetailScreen(lotId: lot.id),
                ),
              );
            },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              // Material Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0x1A2E7D32),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getMaterialIcon(lot.material),
                  color: const Color(0xFF2E7D32),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            lot.material.isEmpty ? 'Scrap Lot' : lot.material,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatusBadge(status: lot.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${lot.estimatedWeight} kg',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•  ID: ${lot.id}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
