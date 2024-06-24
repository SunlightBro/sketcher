import 'package:example/background_image_switch.dart';
import 'package:example/color_picker.dart';
import 'package:example/line_type_switch.dart';
import 'package:example/sketch_mode_switch.dart';
import 'package:example/stroke_width_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sketch/sketch.dart';

void main() {
  runApp(ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SketchPage(),
    );
  }
}

class SketchPage extends StatefulWidget {
  const SketchPage({super.key});

  @override
  State<SketchPage> createState() => _SketchPageState();
}

final IList<SketchElement> samples = IList([
  // LineEle(Point(50, 50), Point(600, 200), Colors.red, LineType.dotted, 10),
  OvalEle(
    Colors.blue,
    LineType.dotted,
    10,
    points: QuadPoints(
      pointA: Offset(20, 120),
      pointB: Offset(120, 120),
      pointC: Offset(20, 320),
      pointD: Offset(120, 320),
    ),
  ),
]);

class _SketchPageState extends State<SketchPage> {
  late SketchController controller;
  late TransformationController transformationController;
  late Uint8List backgroundImageBytesLandscapeImage;
  late Uint8List backgroundImageBytesPortraitImage;

  @override
  void initState() {
    super.initState();
    transformationController = TransformationController();
    controller = SketchController(
      inactiveElements: samples,
      onEditText: onEditTextElement,
      transformationController: transformationController,
    );

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      rootBundle.load('assets/room_landscape.jpg').then((data) => setState(
            () => backgroundImageBytesLandscapeImage = data.buffer.asUint8List(),
          ));
      rootBundle.load('assets/room.jpg').then((data) => setState(
            () => backgroundImageBytesPortraitImage = data.buffer.asUint8List(),
          ));
      controller.addListener(() => setState(() {}));
    });
  }

  @override
  void dispose() {
    controller.removeListener(() {});
    controller.dispose();
    transformationController.dispose();
    super.dispose();
  }

  Future<String?> onEditTextElement(String? text) async => await showDialog<String?>(
        context: context,
        builder: (context) {
          final textController = TextEditingController(text: text);
          final initialValue = text ?? '';
          bool hasChanges = false;

          return AlertDialog(
            title: Text('Input text value'),
            contentPadding: EdgeInsets.all(10),
            content: StatefulBuilder(builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    autofocus: true,
                    onChanged: (currentValue) => setState(() {
                      hasChanges = initialValue != currentValue;
                    }),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: hasChanges ? () => Navigator.of(context).pop(textController.text) : null,
                          child: Text('Save'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Cancel'),
                        ),
                      ],
                    ),
                  )
                ],
              );
            }),
          );
        },
      );

  void _onSwitchImages(BackgroundImageType backgroundImageType) {
    setState(() {
      switch (backgroundImageType) {
        case BackgroundImageType.none:
          controller.backgroundImageBytes = null;
          break;
        case BackgroundImageType.portrait:
          controller.backgroundImageBytes = backgroundImageBytesPortraitImage;
          break;
        case BackgroundImageType.landscape:
          controller.backgroundImageBytes = backgroundImageBytesLandscapeImage;
          break;
      }
    });
  }

  void _onSelectSketchMode(SketchMode sketchMode) {
    setState(() {
      controller.sketchMode = sketchMode;
    });
  }

  void _onSelectLineType(LineType lineType) {
    controller.lineType = lineType;
  }

  void _onSelectColor(Color color) {
    controller.color = color;
  }

  void _onSelectStrokeWidth(double strokeWidth) {
    controller.strokeWidth = strokeWidth;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SketchWidget(
            controller: controller,
            transformationController: transformationController,
          ),
          Align(
            alignment: Alignment.center,
            child: Column(
              children: [
                SizedBox(height: 16.0),
                Text("Sketch Mode"),
                SketchModeSwitch(
                  sketchMode: controller.sketchMode,
                  onSelectSketchMode: _onSelectSketchMode,
                ),
                TextButton(
                  onPressed: () => controller.addTextElement('Sample Text'),
                  child: Text('Add text Element'),
                ),
                SizedBox(height: 8.0),
                Text("Color"),
                ColorPicker(
                  color: controller.color,
                  onSelectColor: _onSelectColor,
                ),
                SizedBox(height: 8.0),
                Text("Line Type"),
                LineTypeSwitch(
                  lineType: controller.lineType,
                  onSelectLineType: _onSelectLineType,
                ),
                SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text("Stroke Width"),
                        StrokeWidthSwitch(
                          strokeWidth: controller.strokeWidth,
                          onSelectStrokeWidth: _onSelectStrokeWidth,
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text("Background Image"),
                        BackgroundImageSwitch(
                          onSelectBackgroundImageType: _onSwitchImages,
                          backgroundImageType: controller.backgroundImageBytes == null
                              ? BackgroundImageType.none
                              : controller.backgroundImageBytes == backgroundImageBytesPortraitImage
                                  ? BackgroundImageType.portrait
                                  : BackgroundImageType.landscape,
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Grid Lines:'),
                    Switch(
                      value: controller.isGridLinesEnabled,
                      onChanged: (value) => controller.isGridLinesEnabled = value,
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: controller.undoPossible ? () => controller.undo() : null,
                      icon: Icon(Icons.undo),
                    ),
                    IconButton(
                      onPressed: controller.deletePossible ? () => controller.deleteActiveElement() : null,
                      icon: Icon(Icons.delete),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
