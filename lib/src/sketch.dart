import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sketch/src/painter.dart';
import 'package:sketch/src/sketch_controller.dart';

class SketchWidget extends StatefulWidget {
  const SketchWidget({
    required this.controller,
    required this.transformationController,
    super.key,
  });

  final SketchController controller;
  final TransformationController transformationController;

  @override
  State<SketchWidget> createState() => _SketchWidgetState();
}

class _SketchWidgetState extends State<SketchWidget> {
  /// [panPosition] used to display the position [MagnifierDecoration]
  Offset? panPosition;

  Offset localPosition = Offset(0, 0);

  double get magnifierSize => widget.controller.magnifierSize / widget.controller.scaleFactor;

  TransformationController get transformationController => widget.transformationController;

  SketchController get controller => widget.controller;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.controller.addListener(() => setState(() {}));
    });
  }

  @override
  void dispose() {
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

    return LayoutBuilder(builder: (context, constraints) {
      final renderBox = context.findRenderObject() as RenderBox;
      controller.initialAspectRatio = Size(constraints.maxWidth, constraints.maxHeight);

      return InteractiveViewer(
        transformationController: transformationController,
        panEnabled: controller.sketchMode == SketchMode.edit && controller.activeElement == null,
        constrained: true,
        maxScale: controller.maxScale,
        minScale: controller.minScale,
        onInteractionStart: (details) {
          if (details.pointerCount == 1 && !controller.isZooming) {
            final localOffset = renderBox.globalToLocal(details.focalPoint);
            final transformation = transformationController.value;
            final invertedMatrix = Matrix4.inverted(transformation);
            final modifiedOffset = MatrixUtils.transformPoint(invertedMatrix, localOffset);
            setState(() => panPosition = modifiedOffset);
            controller.onPanStart(modifiedOffset);
          } else {
            controller.isZooming = true;
            controller.baseScaleFactor = widget.controller.scaleFactor;
          }
        },
        onInteractionUpdate: (details) {
          if (details.pointerCount == 1 && !controller.isZooming) {
            final localOffset = renderBox.globalToLocal(details.focalPoint);
            final transformation = transformationController.value;
            final invertedMatrix = Matrix4.inverted(transformation);
            final modifiedOffset = MatrixUtils.transformPoint(invertedMatrix, localOffset);

            setState(() => panPosition = modifiedOffset);

            controller.onPanUpdate(modifiedOffset);
          } else {
            controller.isZooming = true;
            controller.scaleFactor = controller.baseScaleFactor * details.scale;
          }
        },
        onInteractionEnd: (details) {
          if (controller.isZooming) {
            // Note: This is a workaround for this issue https://github.com/flutter/flutter/issues/132007
            // [onInteractionEnd] for Android, releasing 2 fingers at the same time returns a pointerCount of 1 instead of zero
            final isNotZooming = Platform.isAndroid ? details.pointerCount < 2 : details.pointerCount == 0;
            controller.isZooming = !isNotZooming;
          }

          if (panPosition == null) return;

          setState(() => panPosition = null);

          if (!controller.isZooming) controller.onPanEnd();
        },
        child: GestureDetector(
          excludeFromSemantics: true,
          behavior: HitTestBehavior.translucent,
          onLongPressStart: (details) {
            setState(() => panPosition = details.localPosition);
            controller.onLongPressStart(details.localPosition);
          },
          onLongPressMoveUpdate: (LongPressMoveUpdateDetails details) {
            setState(() => panPosition = details.localPosition);
            controller.onLongPressMoveUpdate(details.localPosition);
          },
          onLongPressEnd: (LongPressEndDetails details) {
            setState(() => panPosition = null);
            controller.onLongPressEnd(details);
          },
          onTapUp: (TapUpDetails details) => controller.onTapUp(details.localPosition),
          child: AspectRatio(
            aspectRatio: initialAspectRatio != null
                ? initialAspectRatio.width / initialAspectRatio.height
                : constraints.maxWidth / constraints.maxHeight,
            child: Stack(
              children: [
                if (backgroundImage != null) Positioned.fill(child: backgroundImage),
                if (controller.isGridLinesEnabled)
                  Positioned.fill(
                    child: GridPaper(
                      color: controller.gridLinesColor,
                      divisions: 1,
                      subdivisions: 1,
                      interval: 20,
                    ),
                  ),
                CustomPaint(
                  willChange: true,
                  isComplex: true,
                  painter: SketchPainter(controller.elements),
                  foregroundPainter: ActivePainter(controller.activeElement),
                  child: Container(),
                ),
                if (magnifierPosition != null && controller.activeElement != null)
                  Positioned(
                    left: magnifierPosition.dx - (magnifierSize),
                    top: magnifierPosition.dy - (magnifierSize),
                    child: RawMagnifier(
                      decoration: MagnifierDecoration(
                        shape: CircleBorder(
                          side: BorderSide(
                            color: controller.magnifierColor,
                            width: controller.magnifierBorderWidth,
                          ),
                        ),
                      ),
                      size: Size.square(magnifierSize),
                      magnificationScale: controller.magnifierScale,
                      focalPointOffset: Offset(
                        magnifierSize / 2,
                        magnifierSize / 2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
