import 'dart:math';

import 'package:flutter/material.dart';

extension BuildContextExt on BuildContext {
  bool get isAndroid => Theme.of(this).platform == TargetPlatform.android;
}

extension PointExt<T extends double> on Point<T> {
  Offset toOffset() => Offset(this.x, this.y);

  bool isBetweenPoints(Point<double> point1, Point<double> point2, double tolerance) {
    final nearestPoint = this.toOffset().findNearestPointOnLine(point1, point2);
    final distanceToLine = this.toOffset().distanceTo(nearestPoint);

    return distanceToLine <= tolerance;
  }
}

extension OffsetExt on Offset {
  Point<double> toPoint() => Point<double>(this.dx, this.dy);

  /// Returns the distance of the current offset to the [other] offset
  double distanceTo(Offset other) {
    var x = dx - other.dx;
    var y = dy - other.dy;
    return sqrt(x * x + y * y);
  }

  /// Returns the offset between the current point and the [point] provider
  Offset centerFrom(Offset point) {
    double centerX = (dx + point.dx) / 2;
    double centerY = (dy + point.dy) / 2;
    return Offset(centerX, centerY);
  }

  /// Finds the nearest point on a line defined by two points (p1 and p2)
  /// from a given target point.
  ///
  /// The function calculates the nearest point on the line passing through p1 and p2
  /// from the target point. It returns the coordinates of the nearest point as a
  /// [Point<double>] object.
  ///
  /// The function takes three parameters:
  /// - [p1]: The first point defining the line.
  /// - [p2]: The second point defining the line.
  /// - [targetPoint]: The point for which we want to find the nearest point on the line.
  ///
  /// The function returns a [Point<double>] object representing the nearest point on
  /// the line from the [targetPoint].
  Offset findNearestPointOnLine(Point<double> p1, Point<double> p2) {
    // Calculate the vector from point p1 to point p2
    Point<double> lineVector = Point<double>(p2.x - p1.x, p2.y - p1.y);

    // Calculate the vector from point p1 to the target point
    Point<double> targetVector = Point<double>(dx - p1.x, dy - p1.y);

    // Calculate the dot product
    double dotProduct = lineVector.x * targetVector.x + lineVector.y * targetVector.y;

    // Calculate the squared length of the line vector
    double lineLengthSquared = lineVector.x * lineVector.x + lineVector.y * lineVector.y;

    // Calculate the parameter 't' to find the nearest point on the line
    double t = dotProduct / lineLengthSquared;

    // If t < 0, the nearest point is before p1 on the line
    // If t > 1, the nearest point is after p2 on the line
    // Otherwise, the nearest point is between p1 and p2 on the line
    if (t < 0) {
      return p1.toOffset();
    } else if (t > 1) {
      return p2.toOffset();
    } else {
      // Calculate the nearest point on the line
      double nearestX = p1.x + t * lineVector.x;
      double nearestY = p1.y + t * lineVector.y;
      return Offset(nearestX, nearestY);
    }
  }
}
