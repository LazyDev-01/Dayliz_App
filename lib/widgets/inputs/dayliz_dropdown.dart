import 'package:flutter/material.dart';
import 'package:dayliz_app/theme/app_theme.dart';

class DaylizDropdownItem<T> {
  final String label;
  final T value;
  final IconData? icon;

  DaylizDropdownItem({
    required this.label,
    required this.value,
    this.icon,
  });
}

class DaylizDropdown<T> extends StatelessWidget {
  final String? label;
  final String hint;
  final T? value;
  final List<DaylizDropdownItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? errorText;
  final bool isExpanded;
  final EdgeInsetsGeometry? contentPadding;
  final IconData? prefixIcon;

  const DaylizDropdown({
    Key? key,
    this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.errorText,
    this.isExpanded = true,
    this.contentPadding,
    this.prefixIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Using theme colors to match the text field styling
    final fillColor = isDark 
        ? theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surfaceVariant
        : theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surface;
    
    final borderColor = theme.inputDecorationTheme.border?.borderSide.color 
        ?? theme.colorScheme.outline.withOpacity(0.5);
    
    final focusedBorderColor = theme.inputDecorationTheme.focusedBorder?.borderSide.color 
        ?? theme.colorScheme.primary;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              label!,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onBackground,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        DropdownButtonFormField<T>(
          value: value,
          icon: const Icon(Icons.arrow_drop_down),
          iconSize: 24,
          elevation: 2,
          isExpanded: isExpanded,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            contentPadding: contentPadding ?? const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            filled: true,
            fillColor: fillColor,
            hintText: hint,
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
            errorText: errorText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: borderColor, width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: borderColor, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: focusedBorderColor, width: 2.0),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: theme.colorScheme.error, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: theme.colorScheme.error, width: 2.0),
            ),
          ),
          items: items.map<DropdownMenuItem<T>>((DaylizDropdownItem<T> item) {
            return DropdownMenuItem<T>(
              value: item.value,
              child: Row(
                children: [
                  if (item.icon != null) ...[
                    Icon(
                      item.icon,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    item.label,
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
} 