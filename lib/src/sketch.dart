import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sketch/src/painter.dart';
import 'package:sketch/src/sketch_controller.dart';
import 'package:sketch/src/sketcher_gesture_recognizer.dart';

class SketchWidget extends StatefulWidget {
  const SketchWidget({
    required this.controller,
    super.key,
  });

  final SketchController controller;

  @override
  State<SketchWidget> createState() => _SketchWidgetState();
}

class _SketchWidgetState extends State<SketchWidget> {
  //late TransformationController _transformationController;

  /// [panPosition] used to display the position [MagnifierDecoration]
  Offset? panPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => widget.controller.addListener(() => setState(() {})));
    //_transformationController = TransformationController();
  }

  @override
  void dispose() {
    //_transformationController.dispose();
    widget.controller.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialAspectRatio = widget.controller.initialAspectRatio;
    final backgroundImageBytes = widget.controller.backgroundImageBytes;
    final backgroundImage = backgroundImageBytes != null
        ? Image.memory(
            backgroundImageBytes,
            fit: BoxFit.contain,
          )
        : null;
    final magnifierPosition = panPosition;
    return InteractiveViewer(
      onInteractionUpdate: (we) {},
      child: RawGestureDetector(
        gestures: <Type, GestureRecognizerFactory>{
          // Handle onLongPress touch
          LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(), (instance) {
            instance
              ..onLongPressStart = (deetz) {
                print('ONLONGPRESS START');
              };
          }),
          // Handle Tap and Pan gestures for 1 finger touch
          SketcherGestureRecognizer: GestureRecognizerFactoryWithHandlers<SketcherGestureRecognizer>(
            () => SketcherGestureRecognizer(),
            (SketcherGestureRecognizer instance) {},
          )
        },
        child: LayoutBuilder(builder: (context, constraints) {
          widget.controller.initialAspectRatio = Size(constraints.maxWidth, constraints.maxHeight);
          return AspectRatio(
            aspectRatio: initialAspectRatio != null
                ? initialAspectRatio.width / initialAspectRatio.height
                : constraints.maxWidth / constraints.maxHeight,
            child: Stack(
              children: [
                if (backgroundImage != null)
                  Positioned.fill(
                    child: backgroundImage,
                  ),
                if (widget.controller.isGridLinesEnabled)
                  Positioned.fill(
                    child: GridPaper(
                      color: widget.controller.gridLinesColor,
                      divisions: 1,
                      subdivisions: 1,
                      interval: 20,
                    ),
                  ),
                CustomPaint(
                  willChange: true,
                  isComplex: true,
                  painter: SketchPainter(
                    widget.controller.elements,
                  ),
                  foregroundPainter: ActivePainter(
                    widget.controller.activeElement,
                  ),
                  child: Container(),
                ),
                if (magnifierPosition != null)
                  Positioned(
                    left: magnifierPosition.dx - widget.controller.magnifierSize,
                    top: magnifierPosition.dy - widget.controller.magnifierSize,
                    child: RawMagnifier(
                      decoration: MagnifierDecoration(
                        shape: CircleBorder(
                          side: BorderSide(
                            color: widget.controller.magnifierColor,
                            width: widget.controller.magnifierBorderWidth,
                          ),
                        ),
                      ),
                      size: Size.square(widget.controller.magnifierSize),
                      magnificationScale: widget.controller.magnifierScale,
                      focalPointOffset: Offset(
                        widget.controller.magnifierSize / 2,
                        widget.controller.magnifierSize / 2,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
