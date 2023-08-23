import 'dart:html';
import 'dart:ui';

extension PointExt<T extends double> on Point<T> {
  Offset toOffset() => Offset(this.x, this.y);
}

extension OffsetExt on Offset {
  Point<double> toPoint() => Point<double>(this.dx, this.dy);
}
