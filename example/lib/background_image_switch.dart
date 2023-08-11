import 'package:flutter/material.dart';

enum BackgroundImageType { none, portrait, landscape }

class BackgroundImageSwitch extends StatelessWidget {
  const BackgroundImageSwitch({
    Key? key,
    required this.backgroundImageType,
    required this.onSelectBackgroundImageType,
  }) : super(key: key);

  final BackgroundImageType backgroundImageType;
  final Function(BackgroundImageType) onSelectBackgroundImageType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SegmentedButton<BackgroundImageType>(
        style: ButtonStyle(),
        segments: [
          ButtonSegment(
            label: Text("None"),
            value: BackgroundImageType.none,
          ),
          ButtonSegment(
            label: Text("Portrait"),
            value: BackgroundImageType.portrait,
          ),
          ButtonSegment(
            label: Text("Landscape"),
            value: BackgroundImageType.landscape,
          ),
        ],
        selected: <BackgroundImageType>{backgroundImageType},
        onSelectionChanged: (Set<BackgroundImageType> newBackgroundImageType) {
          onSelectBackgroundImageType(newBackgroundImageType.first);
        },
      ),
    );
  }
}
