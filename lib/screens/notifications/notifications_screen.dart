import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/api_config.dart';
import '../../config/app_theme.dart';
import '../../models/notification_model.dart';
import '../../services/api_service.dart';
import '../../widgets/empty_state.dart';
import '../scrap/lot_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _api = ApiService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _api.get(ApiConfig.notifications);
      List<dynamic> rawList = [];
      if (response is List) {
        rawList = response;
      } else if (response is Map<String, dynamic>) {
        rawList = response['notifications'] ?? response['data'] ?? [];
      }

      setState(() {
        _notifications = rawList
            .whereType<Map<String, dynamic>>()
            .map((item) => NotificationModel.fromJson(item))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(NotificationModel notif, int index) async {
    if (notif.isRead) {
      _navigateToRelated(notif);
      return;
    }

    // Update locally first for instant UI response
    setState(() {
      _notifications[index] = notif.copyWith(isRead: true);
    });

    try {
      if (notif.id != null) {
        await _api.put(ApiConfig.markNotificationRead(notif.id!));
      }
    } catch (_) {
      // Background sync, suppress errors
    }

    _navigateToRelated(notif);
  }

  void _navigateToRelated(NotificationModel notif) {
    if (notif.relatedId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LotDetailScreen(lotId: notif.relatedId!),
        ),
      );
    }
  }

  Future<void> _markAllRead() async {
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    if (unreadCount == 0) return;

    setState(() {
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });

    try {
      await _api.put(ApiConfig.markAllNotificationsRead);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      // Suppress
    }
  }

  IconData _getTypeIcon(String? type) {
    final t = (type ?? '').toLowerCase();
    if (t.contains('payment') || t.contains('payout') || t.contains('money')) {
      return Icons.payments_outlined;
    } else if (t.contains('lot') || t.contains('scrap') || t.contains('collection')) {
      return Icons.inventory_2_outlined;
    } else if (t.contains('qr') || t.contains('scan')) {
      return Icons.qr_code;
    } else if (t.contains('recycler') || t.contains('partner')) {
      return Icons.business_outlined;
    }
    return Icons.notifications_none_outlined;
  }

  Color _getTypeColor(String? type) {
    final t = (type ?? '').toLowerCase();
    if (t.contains('payment') || t.contains('payout')) {
      return Colors.green;
    } else if (t.contains('lot') || t.contains('scrap')) {
      return Colors.blue;
    } else if (t.contains('qr')) {
      return Colors.purple;
    }
    return AppTheme.primaryGreen;
  }

  String _formatRelativeTime(DateTime? dt) {
    if (dt == null) return 'Just now';
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _notifications.any((n) => !n.isRead);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchNotifications,
        color: AppTheme.primaryGreen,
        child: _isLoading && _notifications.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                ),
              )
            : _errorMessage != null && _notifications.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
                              const SizedBox(height: 12),
                              Text(_errorMessage!, style: const TextStyle(color: Colors.black87)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchNotifications,
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                                child: const Text('Retry', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : _notifications.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: const EmptyState(
                          icon: Icons.notifications_off_outlined,
                          title: 'No Notifications Yet',
                          message: 'You\'re all caught up! Updates regarding lots, handovers, and payments will appear here.',
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 70, color: Color(0xFFEEEEEE)),
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      final icon = _getTypeIcon(notif.type);
                      final iconColor = _getTypeColor(notif.type);
                      final timeStr = _formatRelativeTime(notif.createdAt);

                      return InkWell(
                        onTap: () => _markAsRead(notif, index),
                        child: Container(
                          color: notif.isRead ? Colors.transparent : AppTheme.primaryGreen.withAlpha(10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Type Icon
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: iconColor.withAlpha(25),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: iconColor, size: 22),
                              ),
                              const SizedBox(width: 14),

                              // Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notif.title,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          timeStr,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notif.message,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: notif.isRead ? Colors.grey.shade600 : Colors.black87,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Unread indicator dot
                              if (!notif.isRead) ...[
                                const SizedBox(width: 10),
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(top: 6),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primaryGreen,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
