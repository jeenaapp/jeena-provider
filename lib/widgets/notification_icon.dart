import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../supabase/supabase_config.dart';

class NotificationIcon extends ConsumerStatefulWidget {
  const NotificationIcon({super.key});

  @override
  ConsumerState<NotificationIcon> createState() => _NotificationIconState();
}

class _NotificationIconState extends ConsumerState<NotificationIcon> {
  int _unreadCount = 0;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final user = AuthService.getCurrentUser();
      if (user != null) {
        final notifications = await SupabaseConfig.getUserNotifications(user.id);
        setState(() {
          _notifications = notifications;
          _unreadCount = notifications.where((n) => n['read'] == false).length;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () => _showNotifications(context),
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                '$_unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'الإشعارات',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_unreadCount > 0)
                  TextButton(
                    onPressed: _markAllAsRead,
                    child: const Text('تحديد الكل كمقروء'),
                  ),
              ],
            ),
            const Divider(),
            Expanded(
              child: _notifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return _buildNotificationItem(notification);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد إشعارات',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final isRead = notification['read'] == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isRead ? null : Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isRead ? Colors.grey[300]! : Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getNotificationColor(notification['type']),
          child: Icon(
            _getNotificationIcon(notification['type']),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          notification['title'] ?? 'إشعار',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification['message'] ?? '',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(notification['created_at']),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontSize: 10,
              ),
            ),
          ],
        ),
        onTap: () async {
          if (!isRead) {
            await _markAsRead(notification['id']);
          }
        },
      ),
    );
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'registration':
        return Colors.green;
      case 'approval':
        return Colors.blue;
      case 'rejection':
        return Colors.red;
      case 'order':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'registration':
        return Icons.app_registration;
      case 'approval':
        return Icons.check_circle;
      case 'rejection':
        return Icons.cancel;
      case 'order':
        return Icons.shopping_cart;
      default:
        return Icons.info;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inDays > 0) {
        return 'منذ ${diff.inDays} يوم';
      } else if (diff.inHours > 0) {
        return 'منذ ${diff.inHours} ساعة';
      } else if (diff.inMinutes > 0) {
        return 'منذ ${diff.inMinutes} دقيقة';
      } else {
        return 'الآن';
      }
    } catch (e) {
      return '';
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await SupabaseConfig.markNotificationAsRead(notificationId);
      await _loadNotifications(); // Refresh
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      for (final notification in _notifications) {
        if (notification['read'] == false) {
          await SupabaseConfig.markNotificationAsRead(notification['id']);
        }
      }
      await _loadNotifications(); // Refresh
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }
}