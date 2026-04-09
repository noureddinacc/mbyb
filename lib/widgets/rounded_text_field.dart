import 'package:flutter/material.dart';

class RoundedTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final bool obscureText;
  final TextInputType keyboardType;

  const RoundedTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          
          borderRadius: BorderRadius.circular(30.0),
        ),
      ),
    );
  }
}
