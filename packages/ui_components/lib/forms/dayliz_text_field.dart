import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DaylizTextField extends StatefulWidget {
  final String? label;
  final String? labelText; // Alternative to label
  final String? hint;
  final String? hintText; // Alternative to hint
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
  final Widget? suffixIconWidget; // Support for Widget suffixIcon
  final VoidCallback? onSuffixIconTap;
  final VoidCallback? onTap;
  final bool readOnly;
  final EdgeInsetsGeometry? contentPadding;
  final TextCapitalization textCapitalization;

  const DaylizTextField({
    super.key,
    this.label,
    this.labelText,
    this.hint,
    this.hintText,
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
    this.suffixIconWidget,
    this.onSuffixIconTap,
    this.onTap,
    this.readOnly = false,
    this.contentPadding,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<DaylizTextField> createState() => _DaylizTextFieldState();
}

class _DaylizTextFieldState extends State<DaylizTextField> {
  late TextEditingController _controller;
  bool _isPasswordVisible = false;
  bool _showClearButton = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
    _showClearButton = widget.showClearButton && _controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    if (widget.showClearButton) {
      final shouldShow = _controller.text.isNotEmpty;
      if (shouldShow != _showClearButton) {
        setState(() {
          _showClearButton = shouldShow;
        });
      }
    }
  }

  void _clearText() {
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

    // Get effective label and hint
    final effectiveLabel = widget.labelText ?? widget.label;
    final effectiveHint = widget.hintText ?? widget.hint;

    Widget? suffixWidget;
    if (widget.obscureText) {
      suffixWidget = IconButton(
        icon: Icon(
          _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey[600],
        ),
        onPressed: _togglePasswordVisibility,
      );
    } else if (_showClearButton) {
      suffixWidget = IconButton(
        icon: Icon(
          Icons.clear,
          color: Colors.grey[600],
        ),
        onPressed: _clearText,
      );
    } else if (widget.suffixIconWidget != null) {
      suffixWidget = widget.suffixIconWidget;
    } else if (widget.suffixIcon != null) {
      suffixWidget = IconButton(
        icon: Icon(widget.suffixIcon),
        onPressed: widget.onSuffixIconTap,
      );
    } else if (widget.suffix != null) {
      suffixWidget = widget.suffix;
    }

    Widget? prefixWidget;
    if (widget.prefixIcon != null) {
      prefixWidget = Icon(
        widget.prefixIcon,
        color: Colors.grey[600],
      );
    } else if (widget.prefix != null) {
      prefixWidget = widget.prefix;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (effectiveLabel != null) ...[
          Text(
            effectiveLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: _controller,
          validator: widget.validator,
          decoration: InputDecoration(
            hintText: effectiveHint,
            errorText: widget.errorText,
            enabled: widget.enabled,
            filled: true,
            fillColor: widget.enabled
                ? (theme.inputDecorationTheme.fillColor ?? Colors.grey[100])
                : Colors.grey[50],
            contentPadding: widget.contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 2,
              ),
            ),
            prefixIcon: prefixWidget,
            suffixIcon: suffixWidget,
          ),
          style: theme.textTheme.bodyMedium,
          obscureText: widget.obscureText && !_isPasswordVisible,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          onEditingComplete: widget.onEditingComplete,
          onFieldSubmitted: widget.onSubmitted,
          inputFormatters: widget.inputFormatters,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          textCapitalization: widget.textCapitalization,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
        ),
      ],
    );
  }
}