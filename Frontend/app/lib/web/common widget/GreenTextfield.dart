import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../authentication/Login.dart';

/// ---------------------------------------------------------------
/// Reusable pieces
/// ---------------------------------------------------------------
class GreenField extends StatefulWidget {
   GreenField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
     this.onChanged,

  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
   final ValueChanged<String>? onChanged;

  @override
  State<GreenField> createState() => _GreenFieldState();
}
class _GreenFieldState extends State<GreenField> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _focused ? AppColors.bgMid : Colors.transparent,
            width: 1.6,
          ),
          boxShadow: _focused
              ? [
            BoxShadow(
              color: AppColors.bgMid.withOpacity(0.15),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ]
              : [],
        ),
        child: TextField(
          controller: widget.controller,
          obscureText: widget.obscure,
          keyboardType: widget.keyboardType,
          onChanged:widget.onChanged,
          style: const TextStyle(fontSize: 14.5, color: AppColors.textDark),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.fieldFill,
            labelText: widget.label,
            labelStyle: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13.5,
            ),
            prefixIcon: Icon(widget.icon, size: 19, color: AppColors.textMuted),
            suffixIcon: widget.suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}