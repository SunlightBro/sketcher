import 'dart:math';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:sketch/src/element_modifiers.dart';
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
    final magnifierPosition = panPosition;
    return GestureDetector(
      excludeFromSemantics: true,
      behavior: HitTestBehavior.translucent,
      onTapDown: (TapDownDetails tapDownDetails) {
        /*
        final _globalPosition = _transformationController.toScene(tapDownDetails.localPosition);
        print(_globalPosition);
        */
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
            painter: SketchPainter(<SketchElement>[
              TextEle(
                "text",
                Colors.red,
                const Point(300, 300),
              ),
              LineEle(
                const Point(20, 30),
                const Point(400, 600),
                Colors.green,
                LineType.full,
                4.0,
              ),
              PathEle(
                <Point<double>>[
                  const Point(10, 10),
                  const Point(304, 33),
                  const Point(32, 980),
                  const Point(640, 11),
                ].lock,
                Colors.purple,
                LineType.dashed,
                8.0,
              ),
            ].lock),
            //foregroundPainter: ActivePainter(),
            child: Placeholder(),
          ),
          //Placeholder(),
          if (magnifierPosition != null)
            Positioned(
              left: magnifierPosition.dx,
              top: magnifierPosition.dy,
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
