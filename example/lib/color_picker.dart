import 'package:flutter/material.dart';

class ColorPicker extends StatelessWidget {
  const ColorPicker({
    Key? key,
    required this.color,
    required this.onSelectColor,
  }) : super(key: key);

  final Color color;
  final Function(Color) onSelectColor;

  ButtonSegment<Color> _getButtonSegment(Color color) {
    return ButtonSegment(
      icon: Padding(
        padding: const EdgeInsets.all(4.0),
        child: CircleAvatar(
          backgroundColor: color,
          radius: 10,
        ),
      ),
      value: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SegmentedButton<Color>(
        style: ButtonStyle(),
        segments: [
          _getButtonSegment(Colors.black),
          _getButtonSegment(Colors.red),
          _getButtonSegment(Colors.blue),
          _getButtonSegment(Colors.green),
        ],
        selected: <Color>{color},
        onSelectionChanged: (Set<Color> newColor) {
          onSelectColor(newColor.first);
        },
      ),
    );
  }
}
