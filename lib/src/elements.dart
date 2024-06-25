// ignore_for_file: avoid_non_null_assertion
import 'dart:math';
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sketch/src/dashed_path_painter.dart';
import 'package:sketch/src/element_modifiers.dart';
import 'package:sketch/src/extensions.dart';

const _arrowScaleMultiplier = 3.5;
typedef EndPoints = ({Point<double> start, Point<double> end});

sealed class SketchElement with Drawable, Hitable {}

/// Sketch elements that are drawn by the user
abstract class DrawableSketchElement implements SketchElement {
  final ui.Color color;

  final LineType lineType;

  final double strokeWidth;

  bool _isActive = false;

  bool get isActive => _isActive;

  set isActive(bool active) {
    _isActive = active;
  }

  DrawableSketchElement(this.color, this.lineType, this.strokeWidth);

  /// Touch tolerance of sketch element
  double get touchTolerance => strokeWidth + 5;

  /// Touch tolerance of line points
  double get touchToleranceRadius => 20;
}

/// Draws an arrow head at the given point [arrowHeadPoint]
void _drawArrowHead({
  required ui.Paint paint,
  required ui.Canvas canvas,
  required Point<double> arrowHeadPoint,
  required Point<double> arrowTailPoint,
  required double arrowSize,
}) {
  final arrowPoint = arrowHeadPoint - arrowTailPoint;
  final angle = atan2(arrowPoint.y, arrowPoint.x);
  final arrowAngle = 25 * pi / 180;

  /// Create arrow path
  final path = Path();
  path.moveTo(
      arrowHeadPoint.x - arrowSize * cos(angle - arrowAngle), arrowHeadPoint.y - arrowSize * sin(angle - arrowAngle));
  path.lineTo(arrowHeadPoint.x, arrowHeadPoint.y);
  path.lineTo(
      arrowHeadPoint.x - arrowSize * cos(angle + arrowAngle), arrowHeadPoint.y - arrowSize * sin(angle + arrowAngle));
  path.close();

  // draw arrow
  canvas.drawPath(path, paint);
}

EndPoints _reduceLineLength(Point<double> startPoint, Point<double> endPoint, double reductionSize) {
  // Calculate the vector representing the line direction
  final lineVectorX = endPoint.x - startPoint.x;
  final lineVectorY = endPoint.y - startPoint.y;

  // Normalize the line vector to obtain a unit vector in the direction of the line
  final unitVectorX = lineVectorX / sqrt(lineVectorX * lineVectorX + lineVectorY * lineVectorY);
  final unitVectorY = lineVectorY / sqrt(lineVectorX * lineVectorX + lineVectorY * lineVectorY);

  // Scale the unit vector by the reduction value to get the adjustment vector
  final adjustmentVectorX = unitVectorX * -reductionSize;
  final adjustmentVectorY = unitVectorY * -reductionSize;

  // Adjust the start point to obtain the shortened line
  final newStartPoint = Point(startPoint.x - adjustmentVectorX, startPoint.y - adjustmentVectorY);

  // Calculate the adjusted end point by adding the adjustment vector to the original end point
  final newEndPoint = Point(endPoint.x + adjustmentVectorX, endPoint.y + adjustmentVectorY);

  return (start: newStartPoint, end: newEndPoint);
}

class LineEle extends DrawableSketchElement {
  LineEle(
    this.start,
    this.end,
    super.color,
    super.lineType,
    super.strokeWidth, {
    this.description,
  });

  /// The Line to be drawn
  final Point<double> start;

  ///
  final Point<double> end;

