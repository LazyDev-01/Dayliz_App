import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../providers/viewing_mode_provider.dart';

/// Bottom sheet that appears when user is in viewing mode (city but no delivery)
class DeliveryRestrictionBottomSheet extends ConsumerWidget {
  final String? customMessage;
  final VoidCallback? onDismiss;

  const DeliveryRestrictionBottomSheet({
    super.key,
    this.customMessage,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewingModeState = ref.watch(viewingModeProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                Icons.location_on_outlined,
                size: 32,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Limited Service Area',
              style: AppTextStyles.headline3.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Message
            Text(
              customMessage ?? viewingModeState.restrictionMessage ?? 
              'We don\'t deliver to this area yet, but you can still browse our products.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                // Try Different Location button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go('/location-selection');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Try Different Location',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Just Viewing button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Dismiss the bottom sheet and remember choice
                      ref.read(viewingModeProvider.notifier).dismissRestrictionNotification();
                      Navigator.of(context).pop();
                      onDismiss?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Just Viewing',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Safe area padding for bottom
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  /// Show the delivery restriction bottom sheet
  static Future<void> show(
    BuildContext context, {
    String? customMessage,
    VoidCallback? onDismiss,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DeliveryRestrictionBottomSheet(
        customMessage: customMessage,
        onDismiss: onDismiss,
      ),
    );
  }
}

/// Helper widget to automatically show delivery restriction when needed
class AutoDeliveryRestrictionHandler extends ConsumerWidget {
  final Widget child;

  const AutoDeliveryRestrictionHandler({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewingModeState = ref.watch(viewingModeProvider);

    // Show bottom sheet when viewing mode is active and notification should be shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (viewingModeState.showRestrictionNotification && 
          viewingModeState.isViewingMode) {
        DeliveryRestrictionBottomSheet.show(context);
      }
    });

    return child;
  }
}

/// Viewing mode indicator widget for app bars or other UI elements
class ViewingModeIndicator extends ConsumerWidget {
  final bool compact;

  const ViewingModeIndicator({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewingModeState = ref.watch(viewingModeProvider);

    if (!viewingModeState.isViewingMode) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.visibility_outlined,
              size: 14,
              color: AppColors.accent,
            ),
            const SizedBox(width: 4),
            Text(
              'Viewing Only',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.visibility_outlined,
            size: 16,
            color: AppColors.accent,
          ),
          const SizedBox(width: 8),
          Text(
            'Viewing Mode - No Delivery Available',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
