import 'package:flutter/material.dart';
import 'package:sketch/src/painter.dart';
import 'package:sketch/src/sketch_controller.dart';

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
    widget.controller.addListener(() => setState(() {}));
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
    final magnifierPosition = panPosition;
    return GestureDetector(
      excludeFromSemantics: true,
      behavior: HitTestBehavior.translucent,
      onPanDown: (DragDownDetails details) {
        setState(() => panPosition = details.localPosition);
        widget.controller.onPanDown(details);
      },
      onPanStart: (DragStartDetails details) {
        setState(() => panPosition = details.localPosition);
        widget.controller.onPanStart(details);
      },
      onPanUpdate: (DragUpdateDetails details) {
        setState(() => panPosition = details.localPosition);
        widget.controller.onPanUpdate(details);
      },
      onPanEnd: (DragEndDetails details) {
        setState(() => panPosition = null);
        widget.controller.onPanEnd(details);
      },
      onPanCancel: () {
        setState(() => panPosition = null);
        widget.controller.onPanCancel();
      },
      child: Stack(
        children: [
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
              left: magnifierPosition.dx,
              top: magnifierPosition.dy,
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
                  -widget.controller.magnifierSize / 2,
                  -widget.controller.magnifierSize / 2,
                ),
              ),
            )
        ],
      ),
    );
  }
}
