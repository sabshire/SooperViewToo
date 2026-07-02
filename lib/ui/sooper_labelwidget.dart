import 'package:flutter/material.dart';

class SooperLabel extends StatelessWidget {
  final String label;
  final Widget child;
  final double spacing; // Distance between label and the widget

  const SooperLabel({
    super.key,
    required this.label,
    required this.child,
    this.spacing = 8.0, // Default space of 8 pixels
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center, // Centers everything horizontally
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: spacing), // Dynamic spacer
        child, // Displays your dropdown, textfield, or any other widget
      ],
    );
  }
}