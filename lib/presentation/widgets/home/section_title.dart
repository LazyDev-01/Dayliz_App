import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAllPressed;
  final TextStyle? titleStyle;
  
  const SectionTitle({
    Key? key,
    required this.title,
    this.onSeeAllPressed,
    this.titleStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: titleStyle ?? 
              const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
        ),
        if (onSeeAllPressed != null)
          TextButton(
            onPressed: onSeeAllPressed,
            child: const Text('See All'),
          ),
      ],
    );
  }
} 