  /// optional description
  final String? description;

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
    final activeElementEndPaint = Paint()..color = color.withOpacity(0.5);
    canvas.drawCircle(
      ui.Offset(start.x, start.y),
      touchToleranceRadius,
      activeElementEndPaint,
    );
    canvas.drawCircle(
      ui.Offset(end.x, end.y),
      touchToleranceRadius,
      activeElementEndPaint,
    );
  }

  /// Draws a full line
  void _drawFullLine({
    required ui.Canvas canvas,
    Color? activeColor,
    EndPoints? endPoints,
  }) {
    final ui.Paint paint = _getLineTypeFullPaint(activeColor);
    canvas.drawLine(
      ui.Offset(endPoints?.start.x ?? start.x, endPoints?.start.y ?? start.y),
      ui.Offset(endPoints?.end.x ?? end.x, endPoints?.end.y ?? end.y),
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
      case LineType.arrowStart:
      case LineType.arrowEnd:
        final arrowSize = strokeWidth * _arrowScaleMultiplier;
        // Reduce  the rendered line length so it does not show at the tip of the arrow
        final shortenedLine = _reduceLineLength(start, end, arrowSize * 0.8);
        final adjustedEndPoints = (
          start: lineType != LineType.arrowEnd ? shortenedLine.start : start,
          end: lineType != LineType.arrowStart ? shortenedLine.end : end
        );
        final arrowPaint = ui.Paint()
          ..color = activeColor ?? color
          ..strokeWidth = 1
          ..strokeCap = ui.StrokeCap.round;

        if (lineType == LineType.arrowBetween) {
          _drawArrowHead(
            paint: arrowPaint,
            canvas: canvas,
            arrowHeadPoint: start,
            arrowTailPoint: end,
            arrowSize: arrowSize,
          );
          _drawArrowHead(
            paint: arrowPaint,
            canvas: canvas,
            arrowHeadPoint: end,
            arrowTailPoint: start,
            arrowSize: arrowSize,
          );
        } else if (lineType == LineType.arrowStart || lineType == LineType.arrowEnd) {
          final isLineEnd = lineType == LineType.arrowEnd;

          _drawArrowHead(
            paint: arrowPaint,
            canvas: canvas,
            arrowHeadPoint: isLineEnd ? end : start,
            arrowTailPoint: isLineEnd ? start : end,
            arrowSize: arrowSize,
          );
        }

        _drawFullLine(
          canvas: canvas,
          activeColor: activeColor,
          endPoints: adjustedEndPoints,
        );
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

    if (a <= touchToleranceRadius || pow(b, 2) > pow(a, 2) + pow(c, 2)) {
      return a <= touchToleranceRadius ? LineHitType.start : null;
    } else if (b <= touchToleranceRadius || pow(a, 2) > pow(b, 2) + pow(c, 2)) {
      return b <= touchToleranceRadius ? LineHitType.end : null;
    } else {
      final t = (a + b + c) / 2;
      final h = 2 / c * sqrt(t * (t - a) * (t - b) * (t - c));
      return h <= touchTolerance ? LineHitType.line : null;
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

class PathEle extends DrawableSketchElement {
  PathEle(
    this.points,
    super.color,
    super.lineType,
    super.strokeWidth,
  );

  /// The [points] of the Path to be drawn.
  final IList<Point<double>> points;

  @override
  void draw(ui.Canvas canvas, ui.Size size, [Color? activeColor]) {
    final path = ui.Path()..moveTo(points[0].x, points[0].y);

    points
      ..removeAt(0)
      ..forEach((p) {
        path.lineTo(p.x, p.y);
      });

    final currentColor = activeColor ?? color;

    switch (lineType) {
      case LineType.dashed:
      case LineType.dotted:
        DashedPathPainter(
          originalPath: path,
          pathColor: currentColor,
          strokeWidth: strokeWidth,
          dashGapLength: strokeWidth * lineType.dashGapLengthFactor,
          dashLength: strokeWidth * lineType.dashLengthFactor,
        ).paint(canvas, size);
      case _:
        final ui.Paint paint = ui.Paint()
          ..color = currentColor
          ..strokeWidth = strokeWidth
          ..strokeCap = ui.StrokeCap.round
          ..style = ui.PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round;
        canvas.drawPath(path, paint);
    }
  }

  /// Returns true if offset/position is near any of the Path's points
  @override
  HitPoint? getHit(ui.Offset offset) {
    final currentPosition = Point<double>(offset.dx, offset.dy);
    List<Point<double>> initialPoints = List.from(points);
    bool gotHit = false;

    for (final currentCheckingPoint in initialPoints) {
      if (currentCheckingPoint.distanceTo(currentPosition) < touchToleranceRadius) {
        gotHit = true;
        break;
      }
    }

    return gotHit ? HitPointPath(this, offset) : null;
  }

  @override
  SketchElement create(ui.Offset updateOffset) {
    // TODO: implement create
    throw UnimplementedError();
  }

  @override
  SketchElement update(ui.Offset updateOffset, HitPoint hitPoint) {
    final differenceVector = updateOffset - hitPoint.hitOffset;
    final originalElement = hitPoint.element as PathEle;
    final originalPoints = originalElement.points;
    final movementPoint = Point(differenceVector.dx, differenceVector.dy);
    final updatedPoints = originalPoints.map((element) => element + movementPoint).toIList();

    return PathEle(updatedPoints, color, lineType, strokeWidth);
  }
}

class TextEle extends SketchElement {
  TextEle(
    this.text,
    this.color,
    this.point, {
    this.orientation = Orientation.portrait,
    this.hasComputedPosition = false,
  }) : textPainter = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(color: Colors.white),
          ),
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

  /// This is true if the text element was added programmatically
  /// By default, it is set to [false]
  bool hasComputedPosition;

  /// Determines the orientation of the text element
  Orientation orientation;

  @override
  void draw(ui.Canvas canvas, ui.Size size, [Color? activeColor]) {
    final position = Offset(point.x, point.y);
    textPainter.layout(maxWidth: size.width);

    final degrees = orientation == Orientation.landscape ? 90 : 0;
    final radians = degrees * pi / 180;

    canvas
      ..save()
      ..translate(point.x, point.y)
      ..rotate(radians)
      ..translate(-point.x, -point.y);

    // background of text element
    final backgroundPaint = ui.Paint()..color = activeColor ?? Colors.black.withOpacity(0.70);
    canvas.drawRRect(
      RRect.fromRectXY(
        Rect.fromCenter(
          center: position,
          width: textPainter.width + 16,
          height: textPainter.height + 16,
        ),
        10,
        10,
      ),
      backgroundPaint,
    );

    // the actual text
    textPainter.paint(
      canvas,
      position - Offset(textPainter.width / 2, textPainter.height / 2),
    );

    canvas.restore();
  }

  @override
  HitPoint? getHit(ui.Offset offset) {
    return offset.dx >= point.x - textPainter.width / 2 &&
            offset.dx <= point.x + textPainter.width / 2 &&
            offset.dy >= point.y - textPainter.height / 2 &&
            offset.dy <= point.y + textPainter.height / 2
        ? HitPointText(this, offset)
        : null;
  }

  @override
  SketchElement create(ui.Offset updateOffset) {
    // TODO: implement create
    throw UnimplementedError();
  }

  @override
  SketchElement update(ui.Offset updateOffset, HitPoint hitPoint) {
    return TextEle(
      text,
      color,
      Point(updateOffset.dx, updateOffset.dy),
    );
  }
}

class PolyEle extends DrawableSketchElement {
  PolyEle(
    this.points,
    super.color,
    super.lineType,
    super.strokeWidth, {
    this.closed = false,
    this.activePointIndex,
    this.descriptions,
  });

  final IList<Point<double>> points;

  /// If start point is same as endpoint (that doesn't get added again to the points list)
  final bool closed;

  /// optional description
  final IList<String?>? descriptions;

  /// Contains the index of the point being updated
  int? activePointIndex;

  @override
  SketchElement create(ui.Offset updateOffset) {
    // TODO: implement create
    throw UnimplementedError();
  }

  /// Move the starting point of the path to the first point of the [points]
  ///
  /// Then, draw out the line to each remaining points
  ///
  /// If [closed], close the path.
  void _createPolyPath(IList<Point<double>> points, Path path) {
    path.moveTo(points.first.x, points.first.y);
    points.forEach((p) => path.lineTo(p.x, p.y));
    // Close the path if poly is closed
    if (closed) path.close();
  }

  @override
  void draw(ui.Canvas canvas, ui.Size size, [ui.Color? activeColor]) {
    final currentColor = activeColor ?? color;
    final path = ui.Path();

    switch (lineType) {
      case LineType.dashed:
      case LineType.dotted:
        _createPolyPath(points, path);
        DashedPathPainter(
          originalPath: path,
          pathColor: currentColor,
          strokeWidth: strokeWidth,
          dashGapLength: strokeWidth * lineType.dashGapLengthFactor,
          dashLength: strokeWidth * lineType.dashLengthFactor,
        ).paint(canvas, size);
      case LineType.full:
        _createPolyPath(points, path);

        final ui.Paint paint = ui.Paint()
          ..color = currentColor
          ..strokeWidth = strokeWidth
          ..strokeCap = ui.StrokeCap.round
          ..style = ui.PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round;

        canvas.drawPath(path, paint);
      case LineType.arrowBetween:
      case LineType.arrowEnd:
      case LineType.arrowStart:
        final arrowSize = strokeWidth * _arrowScaleMultiplier;
        final startPoint = _reduceLineLength(points.first, points[1], arrowSize * 0.8).start;
        final endPoint = _reduceLineLength(points.last, points.reversed[1], arrowSize * 0.8).start;
        final adjustedStartPoint = lineType != LineType.arrowEnd ? startPoint : points.first;
        final adjustedEndPoint = lineType != LineType.arrowStart ? endPoint : points.last;
        final newPoints = points.replace(0, adjustedStartPoint).replace(points.length - 1, adjustedEndPoint);

        final linePaint = ui.Paint()
          ..color = currentColor
          ..strokeWidth = strokeWidth
          ..strokeCap = ui.StrokeCap.round
          ..style = ui.PaintingStyle.stroke;

        final ui.Paint arrowPaint = ui.Paint()
          ..color = currentColor
          ..strokeWidth = 1
          ..strokeCap = ui.StrokeCap.round;

        // Lay out the points for the polygon
        _createPolyPath(newPoints, path);

        // draw the poly lines path
        canvas.drawPath(path, linePaint);

        if (lineType == LineType.arrowBetween) {
          _drawArrowHead(
            paint: arrowPaint,
            canvas: canvas,
            arrowHeadPoint: points.first,
            arrowTailPoint: points[1],
            arrowSize: arrowSize,
          );
          _drawArrowHead(
            paint: arrowPaint,
            canvas: canvas,
            arrowHeadPoint: points.last,
            arrowTailPoint: points.reversed[1],
            arrowSize: arrowSize,
          );
        } else if (lineType == LineType.arrowStart || lineType == LineType.arrowEnd) {
          final isLineEnd = lineType == LineType.arrowEnd;

          _drawArrowHead(
            paint: arrowPaint,
            canvas: canvas,
            arrowHeadPoint: isLineEnd ? points.last : points.first,
            arrowTailPoint: isLineEnd ? points.reversed[1] : points[1],
            arrowSize: arrowSize,
          );
        }

        break;
    }

    if (activeColor != null) {
      _drawActiveElementPoints(canvas: canvas, color: activeColor);
    }
  }

  @override
  HitPointPoly? getHit(ui.Offset offset) {
    PolyHitType? polyHitType;
    final hitPoint = Point<double>(offset.dx, offset.dy);

    polyHitType = _hitTestForLinePoints(hitPoint);

    if (polyHitType != null) return HitPointPoly(this, offset, polyHitType);

    final lineHitEndPoints = _hitTestForPolyLine(hitPoint);

    if (lineHitEndPoints != null) polyHitType = PolyHitType.line;

    return polyHitType != null
        ? HitPointPoly(
            this,
            offset,
            polyHitType,
            lineHitEndPoints: lineHitEndPoints,
          )
        : null;
  }

  @override
  SketchElement update(ui.Offset updateOffset, HitPoint hitPoint) {
    if (hitPoint is! HitPointPoly) return this;

    switch (hitPoint.hitType) {
      case PolyHitType.start:
      case PolyHitType.midPoints:
      case PolyHitType.end:
        final activeIndex = activePointIndex ??
            points.indexWhere((element) =>
                element.distanceTo(Point<double>(hitPoint.hitOffset.dx, hitPoint.hitOffset.dy)) < touchToleranceRadius);

        if (activeIndex == -1) return this;

        final Point<double> newPoint = Point(updateOffset.dx, updateOffset.dy);
        final newPointList = points.replace(activeIndex, newPoint);

        return PolyEle(newPointList, color, lineType, strokeWidth, activePointIndex: activeIndex, closed: closed);

      case PolyHitType.line:
        final differenceVector = updateOffset - hitPoint.hitOffset;
        final originalElement = hitPoint.element as PolyEle;
        final originalPoints = originalElement.points;
        final movementPoint = Point(differenceVector.dx, differenceVector.dy);
        final updatedPoints = originalPoints.map((element) => element + movementPoint).toIList();

        return PolyEle(updatedPoints, color, lineType, strokeWidth, closed: closed);
    }
  }

  void _drawActiveElementPoints({required ui.Canvas canvas, required Color color}) {
    final activeElementEndPaint = Paint()..color = color.withOpacity(0.5);

    for (var point in points) {
      canvas.drawCircle(
        point.toOffset(),
        touchToleranceRadius,
        activeElementEndPaint,
      );
    }
  }

  /// Checks if polyline is hit
  PolyHitType? _hitTestForLinePoints(Point<double> hitPoint) {
    // Check if first/last point of poly was hit
    final endPointHitType = _getEndPointsHitType(points.first, points.last, hitPoint);

    if (endPointHitType != null) {
      return endPointHitType;
    } else if (points.any((element) => element.distanceTo(hitPoint) < touchToleranceRadius)) {
      return PolyHitType.midPoints;
    }

    return null;
  }

  /// Check if polyline was hit between lines.
  ///
  /// Returns a type of [EndPoints] which contains the start and end point of which the poly line was hit.
  EndPoints? _hitTestForPolyLine(Point<double> hitPoint) {
    Point<double>? previousPoint;

    for (var point in [...points, if (closed) points.first]) {
      if (previousPoint != null) {
        final start = Point<double>(previousPoint.x, previousPoint.y);
        final end = Point<double>(point.x, point.y);

        if (hitPoint.isBetweenPoints(start, end, touchTolerance)) {
          return (start: start, end: end);
        }
      }
      previousPoint = point;
    }

    return null;
  }

  /// Returns PolyHitType.start if startPoint is hit
  /// Returns PolyHitType.end if endPoint is hit
  /// else, return null
  PolyHitType? _getEndPointsHitType(Point<double> startPoint, Point<double> endPoint, Point<double> hitPoint) {
    final a = startPoint.distanceTo(hitPoint);
    final b = endPoint.distanceTo(hitPoint);
    final c = startPoint.distanceTo(endPoint);

    final startGotHit = (a < touchToleranceRadius || pow(b, 2) > pow(a, 2) + pow(c, 2)) && a < touchToleranceRadius;
    final endGotHit = (b < touchToleranceRadius || pow(a, 2) > pow(b, 2) + pow(c, 2)) && b < touchToleranceRadius;

    if (!startGotHit && !endGotHit) {
      return null;
    } else {
      return startGotHit ? PolyHitType.start : PolyHitType.end;
    }
  }
}

class OvalEle extends DrawableSketchElement {
  OvalEle(
    super.color,
    super.lineType,
    super.strokeWidth, {
    required this.points,
  });

  factory OvalEle.fromStartPointWithSize({
    required Offset startPoint,
    required Offset localPoint,
    required Color color,
    required LineType lineType,
    required double strokeWidth,
    double size = _defaultCircleSize,
  }) {
    final pointBX = localPoint.dx < startPoint.dx ? startPoint.dx - size : startPoint.dx + size;
    final pointCY = localPoint.dy < startPoint.dy ? startPoint.dy - size : startPoint.dy + size;

    return OvalEle(
      color,
      lineType,
      strokeWidth,
      points: QuadPoints(
        pointA: startPoint,
        pointB: Offset(pointBX, startPoint.dy),
        pointC: Offset(startPoint.dx, pointCY),
        pointD: Offset(pointBX, pointCY),
      ),
    );
  }

  final QuadPoints points;

  static const _defaultCircleSize = 150.0;

  List<Offset?> get midPoints =>
      points.lineEndPoints.map((e) => getMidPoint(e.start.toOffset(), e.end.toOffset())).toList();

  // If distance between two points is less than the sum size of 2 points, don't show midPoint
  Offset? getMidPoint(Offset point1, Offset point2) {
    final distance = point1.distanceTo(point2);
    final pointDiameter = touchToleranceRadius * 2;

    return (distance / 2) >= pointDiameter ? point1.centerFrom(point2) : null;
  }

  void _drawActiveElementPoints({required ui.Canvas canvas, required Color color}) {
    final activeElementInnerEndPaint = Paint()..color = color.withOpacity(0.8);
    final activeElementOuterEndPaint = Paint()..color = color.withOpacity(0.5);

    final allPoints = [...points.allPoints, ...midPoints.nonNulls];
    for (final point in allPoints) {
      canvas.drawCircle(
        point,
        10,
        activeElementInnerEndPaint,
      );

      canvas.drawCircle(
        point,
        touchToleranceRadius,
        activeElementOuterEndPaint,
      );
    }
  }

  int _getSelectedCornerPointIndex(Offset offset) =>
      points.allPoints.indexWhere((element) => element.distanceTo(offset) < touchToleranceRadius);

  int _getSelectedMidPointIndex(Offset offset) =>
      midPoints.indexWhere((element) => element != null && element.distanceTo(offset) < touchToleranceRadius);

  (OvalHitType hitType, int? selectedPointIndex)? _hitTestWithSelectedPoint(Offset offset) {
    final rect = Rect.fromPoints(points.pointA, points.pointD);

    if (isActive) {
      final selectedCornerPointIndex = _getSelectedCornerPointIndex(offset);
      if (selectedCornerPointIndex >= 0) return (OvalHitType.cornerPoint, selectedCornerPointIndex);

      final selectedMidPointIndex = _getSelectedMidPointIndex(offset);
      if (selectedMidPointIndex >= 0) return (OvalHitType.midPoint, selectedMidPointIndex);

      if (_isOutlineHit(offset)) return (OvalHitType.outline, null);
    }
    if (_isOvalHit(rect, offset)) return (OvalHitType.oval, null);

    return null;
  }

  /// Checks hit on oval from current [offset]
  /// Returns true if the offset is more than the inner distance from center and less than the outer distance from center
  bool _isOvalHit(Rect rect, Offset offset) {
    final center = Offset(rect.left + rect.width / 2, rect.top + rect.height / 2);

    // Radii for the inner ellipse plus stroke width
    // Calculate the distance from the point to the center relative to inner ellipse radii
    final innerRadiiX = rect.width / 2 - strokeWidth; // radius in x direction
    final innerRadiiY = rect.height / 2 - strokeWidth; // radius in y direction
    final innerDistanceX = (offset.dx - center.dx) / innerRadiiX;
    final innerDistanceY = (offset.dy - center.dy) / innerRadiiY;

    // Radii for the ellipse minus stroke width
    // Calculate the distance from the point to the center relative to ellipse radii
    final outerRadiiX = rect.width / 2 + strokeWidth; // radius in x direction
    final outerRadiiY = rect.height / 2 + strokeWidth; // radius in y direction
    final outerDistanceX = (offset.dx - center.dx) / outerRadiiX;
    final outerDistanceY = (offset.dy - center.dy) / outerRadiiY;

    final maxOutlineToCenter = pow(outerDistanceX, 2) + pow(outerDistanceY, 2);
    final minOutlineToCenter = pow(innerDistanceX, 2) + pow(innerDistanceY, 2);

    return minOutlineToCenter >= 1 && maxOutlineToCenter <= 1;
  }

  bool _isOutlineHit(Offset offset) => points.lineEndPoints.any((element) => offset.toPoint().isBetweenPoints(
        element.start,
        element.end,
        touchTolerance,
      ));

  @override
  void draw(ui.Canvas canvas, ui.Size size, [Color? activeColor]) {
    final rect = Rect.fromPoints(points.pointA, points.pointD);
    final path = Path();

    // Create a square Rect with adjusted width and height for a circle
    path.addOval(rect);

    switch (lineType) {
      case LineType.dashed:
      case LineType.dotted:
        DashedPathPainter(
          originalPath: path,
          pathColor: activeColor ?? color,
          strokeWidth: strokeWidth,
          dashGapLength: strokeWidth * lineType.dashGapLengthFactor,
          dashLength: strokeWidth * lineType.dashLengthFactor,
        ).paint(canvas, size);
        break;
      default:
        final paint = Paint()
          ..color = activeColor ?? color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;
        canvas.drawPath(path, paint);
    }

    if (activeColor != null) {
      path.addRect(rect);
      DashedPathPainter(
        originalPath: path,
        pathColor: activeColor,
        strokeWidth: 5,
        dashGapLength: 15,
        dashLength: 15,
      ).paint(canvas, size);

      _drawActiveElementPoints(canvas: canvas, color: activeColor);
    }
  }

  @override
  HitPointOval? getHit(ui.Offset offset) {
    final hitTypeWithSelectedPoint = _hitTestWithSelectedPoint(offset);

    if (hitTypeWithSelectedPoint == null) return null;

    return HitPointOval(
      this,
      offset,
      hitTypeWithSelectedPoint.$1,
      selectedPointIndex: hitTypeWithSelectedPoint.$2,
    );
  }

  @override
  SketchElement create(ui.Offset updateOffset) {
    // TODO: implement create
    throw UnimplementedError();
  }

  @override
  SketchElement update(ui.Offset updateOffset, HitPoint hitPoint) {
    if (hitPoint is! HitPointOval) return this;

    switch (hitPoint.hitType) {
      case OvalHitType.cornerPoint:
        final hitPointCircleElement = hitPoint.element as OvalEle;
        final selectedPointIndex = hitPoint.selectedPointIndex;

        if (selectedPointIndex == null) return this;

        final initialSelectedPoint = hitPointCircleElement.points.allPoints[selectedPointIndex];
        final anchorPoint = hitPointCircleElement.points.allPoints.firstWhereOrNull(
            (element) => element.dx != initialSelectedPoint.dx && element.dy != initialSelectedPoint.dy);

        // Don't do anything if there is no position adjustment for the selected point Or if anchor point is null
        if (initialSelectedPoint == updateOffset || anchorPoint == null) return this;

        // Get center point of the oval
        final centerPoint = Offset(
          points.allPoints.map((e) => e.dx).average,
          points.allPoints.map((e) => e.dy).average,
        );

        final diffX = updateOffset.dx - initialSelectedPoint.dx;
        final diffY = updateOffset.dy - initialSelectedPoint.dy;

        // Calculate the additional distance from the selected point to the current point
        final additionalDistance = sqrt((pow(diffX, 2) + pow(diffY, 2)));

        final centerToAnchor = centerPoint.distanceTo(anchorPoint);
        final centerToInitial = centerPoint.distanceTo(initialSelectedPoint);

        // Check if interaction is scaling up (moving outward from the selected point) or scaling down (moving inward)
        final isScalingUp = updateOffset.distanceTo(anchorPoint) > updateOffset.distanceTo(initialSelectedPoint)
            ? anchorPoint.distanceTo(initialSelectedPoint) <= anchorPoint.distanceTo(updateOffset)
            : centerToAnchor > centerToInitial;

        final initialDistanceFromAnchorPoint = anchorPoint.distanceTo(initialSelectedPoint);

        // Growth factor will decide if the new point would be scaled up or scaled down
        final growthFactor = isScalingUp
            ? ((initialDistanceFromAnchorPoint + additionalDistance) / initialDistanceFromAnchorPoint)
            : additionalDistance / initialDistanceFromAnchorPoint;

        final oppositePointX = isScalingUp ? anchorPoint.dx : initialSelectedPoint.dx;
        final sourcePointX = isScalingUp ? initialSelectedPoint.dx : anchorPoint.dx;

        final oppositePointY = isScalingUp ? anchorPoint.dy : initialSelectedPoint.dy;
        final sourcePointY = isScalingUp ? initialSelectedPoint.dy : anchorPoint.dy;

        // Calculate on new X and Y based on the growth factor, opposite point, and sourcePoint
        final newX = growthFactor * (sourcePointX - oppositePointX) + oppositePointX;
        final newY = growthFactor * (sourcePointY - oppositePointY) + oppositePointY;

        final currentSelectedPoint = points.allPoints[selectedPointIndex];

        // Update the selected point with the new one
        // Also update the points beside the selected point
        final updatedPoints = points.allPoints
            .map((currentPoint) {
              if (currentPoint == currentSelectedPoint) {
                return Offset(newX, newY);
              } else if (currentPoint.dx == currentSelectedPoint.dx) {
                return Offset(newX, currentPoint.dy);
              } else if (currentPoint.dy == currentSelectedPoint.dy) {
                return Offset(currentPoint.dx, newY);
              } else {
                return currentPoint;
              }
            })
            .nonNulls
            .toList();

        return OvalEle(
          color,
          lineType,
          strokeWidth,
          points: QuadPoints(
            pointA: updatedPoints[0],
            pointB: updatedPoints[1],
            pointC: updatedPoints[2],
            pointD: updatedPoints[3],
          ),
        );

      case OvalHitType.midPoint:
        final selectedPointIndex = hitPoint.selectedPointIndex;

        if (selectedPointIndex == null) return this;

        final selectedMidPoint = midPoints[selectedPointIndex];

        if (selectedMidPoint == null) return this;

        final updatedPoints = points.allPoints
            .map((currentPoint) {
              // Check if X should be updated
              if (selectedMidPoint.dx == currentPoint.dx && selectedMidPoint.dy != currentPoint.dy) {
                return Offset(updateOffset.dx, currentPoint.dy);
              }
              // Check if Y should be updated
              else if (selectedMidPoint.dy == currentPoint.dy && selectedMidPoint.dx != currentPoint.dx) {
                return Offset(currentPoint.dx, updateOffset.dy);
              } else {
                return currentPoint;
              }
            })
            .nonNulls
            .toList();

        return OvalEle(
          color,
          lineType,
          strokeWidth,
          points: QuadPoints(
            pointA: updatedPoints[0],
            pointB: updatedPoints[1],
            pointC: updatedPoints[2],
            pointD: updatedPoints[3],
          ),
        );
      case OvalHitType.outline:
      case OvalHitType.oval:
        final hitPointCircleElement = hitPoint.element as OvalEle;
        final initialTouchPoint = hitPoint.hitOffset;
        final initialPoints = hitPointCircleElement.points;

        final additionalX = updateOffset.dx - initialTouchPoint.dx;
        final additionalY = updateOffset.dy - initialTouchPoint.dy;

        final updatedPoints =
            initialPoints.allPoints.map((e) => Offset(e.dx + additionalX, e.dy + additionalY)).toList();

        return OvalEle(
          color,
          lineType,
          strokeWidth,
          points: QuadPoints(
            pointA: updatedPoints[0],
            pointB: updatedPoints[1],
            pointC: updatedPoints[2],
            pointD: updatedPoints[3],
          ),
        );
    }
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

class QuadPoints {
  QuadPoints({
    required this.pointA,
    required this.pointB,
    required this.pointC,
    required this.pointD,
  });

  /// The first point where the user tapped on the screen
  final Offset pointA;

  /// The point opposite to [pointA]
  final Offset pointB;

  /// The point opposite to [pointD]
  final Offset pointC;

  /// The point diagonally opposite to [pointA]
  final Offset pointD;

  /// Returns the list of all the points
  List<Offset> get allPoints => [pointA, pointB, pointC, pointD];

  List<EndPoints> get lineEndPoints => [
        (start: pointA.toPoint(), end: pointB.toPoint()),
        (start: pointA.toPoint(), end: pointC.toPoint()),
        (start: pointB.toPoint(), end: pointD.toPoint()),
        (start: pointC.toPoint(), end: pointD.toPoint()),
      ];
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

class HitPointPoly extends HitPoint {
  HitPointPoly(
    super.element,
    super.hitOffset,
    this.hitType, {
    this.lineHitEndPoints,
  });

  final PolyHitType hitType;

  /// [lineHitEndPoints] has value when hit type is [PolyHitType.line]
  final EndPoints? lineHitEndPoints;
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

class HitPointOval extends HitPoint {
  HitPointOval(
    super.element,
    super.hitOffset,
    this.hitType, {
    this.selectedPointIndex,
  });

  final OvalHitType hitType;

  final int? selectedPointIndex;
}

enum OvalHitType { oval, outline, midPoint, cornerPoint }

enum LineHitType { start, end, line }

enum PolyHitType { start, end, line, midPoints }

extension Editable on SketchElement {
  /// Returns values for element that are editable
  /// In following order: color, lineType, strokeWidth
  (Color?, LineType?, double?) getEditableValues() {
    final SketchElement element = this;
    switch (element) {
      case DrawableSketchElement():
        return (element.color, element.lineType, element.strokeWidth);
      case _:
        return (null, null, null);
    }
  }
}
