import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/notification.dart';
import '../../providers/notification_providers.dart';
import '../../widgets/common/unified_app_bar.dart';
import '../../widgets/common/loading_indicator.dart';

/// Notification settings screen
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  TimeOfDay? _quietHoursStart;
  TimeOfDay? _quietHoursEnd;

  @override
  Widget build(BuildContext context) {
    final preferencesState = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: UnifiedAppBars.withBackButton(
        title: 'Notification Settings',
        fallbackRoute: '/notifications',
      ),
      body: preferencesState.isLoading
          ? const Center(child: LoadingIndicator(message: 'Loading settings...'))
          : _buildSettingsContent(preferencesState.preferences),
    );
  }

  Widget _buildSettingsContent(NotificationPreferences? preferences) {
    if (preferences == null) {
      return const Center(
        child: Text('Failed to load notification preferences'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Push Notifications'),
          _buildNotificationCard([
            _buildSwitchTile(
              title: 'Push Notifications',
              subtitle: 'Receive notifications on your device',
              value: preferences.pushNotificationsEnabled,
              onChanged: (value) => _updatePreferences(
                preferences.copyWith(pushNotificationsEnabled: value),
              ),
            ),
            _buildSwitchTile(
              title: 'Sound',
              subtitle: 'Play sound for notifications',
              value: preferences.soundEnabled,
              onChanged: preferences.pushNotificationsEnabled
                  ? (value) => _updatePreferences(
                        preferences.copyWith(soundEnabled: value),
                      )
                  : null,
            ),
            _buildSwitchTile(
              title: 'Vibration',
              subtitle: 'Vibrate for notifications',
              value: preferences.vibrationEnabled,
              onChanged: preferences.pushNotificationsEnabled
                  ? (value) => _updatePreferences(
                        preferences.copyWith(vibrationEnabled: value),
                      )
                  : null,
            ),
          ]),

          const SizedBox(height: 24),

          _buildSectionHeader('Notification Types'),
          _buildNotificationCard([
            _buildSwitchTile(
              title: 'Order Updates',
              subtitle: 'Order status, delivery updates',
              value: preferences.orderUpdatesEnabled,
              onChanged: (value) => _updatePreferences(
                preferences.copyWith(orderUpdatesEnabled: value),
              ),
            ),
            _buildSwitchTile(
              title: 'Promotional Offers',
              subtitle: 'Deals, discounts, and special offers',
              value: preferences.promotionalNotificationsEnabled,
              onChanged: (value) => _updatePreferences(
                preferences.copyWith(promotionalNotificationsEnabled: value),
              ),
            ),
            _buildSwitchTile(
              title: 'System Announcements',
              subtitle: 'App updates and important notices',
              value: preferences.systemAnnouncementsEnabled,
              onChanged: (value) => _updatePreferences(
                preferences.copyWith(systemAnnouncementsEnabled: value),
              ),
            ),
          ]),

          const SizedBox(height: 24),

          _buildSectionHeader('Email Notifications'),
          _buildNotificationCard([
            _buildSwitchTile(
              title: 'Email Notifications',
              subtitle: 'Receive notifications via email',
              value: preferences.emailNotificationsEnabled,
              onChanged: (value) => _updatePreferences(
                preferences.copyWith(emailNotificationsEnabled: value),
              ),
            ),
          ]),

          const SizedBox(height: 24),

          _buildSectionHeader('Quiet Hours'),
          _buildNotificationCard([
            _buildQuietHoursTile(
              title: 'Quiet Hours',
              subtitle: 'Mute notifications during these hours',
              startTime: preferences.quietHoursStart,
              endTime: preferences.quietHoursEnd,
              onChanged: (start, end) => _updatePreferences(
                preferences.copyWith(
                  quietHoursStart: start,
                  quietHoursEnd: end,
                ),
              ),
            ),
          ]),

          const SizedBox(height: 24),

          _buildSectionHeader('Advanced'),
          _buildNotificationCard([
            _buildActionTile(
              title: 'Test Notification',
              subtitle: 'Send a test notification',
              icon: Icons.send,
              onTap: _sendTestNotification,
            ),
            _buildActionTile(
              title: 'Clear Notification History',
              subtitle: 'Remove all notifications',
              icon: Icons.clear_all,
              onTap: _clearNotificationHistory,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildQuietHoursTile({
    required String title,
    required String subtitle,
    required String startTime,
    required String endTime,
    required Function(String start, String end) onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTimeButton(
                label: 'Start',
                time: startTime,
                onTap: () => _selectTime(
                  context,
                  startTime,
                  (time) => onChanged(time, endTime),
                ),
              ),
              const SizedBox(width: 16),
              const Text('to'),
              const SizedBox(width: 16),
              _buildTimeButton(
                label: 'End',
                time: endTime,
                onTap: () => _selectTime(
                  context,
                  endTime,
                  (time) => onChanged(startTime, time),
                ),
              ),
            ],
          ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildTimeButton({
    required String label,
    required String time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              time,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Future<void> _selectTime(
    BuildContext context,
    String currentTime,
    Function(String) onTimeSelected,
  ) async {
    final timeParts = currentTime.split(':');
    final currentTimeOfDay = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: currentTimeOfDay,
    );

    if (selectedTime != null) {
      final formattedTime = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      onTimeSelected(formattedTime);
    }
  }

  void _updatePreferences(NotificationPreferences preferences) {
    ref.read(notificationPreferencesProvider.notifier).updatePreferences(preferences);
  }

  void _sendTestNotification() {
    // TODO: Implement test notification
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification sent!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _clearNotificationHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Notification History'),
        content: const Text('Are you sure you want to clear all notification history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(notificationStateProvider.notifier).clearAllNotifications();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification history cleared'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
