import 'package:flutter/material.dart';
import 'package:sketch/sketch.dart';

class LineTypeSwitch extends StatelessWidget {
  const LineTypeSwitch({
    Key? key,
    required this.lineType,
    required this.onSelectLineType,
  }) : super(key: key);

  final LineType lineType;
  final Function(LineType) onSelectLineType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SegmentedButton<LineType>(
        style: ButtonStyle(),
        segments: [
          ButtonSegment(
            label: Text("Full"),
            value: LineType.full,
          ),
          ButtonSegment(
            label: Text("Dashed"),
            value: LineType.dashed,
          ),
          ButtonSegment(
            label: Text("Dotted"),
            value: LineType.dotted,
          ),
          ButtonSegment(
            label: Text("Arrow Start"),
            value: LineType.arrowStart,
          ),
          ButtonSegment(
            label: Text("Arrow End"),
            value: LineType.arrowEnd,
          ),
          ButtonSegment(
            label: Text("Arrow Both"),
            value: LineType.arrowBetween,
          ),
        ],
        selected: <LineType>{lineType},
        onSelectionChanged: (Set<LineType> newSelection) {
          onSelectLineType(newSelection.first);
        },
      ),
    );
  }
}
