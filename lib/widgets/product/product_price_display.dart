import 'package:flutter/material.dart';

class ProductPriceDisplay extends StatelessWidget {
  final double price;
  final double? discountedPrice;
  final int? discountPercentage;
  final TextStyle? regularPriceStyle;
  final TextStyle? discountedPriceStyle;
  final TextStyle? discountLabelStyle;
  final bool showDiscountLabel;
  
  const ProductPriceDisplay({
    Key? key,
    required this.price,
    this.discountedPrice,
    this.discountPercentage,
    this.regularPriceStyle,
    this.discountedPriceStyle,
    this.discountLabelStyle,
    this.showDiscountLabel = true,
  }) : super(key: key);

  bool get hasDiscount => 
      discountedPrice != null && 
      discountedPrice! < price && 
      discountPercentage != null;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (hasDiscount) ...[
          Text(
            '\$${price.toStringAsFixed(2)}',
            style: regularPriceStyle ?? 
                Theme.of(context).textTheme.titleLarge?.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                  fontSize: 16,
                ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          '\$${(discountedPrice ?? price).toStringAsFixed(2)}',
          style: discountedPriceStyle ??
              Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
        ),
        if (hasDiscount && showDiscountLabel) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${discountPercentage}% OFF',
              style: discountLabelStyle ?? 
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ],
    );
  }
} 