import 'dart:math';
import 'dart:ui' as ui;

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:sketch/src/dashed_path_painter.dart';
import 'package:sketch/src/element_modifiers.dart';

const double toleranceRadius = 5.0;

@immutable
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
  final ui.Color color;

  ///
  final LineType lineType;

  ///
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

  LineHitType? _hitTest(Offset position) {
    final s = Point(start.x, start.y);
    final e = Point(end.x, end.y);
    final p = Point(position.dx, position.dy);
    final double a = s.distanceTo(p);
    final b = e.distanceTo(p);
    final c = s.distanceTo(e);
    if (pow(b, 2) > pow(a, 2) + pow(c, 2) && a < toleranceRadius) {
      return LineHitType.start;
    } else if (pow(a, 2) > pow(b, 2) + pow(c, 2) && b < toleranceRadius) {
      return LineHitType.end;
    } else {
      final t = (a+b+c)/2;
      final h = 2/c * sqrt(t*(t-a)*(t-b)*(t-c));
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
    // TODO: implement update
    throw UnimplementedError();
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
  void draw(ui.Canvas canvas, ui.Size size) {
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
  void draw(ui.Canvas canvas, ui.Size size) {
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
  void draw(ui.Canvas canvas, ui.Size size);
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
