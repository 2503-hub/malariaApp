import 'package:flutter/material.dart';

class MedicalTextField extends StatefulWidget {
  const MedicalTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;

  @override
  State<MedicalTextField> createState() => _MedicalTextFieldState();
}

class _MedicalTextFieldState extends State<MedicalTextField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _focusNode.hasFocus;
    final theme = Theme.of(context);
    const primaryColor = Color(0xFF087F7A);
    const borderColor = Color(0xFFE2E8F0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isFocused
                ? primaryColor.withValues(alpha: 0.16)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isFocused ? 18 : 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        textCapitalization: widget.textCapitalization,
        obscureText: widget.obscureText,
        validator: widget.validator,
        onChanged: widget.onChanged,
        autofillHints: widget.autofillHints,
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 15.5,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          prefixIcon: Icon(
            widget.prefixIcon,
            color: isFocused ? primaryColor : const Color(0xFF64748B),
          ),
          suffixIcon: widget.suffixIcon,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          labelStyle: TextStyle(
            color: isFocused ? primaryColor : const Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
          errorStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: primaryColor, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: theme.colorScheme.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: theme.colorScheme.error, width: 1.6),
          ),
        ),
      ),
    );
  }
}
