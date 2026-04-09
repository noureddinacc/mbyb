import 'package:flutter/material.dart';

class RoundedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool enabled;

  const RoundedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = enabled
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).disabledColor;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: enabled ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
