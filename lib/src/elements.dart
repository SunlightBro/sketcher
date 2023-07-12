import 'dart:math';
import 'dart:ui' as ui;

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:sketch/src/dashed_path_painter.dart';
import 'package:sketch/src/element_modifiers.dart';

@immutable
sealed class SketchElement with Drawable {}

class LineEle extends SketchElement {
  LineEle(
    this.start,
    this.end,
    this.color,
    this.lineType,
    this.strokeWidth, {
    this.description,
  });

  /// The Line to be drawn
  final Point<double> start;
  final Point<double> end;

  /// [LineEle] modifiers
  final ui.Color color;
  final LineType lineType;
  final double strokeWidth;

  /// optional description
  final String? description;

  @override
  void draw(ui.Canvas canvas, ui.Size size) {
    final ui.Paint paint = ui.Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = ui.StrokeCap.round
      ..style = ui.PaintingStyle.stroke;

    canvas.drawLine(
      ui.Offset(start.x, start.y),
      ui.Offset(end.x, end.y),
      paint,
    );
  }
}

class FreeEle extends SketchElement {
  FreeEle(
    this.points,
    this.color,
    this.lineType,
    this.strokeWidth,
  );

  /// The Path to be drawn.
  final IList<Point<double>> points;

  /// [FreeEle] modifiers
  final ui.Color color;
  final LineType lineType;
  final double strokeWidth;

  @override
  void draw(ui.Canvas canvas, ui.Size size) {
    final path = ui.Path()..moveTo(points[0].x, points[0].y);

    points
      ..removeAt(0)
      ..forEach((p) {
        path.lineTo(p.x, p.y);
      });

    switch (lineType) {
      case LineType.dashed:
        DashedPathPainter(
          originalPath: path,
          pathColor: color,
          strokeWidth: strokeWidth,
          dashGapLength: strokeWidth * 2,
          dashLength: strokeWidth * 4,
        ).paint(canvas, size);
      case LineType.dotted:
        DashedPathPainter(
          originalPath: path,
          pathColor: color,
          strokeWidth: strokeWidth,
          dashGapLength: strokeWidth,
          dashLength: strokeWidth,
        ).paint(canvas, size);
      case _:
        final ui.Paint paint = ui.Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..strokeCap = ui.StrokeCap.round
          ..style = ui.PaintingStyle.stroke;
        canvas.drawPath(path, paint);
    }
  }
}

class TextEle extends SketchElement {
  TextEle({
    required this.text,
    required this.color,
    required this.point,
    this.direction = TextDirection.ltr,
  }) : textPainter = TextPainter(
          text: TextSpan(text: text),
          textAlign: TextAlign.center,
          textDirection: direction,
        );

  /// The text to be drawn.
  final String text;

  /// The color of the text.
  final ui.Color color;

  /// The point where the text should be drawn.
  final Point<double> point;

  /// A text painter that will paint the text on the canvas.
  final TextPainter textPainter;

  /// The direction of the text to be drawn.
  final TextDirection direction;

  @override
  void draw(ui.Canvas canvas, ui.Size size) {
    textPainter.layout(maxWidth: size.width);
    final position = Offset(point.x, point.y);
    textPainter.paint(
      canvas,
      position - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }
}

mixin Drawable {
  void draw(ui.Canvas canvas, ui.Size size);
}
