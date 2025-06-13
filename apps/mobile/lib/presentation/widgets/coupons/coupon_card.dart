import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/coupon.dart';

/// Widget for displaying a coupon card
class CouponCard extends StatelessWidget {
  final Coupon coupon;
  final bool isAvailable;
  final VoidCallback? onTap;
  final VoidCallback? onCollect;
  final VoidCallback? onApply;

  const CouponCard({
    super.key,
    required this.coupon,
    required this.isAvailable,
    this.onTap,
    this.onCollect,
    this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: _getGradient(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildDescription(),
              const SizedBox(height: 12),
              _buildDetails(),
              const SizedBox(height: 16),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getDiscountColor(),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            coupon.discountDisplayText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const Spacer(),
        _buildStatusChip(),
      ],
    );
  }

  Widget _buildStatusChip() {
    Color chipColor;
    String statusText;
    
    if (!coupon.isValid) {
      if (coupon.isExpired) {
        chipColor = Colors.red[100]!;
        statusText = 'Expired';
      } else if (coupon.isNotStarted) {
        chipColor = Colors.orange[100]!;
        statusText = 'Coming Soon';
      } else {
        chipColor = Colors.grey[200]!;
        statusText = 'Inactive';
      }
    } else if (coupon.isExpiringSoon) {
      chipColor = Colors.orange[100]!;
      statusText = 'Expires Soon';
    } else {
      chipColor = Colors.green[100]!;
      statusText = 'Active';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _getStatusTextColor(chipColor),
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          coupon.code,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        if (coupon.description != null) ...[
          const SizedBox(height: 4),
          Text(
            coupon.description!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetails() {
    return Column(
      children: [
        if (coupon.minimumOrderText != null)
          _buildDetailRow(Icons.shopping_cart, coupon.minimumOrderText!),
        if (coupon.maximumDiscountText != null) ...[
          const SizedBox(height: 4),
          _buildDetailRow(Icons.money_off, coupon.maximumDiscountText!),
        ],
        const SizedBox(height: 4),
        _buildDetailRow(Icons.schedule, coupon.validityStatusText),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        // Copy code button
        InkWell(
          onTap: () => _copyCode(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.copy,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Copy Code',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        // Action button
        if (isAvailable && onCollect != null)
          _buildActionButton(
            'Collect',
            AppColors.primary,
            onCollect!,
            enabled: coupon.isValid,
          )
        else if (!isAvailable && onApply != null)
          _buildActionButton(
            'Apply',
            AppColors.success,
            onApply!,
            enabled: coupon.isValid,
          ),
      ],
    );
  }

  Widget _buildActionButton(
    String text,
    Color color,
    VoidCallback onPressed, {
    bool enabled = true,
  }) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? color : Colors.grey[300],
        foregroundColor: enabled ? Colors.white : Colors.grey[600],
        elevation: enabled ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: coupon.code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Coupon code ${coupon.code} copied!'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.success,
      ),
    );
  }

  LinearGradient _getGradient() {
    if (!coupon.isValid) {
      return LinearGradient(
        colors: [Colors.grey[100]!, Colors.grey[50]!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    if (coupon.discountType == Coupon.discountTypePercentage) {
      return LinearGradient(
        colors: [Colors.blue[50]!, Colors.white],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      return LinearGradient(
        colors: [Colors.green[50]!, Colors.white],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  Color _getDiscountColor() {
    if (!coupon.isValid) {
      return Colors.grey[400]!;
    }

    if (coupon.discountType == Coupon.discountTypePercentage) {
      return Colors.blue[600]!;
    } else {
      return Colors.green[600]!;
    }
  }

  Color _getStatusTextColor(Color backgroundColor) {
    if (backgroundColor == Colors.red[100]) return Colors.red[800]!;
    if (backgroundColor == Colors.orange[100]) return Colors.orange[800]!;
    if (backgroundColor == Colors.green[100]) return Colors.green[800]!;
    return Colors.grey[800]!;
  }
}
