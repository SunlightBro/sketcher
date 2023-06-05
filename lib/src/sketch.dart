import 'dart:math';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/widgets.dart';
import 'package:sketch/src/elements.dart';
import 'package:sketch/src/painter.dart';

class Sketch extends StatefulWidget {
  const Sketch({super.key});

  @override
  State<Sketch> createState() => _SketchState();
}

class _SketchState extends State<Sketch> {
  late TransformationController _transformationController;

  Offset? panPosition;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      excludeFromSemantics: true,
      behavior: HitTestBehavior.translucent,

      onTapDown: (TapDownDetails tapDownDetails) {
        final _globalPosition =
            _transformationController.toScene(tapDownDetails.localPosition);
        print(_globalPosition);
      },
      onPanDown: (details) =>
          setState(() => panPosition = details.localPosition),
      onPanStart: (details) =>
          setState(() => panPosition = details.localPosition),
      onPanUpdate: (details) =>
          setState(() => panPosition = details.localPosition),
      onPanEnd: (details) => setState(() => panPosition = null),
      onPanCancel: () => setState(() => panPosition = null),
      child: Stack(
        children: [
          CustomPaint(
            willChange: true,
            isComplex: true,
            painter: SketchPainter(<SketchElement>[].lock),
            //foregroundPainter: ActivePainter(),
          ),
          Placeholder(),
          if (panPosition != null)
            Positioned(
              left: panPosition!.dx,
              top: panPosition!.dy,
              child: const RawMagnifier(
                decoration: MagnifierDecoration(
                  shape: CircleBorder(
                    side: BorderSide(color: Color(0xffffcc00), width: 3),
                  ),
                ),
                size: Size(64, 64),
                magnificationScale: 2,
              ),
            )
        ],
      ),
    );
  }
}
