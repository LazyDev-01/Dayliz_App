import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dayliz_app/theme/app_theme.dart';

class DaylizTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool enabled;
  final bool autofocus;
  final bool showClearButton;
  final Widget? prefix;
  final Widget? suffix;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconTap;
  final EdgeInsetsGeometry? contentPadding;
  final TextCapitalization textCapitalization;

  const DaylizTextField({
    Key? key,
    this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.validator,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.autofocus = false,
    this.showClearButton = false,
    this.prefix,
    this.suffix,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.contentPadding,
    this.textCapitalization = TextCapitalization.none,
  }) : super(key: key);

  @override
  State<DaylizTextField> createState() => _DaylizTextFieldState();
}

class _DaylizTextFieldState extends State<DaylizTextField> {
  late final TextEditingController _controller;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      // Only dispose the controller if we created it
      _controller.dispose();
    } else {
      _controller.removeListener(_handleTextChanged);
    }
    super.dispose();
  }

  void _handleTextChanged() {
    setState(() {
      // Update the UI when text changes (for the clear button)
    });
  }

  void _handleClearText() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daylizTheme = theme.extension<DaylizThemeExtension>();
    
    // Determine if we should show the password toggle
    final bool isPassword = widget.obscureText;
    
    // Determine if we should show the clear button
    final bool shouldShowClearButton = 
        widget.showClearButton && 
        _controller.text.isNotEmpty && 
        widget.enabled;
    
    // Create the suffix icon based on various conditions
    Widget? suffixIconWidget;
    if (isPassword) {
      suffixIconWidget = GestureDetector(
        onTap: _togglePasswordVisibility,
        child: Icon(
          _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      );
    } else if (shouldShowClearButton) {
      suffixIconWidget = GestureDetector(
        onTap: _handleClearText,
        child: Icon(
          Icons.clear,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      );
    } else if (widget.suffixIcon != null) {
      suffixIconWidget = GestureDetector(
        onTap: widget.onSuffixIconTap,
        child: Icon(
          widget.suffixIcon,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      );
    } else if (widget.suffix != null) {
      suffixIconWidget = widget.suffix;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: widget.enabled 
                  ? theme.colorScheme.onSurface 
                  : theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
            enabled: widget.enabled,
            filled: true,
            fillColor: widget.enabled 
                ? (theme.inputDecorationTheme.fillColor ?? Colors.grey[100]) 
                : Colors.grey[50],
            contentPadding: widget.contentPadding ?? 
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: daylizTheme?.inputBorderRadius ?? BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: daylizTheme?.inputBorderRadius ?? BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: daylizTheme?.inputBorderRadius ?? BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.primaryColor,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: daylizTheme?.inputBorderRadius ?? BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: daylizTheme?.inputBorderRadius ?? BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 1.5,
              ),
            ),
            prefixIcon: widget.prefixIcon != null 
                ? Icon(widget.prefixIcon) 
                : widget.prefix,
            suffixIcon: suffixIconWidget,
          ),
          style: theme.textTheme.bodyMedium,
          obscureText: widget.obscureText && !_isPasswordVisible,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          onEditingComplete: widget.onEditingComplete,
          onSubmitted: widget.onSubmitted,
          inputFormatters: widget.inputFormatters,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          textCapitalization: widget.textCapitalization,
        ),
      ],
    );
  }
} 