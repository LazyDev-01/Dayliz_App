import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/agent_availability_provider.dart';

/// Widget to display and manage agent availability status
class AvailabilityStatusCard extends ConsumerWidget {
  const AvailabilityStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availabilityState = ref.watch(agentAvailabilityProvider);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: _getStatusGradient(availabilityState.status),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor(availabilityState.status).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agent Status',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStatusDisplayText(availabilityState.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${availabilityState.currentOrdersCount}/${availabilityState.maxOrdersCapacity}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatusButton(
                  context,
                  ref,
                  'Go Online',
                  'available',
                  Icons.play_circle_filled,
                  availabilityState.status == 'available',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusButton(
                  context,
                  ref,
                  'Break',
                  'on_break',
                  Icons.pause_circle_filled,
                  availabilityState.status == 'on_break',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusButton(
                  context,
                  ref,
                  'Offline',
                  'offline',
                  Icons.stop_circle,
                  availabilityState.status == 'offline',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(
    BuildContext context,
    WidgetRef ref,
    String label,
    String status,
    IconData icon,
    bool isActive,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _updateStatus(ref, status),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isActive ? _getStatusColor(status) : Colors.white,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? _getStatusColor(status) : Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateStatus(WidgetRef ref, String status) {
    final notifier = ref.read(agentAvailabilityProvider.notifier);

    switch (status) {
      case 'available':
        notifier.goOnline();
        break;
      case 'on_break':
        notifier.setOnBreak();
        break;
      case 'offline':
        notifier.goOffline();
        break;
    }
  }

  LinearGradient _getStatusGradient(String status) {
    switch (status) {
      case 'available':
        return const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'busy':
        return const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFE65100)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'on_break':
        return const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'offline':
      default:
        return const LinearGradient(
          colors: [Color(0xFF757575), Color(0xFF424242)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return const Color(0xFF4CAF50);
      case 'busy':
        return const Color(0xFFFF9800);
      case 'on_break':
        return const Color(0xFF2196F3);
      case 'offline':
      default:
        return const Color(0xFF757575);
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status) {
      case 'available':
        return 'Available';
      case 'busy':
        return 'Busy';
      case 'on_break':
        return 'On Break';
      case 'offline':
      default:
        return 'Offline';
    }
  }
}
