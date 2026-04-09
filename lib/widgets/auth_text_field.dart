import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: AppColors.background,
      ),
      validator: validator,
    );
  }
}
