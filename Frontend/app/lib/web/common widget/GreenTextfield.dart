
import 'package:flutter/material.dart';

class GreenField extends StatelessWidget {
  const GreenField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.onChanged,
    this.height,
    this.width,
    this.multiline = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final double? height;
  final double? width;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFEAF8EE);

    return SizedBox(
      width: width ?? double.infinity,
      height: multiline ? (height ?? 150) : height,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType ??
            (multiline ? TextInputType.multiline : TextInputType.text),
        onChanged: onChanged,

        minLines: multiline ? null : 1,
        maxLines: multiline ? null : 1,
        expands: multiline,

        textAlignVertical: TextAlignVertical.top,
        textCapitalization: TextCapitalization.sentences,

        style: const TextStyle(
          fontSize: 14.5,
          color: Colors.black,
        ),

        decoration: InputDecoration(
          filled: true,
          fillColor: backgroundColor,
          alignLabelWithHint: true,

          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.red,
            fontSize: 13.5,
          ),

          prefixIcon: multiline ? null : Icon(
            icon,
            size: 19,
            color: Colors.brown,
          ),

          suffixIcon: suffix,

          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 12,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
