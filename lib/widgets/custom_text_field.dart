import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? helperText;
  final int? maxLength;
  final int maxLines;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.helperText,
    this.maxLength,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        helperText: helperText,
      ),
      validator: validator,
    );
  }
}
