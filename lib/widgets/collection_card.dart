import 'package:flutter/material.dart';
import '../models/collection.dart';
import 'app_status_chip.dart';

/// Reusable collection list card displaying Scrap ID, Customer, Address,
/// Scheduled Date, Material category, and Status badge.
class CollectionCard extends StatelessWidget {
  final Collection collection;
  final VoidCallback onTap;

  const CollectionCard({
    super.key,
    required this.collection,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sched = collection.scheduledDateTime;
    final dateStr = sched != null
        ? '${sched.day.toString().padLeft(2, '0')}/${sched.month.toString().padLeft(2, '0')}/${sched.year} ${sched.hour.toString().padLeft(2, '0')}:${sched.minute.toString().padLeft(2, '0')}'
        : 'Date pending';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF334155)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Scrap ID + Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.recycling_rounded,
                          color: Color(0xFF10B981),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        collection.lotId,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  AppStatusChip(status: collection.status),
                ],
              ),
              const Divider(color: Color(0xFF334155), height: 20),

              // Customer / Source Name
              _buildRow(
                icon: Icons.person_outline,
                label: 'Customer / Source',
                value: collection.displayCustomerName,
              ),
              const SizedBox(height: 8),

              // Scrap Category / Material & Weight
              Row(
                children: [
                  Expanded(
                    child: _buildRow(
                      icon: Icons.category_outlined,
                      label: 'Scrap Category',
                      value: collection.material,
                    ),
                  ),
                  Expanded(
                    child: _buildRow(
                      icon: Icons.scale_outlined,
                      label: 'Est. Weight',
                      value: '${collection.weight.toStringAsFixed(1)} kg',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Pickup Address
              _buildRow(
                icon: Icons.location_on_outlined,
                label: 'Pickup Address',
                value: collection.pickupAddress,
              ),
              const SizedBox(height: 8),

              // Scheduled Pickup Date/Time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Scheduled Pickup',
                      value: dateStr,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Icon(icon, color: const Color(0xFF94A3B8), size: 15),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
