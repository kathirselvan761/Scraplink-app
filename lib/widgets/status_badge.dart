import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  Color _getStatusColor(String st) {
    switch (st.toUpperCase()) {
      case 'REQUESTED':
        return Colors.orange;
      case 'ACCEPTED':
        return Colors.blue;
      case 'COLLECTED':
        return Colors.purple;
      case 'HANDED_OVER':
        return Colors.teal;
      case 'RECEIVED':
        return Colors.cyan.shade700;
      case 'PROCESSING':
        return Colors.indigo;
      case 'RECYCLED':
        return Colors.green;
      case 'COMPLETED':
        return const Color(0xFF1B5E20); // Dark green
      case 'PENDING':
        return Colors.amber.shade800;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    final displayStatus = status.replaceAll('_', ' ').toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        displayStatus,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
