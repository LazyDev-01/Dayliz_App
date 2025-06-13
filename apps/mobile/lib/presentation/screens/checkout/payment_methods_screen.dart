import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/payment_method.dart';
import '../../providers/auth_providers.dart';
import '../../providers/payment_method_providers.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/unified_app_bar.dart';
import '../../widgets/payment/payment_method_card.dart';
import '../../widgets/payment/add_payment_method_dialog.dart';

class PaymentMethodsScreen extends ConsumerWidget {
  final bool isCheckout;

  const PaymentMethodsScreen({
    Key? key,
    this.isCheckout = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the current user from auth state
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isAuthenticated = authState.isAuthenticated;

    if (!isAuthenticated) {
      return _buildNotLoggedInState(context);
    }

    return _buildContent(context, ref, user?.id ?? '');
  }

  Widget _buildNotLoggedInState(BuildContext context) {
    return Scaffold(
      appBar: UnifiedAppBars.withBackButton(
        title: 'Payment Methods',
        fallbackRoute: '/home',
      ),
      body: EmptyState(
        icon: Icons.login,
        title: 'Not Logged In',
        message: 'Please log in to manage your payment methods',
        buttonText: 'Log In',
        onButtonPressed: () => context.go('/login'),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, String userId) {
    final paymentMethodState = ref.watch(paymentMethodNotifierProvider(userId));

    return Scaffold(
      appBar: UnifiedAppBars.withBackButton(
        title: 'Payment Methods',
        fallbackRoute: '/checkout',
        actions: [
          if (isCheckout && paymentMethodState.selectedMethod != null)
            TextButton(
              onPressed: () {
                if (isCheckout) {
                  context.pop(paymentMethodState.selectedMethod);
                }
              },
              child: const Text('Done', style: TextStyle(color: Color(0xFF374151))),
            ),
        ],
      ),
      body: _buildBody(context, ref, userId, paymentMethodState),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPaymentMethodDialog(context, ref, userId),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    String userId,
    PaymentMethodState state,
  ) {
    // Show loading state
    if (state.isLoading) {
      return const Center(child: LoadingIndicator());
    }

    // Show error state
    if (state.errorMessage != null) {
      return ErrorState(
        message: state.errorMessage!,
        onRetry: () => ref.read(paymentMethodNotifierProvider(userId).notifier).loadPaymentMethods(),
      );
    }

    // Show empty state
    if (state.methods.isEmpty) {
      return EmptyState(
        icon: Icons.payment,
        title: 'No Payment Methods',
        message: 'You haven\'t added any payment methods yet',
        buttonText: 'Add Payment Method',
        onButtonPressed: () => _showAddPaymentMethodDialog(context, ref, userId),
      );
    }

    // Show payment methods
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.methods.length,
      itemBuilder: (context, index) {
        final paymentMethod = state.methods[index];
        final isSelected = state.selectedMethod?.id == paymentMethod.id;

        return PaymentMethodCard(
          paymentMethod: paymentMethod,
          isSelected: isSelected,
          onTap: () => ref.read(paymentMethodNotifierProvider(userId).notifier)
              .selectPaymentMethod(paymentMethod.id),
          onDelete: paymentMethod.isDefault
              ? null // Prevent deleting default payment method
              : () => _showDeleteConfirmationDialog(context, ref, userId, paymentMethod),
          onSetDefault: paymentMethod.isDefault
              ? null
              : () => ref.read(paymentMethodNotifierProvider(userId).notifier)
                  .setDefaultPaymentMethod(paymentMethod.id),
        );
      },
    );
  }

  void _showAddPaymentMethodDialog(BuildContext context, WidgetRef ref, String userId) {
    showDialog(
      context: context,
      builder: (context) => AddPaymentMethodDialog(
        onAddPaymentMethod: (paymentMethod) {
          // Add actual user ID to the payment method
          final updatedMethod = paymentMethod.copyWith(userId: userId);

          // Add the payment method to the list
          ref.read(paymentMethodNotifierProvider(userId).notifier)
              .addPaymentMethod(updatedMethod);
        },
      ),
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
    PaymentMethod paymentMethod,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Method'),
        content: Text(
          'Are you sure you want to delete ${paymentMethod.nickName ?? paymentMethod.displayName}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(paymentMethodNotifierProvider(userId).notifier)
                  .deletePaymentMethod(paymentMethod.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}