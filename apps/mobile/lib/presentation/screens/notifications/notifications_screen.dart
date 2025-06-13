import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/notification.dart';
import '../../providers/notification_providers.dart';
import '../../widgets/common/unified_app_bar.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/empty_state.dart';

/// Notifications screen showing user's notifications
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Load more notifications when near bottom
      ref.read(notificationStateProvider.notifier).loadMoreNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationStateProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: UnifiedAppBars.withBackButton(
        title: 'Notifications',
        fallbackRoute: '/home',
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF374151)),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_read, size: 20),
                    SizedBox(width: 8),
                    Text('Mark all as read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, size: 20),
                    SizedBox(width: 8),
                    Text('Clear all'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 8),
                    Text('Notification settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(notificationStateProvider.notifier).loadNotifications(refresh: true),
        child: Column(
          children: [
            _buildFilterTabs(),
            Expanded(
              child: _buildNotificationsList(notificationState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('all', 'All'),
          const SizedBox(width: 8),
          _buildFilterChip('unread', 'Unread'),
          const SizedBox(width: 8),
          _buildFilterChip('orders', 'Orders'),
          const SizedBox(width: 8),
          _buildFilterChip('promotions', 'Promotions'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
        _applyFilter(value);
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  void _applyFilter(String filter) {
    switch (filter) {
      case 'unread':
        ref.read(notificationStateProvider.notifier).loadNotifications(
          refresh: true,
          isRead: false,
        );
        break;
      case 'orders':
        ref.read(notificationStateProvider.notifier).loadNotifications(
          refresh: true,
          type: NotificationEntity.typeOrderPlaced,
        );
        break;
      case 'promotions':
        ref.read(notificationStateProvider.notifier).loadNotifications(
          refresh: true,
          type: NotificationEntity.typePromotion,
        );
        break;
      default:
        ref.read(notificationStateProvider.notifier).loadNotifications(refresh: true);
    }
  }

  Widget _buildNotificationsList(NotificationState state) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(child: LoadingIndicator(message: 'Loading notifications...'));
    }

    if (state.errorMessage != null && state.notifications.isEmpty) {
      return ErrorState(
        message: state.errorMessage!,
        onRetry: () => ref.read(notificationStateProvider.notifier).loadNotifications(refresh: true),
      );
    }

    if (state.notifications.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_none,
        title: 'No notifications',
        message: 'You\'ll see your notifications here when you receive them.',
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: state.notifications.length + (state.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.notifications.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final notification = state.notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(NotificationEntity notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: notification.isRead ? 1 : 2,
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationIcon(notification),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatNotificationTime(notification.createdAt),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, size: 16, color: Colors.grey[500]),
                          onSelected: (action) => _handleNotificationAction(action, notification),
                          itemBuilder: (context) => [
                            if (!notification.isRead)
                              const PopupMenuItem(
                                value: 'mark_read',
                                child: Text('Mark as read'),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildNotificationIcon(NotificationEntity notification) {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case NotificationEntity.typeOrderDelivered:
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case NotificationEntity.typeOrderOutForDelivery:
        iconData = Icons.delivery_dining;
        iconColor = Colors.blue;
        break;
      case NotificationEntity.typeOrderPlaced:
      case NotificationEntity.typeOrderConfirmed:
        iconData = Icons.receipt;
        iconColor = Colors.orange;
        break;
      case NotificationEntity.typePromotion:
        iconData = Icons.local_offer;
        iconColor = Colors.purple;
        break;
      case NotificationEntity.typePaymentSuccess:
        iconData = Icons.payment;
        iconColor = Colors.green;
        break;
      case NotificationEntity.typePaymentFailed:
        iconData = Icons.error;
        iconColor = Colors.red;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  String _formatNotificationTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  void _handleNotificationTap(NotificationEntity notification) {
    // Mark as read if not already read
    if (!notification.isRead) {
      ref.read(notificationStateProvider.notifier).markAsRead(notification.id);
    }

    // Handle navigation based on notification type
    if (notification.actionUrl != null) {
      context.go(notification.actionUrl!);
    } else if (notification.isOrderNotification && notification.data?['orderId'] != null) {
      context.go('/orders/${notification.data!['orderId']}');
    }
  }

  void _handleNotificationAction(String action, NotificationEntity notification) {
    switch (action) {
      case 'mark_read':
        ref.read(notificationStateProvider.notifier).markAsRead(notification.id);
        break;
      case 'delete':
        ref.read(notificationStateProvider.notifier).deleteNotification(notification.id);
        break;
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'mark_all_read':
        ref.read(notificationStateProvider.notifier).markAllAsRead();
        break;
      case 'clear_all':
        _showClearAllDialog();
        break;
      case 'settings':
        context.go('/notifications/settings');
        break;
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all notifications'),
        content: const Text('Are you sure you want to clear all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(notificationStateProvider.notifier).clearAllNotifications();
            },
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
  }
}
