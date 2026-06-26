import 'dart:core';
import 'package:flutter/material.dart';

class SooperDropdown<T> extends StatefulWidget {
  // Pass through Variables
  final T dropdownValue;
  final List<T> dropdownValueList;
  final ValueChanged<T?> onStateChanged;

  const SooperDropdown({
    super.key,
    required this.dropdownValue,
    required this.dropdownValueList,
    required this.onStateChanged, // Adds state change event
  });

  @override
  State<SooperDropdown<T>> createState() => _SooperDropdownState<T>();
}

class _SooperDropdownState<T> extends State<SooperDropdown<T>> {

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          focusColor: Colors.transparent
        ),
        child: DropdownButton<T>(
          value: widget.dropdownValue,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          hint: const Text("Processor", style: TextStyle(fontStyle: FontStyle.italic)),
          isExpanded: true,
          items: widget.dropdownValueList.map((T value) {
            return DropdownMenuItem<T>(
              value: value,
              child: Text(value.toString(), style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (T? value) {
            widget.onStateChanged(value); // Sends event to where this widget is instantiated. When they on SetState to set their value this will refresh this.
          },
        ),
      )
    );
  }
}