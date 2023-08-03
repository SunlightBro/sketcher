import 'dart:math';
import 'dart:ui' as ui;

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:sketch/src/dashed_path_painter.dart';
import 'package:sketch/src/element_modifiers.dart';

const double toleranceRadius = 20.0;
const double toleranceRadiusPOI = 40.0;

sealed class SketchElement with Drawable, Hitable {}

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

  ///
  final Point<double> end;

  /// [LineEle] modifiers
  ui.Color color;

  ///
  LineType lineType;

  ///
  double strokeWidth;

  /// optional description
  final String? description;

  void setActiveElementColor(Color color) {
    //return this..color = color;
  }

  /// Defines and returns the paint for full lines
  Paint _getLineTypeFullPaint(Color? activeColor) {
    return ui.Paint()
      ..color = activeColor ?? color
      ..strokeWidth = strokeWidth
      ..strokeCap = ui.StrokeCap.round
      ..style = ui.PaintingStyle.stroke;
  }

  /// Draws circles around the start and end points of the line
  void _drawActiveElementEnds({required ui.Canvas canvas, required Color color}) {
    const double activeElementEndRadius = 15.0;
    final activeElementEndPaint = Paint()..color = color.withOpacity(0.5);
    canvas.drawCircle(
      ui.Offset(start.x, start.y),
      activeElementEndRadius,
      activeElementEndPaint,
    );
    canvas.drawCircle(
      ui.Offset(end.x, end.y),
      activeElementEndRadius,
      activeElementEndPaint,
    );
  }

  /// Draws an arrow (full line and arrowhead) at the given point [arrowAt]
  void _drawArrow(
    Point<double> arrowAt, {
    required ui.Canvas canvas,
    Color? activeColor,
  }) {
    final ui.Paint paint = _getLineTypeFullPaint(activeColor);

    // direction of arrowhead
    final dX = arrowAt == end ? end.x - start.x : start.x - end.x;
    final dY = arrowAt == end ? end.y - start.y : start.y - end.y;
    final angle = atan2(dY, dX);

    // dimensions of arrowhead
    final arrowSize = 15;
    final arrowAngle = 25 * pi / 180;

    final path = Path();
    path.moveTo(arrowAt.x - arrowSize * cos(angle - arrowAngle), arrowAt.y - arrowSize * sin(angle - arrowAngle));
    path.lineTo(arrowAt.x, arrowAt.y);
    path.lineTo(arrowAt.x - arrowSize * cos(angle + arrowAngle), arrowAt.y - arrowSize * sin(angle + arrowAngle));
    path.close();
    // draw arrow
    canvas.drawPath(path, paint);
    // draw full line
    _drawFullLine(canvas: canvas, activeColor: activeColor);
  }

  /// Draws a full line
  void _drawFullLine({required ui.Canvas canvas, Color? activeColor}) {
    final ui.Paint paint = _getLineTypeFullPaint(activeColor);
    canvas.drawLine(
      ui.Offset(start.x, start.y),
      ui.Offset(end.x, end.y),
      paint,
    );
  }

  @override
  void draw(ui.Canvas canvas, ui.Size size, [Color? activeColor]) {
    switch (lineType) {
      case LineType.dashed:
      case LineType.dotted:
        final path = ui.Path()..moveTo(start.x, start.y);
        path.lineTo(end.x, end.y);
        DashedPathPainter(
          originalPath: path,
          pathColor: activeColor ?? color,
          strokeWidth: strokeWidth,
          dashGapLength: strokeWidth * lineType.dashGapLengthFactor,
          dashLength: strokeWidth * lineType.dashLengthFactor,
        ).paint(canvas, size);
        break;
      case LineType.full:
        _drawFullLine(canvas: canvas, activeColor: activeColor);
      case LineType.arrowBetween:
        _drawArrow(end, canvas: canvas, activeColor: activeColor);
        _drawArrow(start, canvas: canvas, activeColor: activeColor);
        break;
      case LineType.arrowEnd:
        _drawArrow(end, canvas: canvas, activeColor: activeColor);
        break;
      case LineType.arrowStart:
        _drawArrow(start, canvas: canvas, activeColor: activeColor);
        break;
    }
    if (activeColor != null) {
      _drawActiveElementEnds(canvas: canvas, color: activeColor);
    }
  }

  /// TODO: needs documentation & improvement/simplification
  LineHitType? _hitTest(Offset position) {
    final s = Point(start.x, start.y);
    final e = Point(end.x, end.y);
    final p = Point(position.dx, position.dy);
    final double a = s.distanceTo(p);
    final b = e.distanceTo(p);
    final c = s.distanceTo(e);

    if (a < toleranceRadiusPOI || pow(b, 2) > pow(a, 2) + pow(c, 2)) {
      return a < toleranceRadiusPOI ? LineHitType.start : null;
    } else if (b < toleranceRadiusPOI || pow(a, 2) > pow(b, 2) + pow(c, 2)) {
      return b < toleranceRadiusPOI ? LineHitType.end : null;
    } else {
      final t = (a + b + c) / 2;
      final h = 2 / c * sqrt(t * (t - a) * (t - b) * (t - c));
      return h < toleranceRadius ? LineHitType.line : null;
    }
  }

  @override
  HitPointLine? getHit(ui.Offset offset) {
    LineHitType? lineHitType = _hitTest(offset);
    return lineHitType != null ? HitPointLine(this, offset, lineHitType) : null;
  }

  @override
  SketchElement create(ui.Offset updateOffset) {
    // TODO: implement create
    throw UnimplementedError();
  }

  @override
  SketchElement update(ui.Offset updateOffset, HitPoint hitPoint) {
    // todo: improve Hitable mixin to prevent type checking
    if (hitPoint is! HitPointLine) return this;
    switch (hitPoint.hitType) {
      case LineHitType.start:
        // set start of line to point of mouse/finger
        final Point<double> newStart = Point(updateOffset.dx, updateOffset.dy);
        return LineEle(newStart, end, color, lineType, strokeWidth);
      case LineHitType.end:
        // set end of line to point of mouse/finger
        final Point<double> newEnd = Point(updateOffset.dx, updateOffset.dy);
        return LineEle(start, newEnd, color, lineType, strokeWidth);
      case LineHitType.line:
        // vector between drag start and end
        final differenceVector = updateOffset - hitPoint.hitOffset;

        // using the original start and end position
        final LineEle originalElement = hitPoint.element as LineEle;
        final originalStart = originalElement.start;
        final originalEnd = originalElement.end;

        // creating the new element
        final Point<double> newStart = originalStart + Point(differenceVector.dx, differenceVector.dy);
        final Point<double> newEnd = originalEnd + Point(differenceVector.dx, differenceVector.dy);
        return LineEle(newStart, newEnd, color, lineType, strokeWidth);
    }
  }
}

