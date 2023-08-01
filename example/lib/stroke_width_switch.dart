import 'package:flutter/material.dart';

class StrokeWidthSwitch extends StatelessWidget {
  const StrokeWidthSwitch({
    Key? key,
    required this.strokeWidth,
    required this.onSelectStrokeWidth,
  }) : super(key: key);

  final double strokeWidth;
  final Function(double) onSelectStrokeWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SegmentedButton<double>(
        style: ButtonStyle(),
        segments: [
          ButtonSegment(
            label: Text("Light"),
            value: 4.0,
          ),
          ButtonSegment(
            label: Text("Regular"),
            value: 7.0,
          ),
          ButtonSegment(
            label: Text("Bold"),
            value: 10.0,
          ),
        ],
        selected: <double>{strokeWidth},
        onSelectionChanged: (Set<double> newStrokeWidth) {
          onSelectStrokeWidth(newStrokeWidth.first);
        },
      ),
    );
  }
}