class PathEle extends SketchElement {
  PathEle(
    this.points,
    this.color,
    this.lineType,
    this.strokeWidth,
  );

  /// The [points] of the Path to be drawn.
  final IList<Point<double>> points;

  /// The [color] of the text.
  final ui.Color color;

  ///
  final LineType lineType;

  ///
  final double strokeWidth;

  @override
  void draw(ui.Canvas canvas, ui.Size size, [Color? activeColor]) {
    final path = ui.Path()..moveTo(points[0].x, points[0].y);

    points
      ..removeAt(0)
      ..forEach((p) {
        path.lineTo(p.x, p.y);
      });

    switch (lineType) {
      case LineType.dashed:
      case LineType.dotted:
        DashedPathPainter(
          originalPath: path,
          pathColor: color,
          strokeWidth: strokeWidth,
          dashGapLength: strokeWidth * lineType.dashGapLengthFactor,
          dashLength: strokeWidth * lineType.dashLengthFactor,
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

  @override
  HitPoint? getHit(ui.Offset offset) {
    // TODO: implement getHit
    throw UnimplementedError();
  }

  @override
  SketchElement create(ui.Offset updateOffset) {
    // TODO: implement create
    throw UnimplementedError();
  }

  @override
  SketchElement update(ui.Offset updateOffset, HitPoint hitPoint) {
    // TODO: implement update
    throw UnimplementedError();
  }
}

class TextEle extends SketchElement {
  TextEle(
    this.text,
    this.color,
    this.point,
  ) : textPainter = TextPainter(
          text: TextSpan(text: text),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );

  /// The [text] to be drawn.
  final String text;

  /// The [color] of the text.
  final ui.Color color;

  /// The [point] where the text should be drawn.
  final Point<double> point;

  /// A [textPainter] that will paint the text on the canvas.
  final TextPainter textPainter;

  @override
  void draw(ui.Canvas canvas, ui.Size size, [Color? activeColor]) {
    textPainter.layout(maxWidth: size.width);
    final position = Offset(point.x, point.y);
    textPainter.paint(
      canvas,
      position - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  HitPoint? getHit(ui.Offset offset) {
    // TODO: implement getHit
    throw UnimplementedError();
  }

  @override
  SketchElement create(ui.Offset updateOffset) {
    // TODO: implement create
    throw UnimplementedError();
  }

  @override
  SketchElement update(ui.Offset updateOffset, HitPoint hitPoint) {
    // TODO: implement update
    throw UnimplementedError();
  }
}

mixin Drawable {
  ///
  void draw(ui.Canvas canvas, ui.Size size, [Color? activeColor]);
}

mixin Hitable {
  ///
  HitPoint? getHit(ui.Offset startOffset);

  ///
  SketchElement update(ui.Offset updateOffset, HitPoint hitPoint);

  ///
  SketchElement create(ui.Offset updateOffset);
}

sealed class HitPoint {
  HitPoint(
    this.element,
    this.hitOffset,
  );

  final SketchElement element;
  final Offset hitOffset;
}

class HitPointLine extends HitPoint {
  HitPointLine(
    super.element,
    super.hitOffset,
    this.hitType,
  );

  final LineHitType hitType;
}

class HitPointPath extends HitPoint {
  HitPointPath(
    super.element,
    super.hitOffset,
  );
}

class HitPointText extends HitPoint {
  HitPointText(
    super.element,
    super.hitOffset,
  );
}

enum LineHitType { start, end, line }

extension Editable on SketchElement {
  /// Returns values for element that are editable
  /// In following order: color, lineType, strokeWidth
  (Color?, LineType?, double?) getEditableValues() {
    final SketchElement element = this;
    switch (element) {
      case LineEle():
        return (element.color, element.lineType, element.strokeWidth);
      case _:
        return (null, null, null);
    }
  }
}
