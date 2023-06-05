import 'dart:math';
import 'dart:ui' as ui;

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:sketch/src/element_modifiers.dart';

@immutable
sealed class SketchElement with Drawable {}

class LineEle extends SketchElement {
  LineEle(this.start, this.end, this.color, this.lineType);

  final Point<double> start;
  final Point<double> end;
  final ui.Color color;
  final LineType lineType;

  @override
  void draw(ui.Canvas c, ui.Size size) {
    // TODO: implement draw
    _drawLine(canvas: c, start: start, end: end);
  }
}

class FreeEle extends SketchElement {
  FreeEle(this.points, this.color, this.lineType);

  final IList<Point<double>> points;
  final ui.Color color;
  final LineType lineType;

  @override
  void draw(ui.Canvas c, ui.Size size) {
    // TODO: implement draw
  }
  
}

class TextEle extends SketchElement {
  TextEle(this.text, this.color);
  final String text;
  final ui.Color color;

  @override
  void draw(ui.Canvas c, ui.Size size) {
// Create a TextSpan tree and pass it to the TextPainter constructor.
//
// Call layout to prepare the paragraph.
//
// Call paint as often as desired to paint the paragraph.
//
// Call dispose when the object will no longer be accessed to release native resources.
// For TextPainter objects that are used repeatedly and stored on a State or RenderObject, call dispose from State.dispose or RenderObject.dispose or similar.
// For TextPainter objects that are only used ephemerally, it is safe to immediately dispose them after the last call to methods or properties on the object.
    // TODO: implement draw
  }
}

mixin Drawable {
  void draw(ui.Canvas c, ui.Size size);
}

// TODO: move
void _drawLine(
    {required ui.Canvas canvas,
    required Point<double> start,
    required Point<double> end}) {
  final ui.Paint paint = ui.Paint()
    ..color = const ui.Color(0xFF000000)
    ..strokeWidth = 4.0
    ..strokeCap = ui.StrokeCap.round
    ..style = ui.PaintingStyle.stroke;

  canvas.drawLine(
    ui.Offset(start.x, start.y),
    ui.Offset(end.x, end.y),
    paint,
  );
}

// void _drawLineWithText({@required Canvas canvas, @required PaintColor color, @required PaintPosition startPoint, @required PaintPosition endPoint, @required String description, isOutline = false}) {
//   final p = ui.Paint()
//     ..color = ui.Color(color.colorValue)
//     ..strokeWidth = 4.0
//     ..strokeCap = ui.StrokeCap.round
//     ..style = ui.PaintingStyle.stroke;
//
//   final x = (startPoint.x + endPoint.x) / 2;
//   final y = (startPoint.y + endPoint.y) / 2;
//   var r = math.atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x);
//   if (r < -math.pi / 2) {
//     r += math.pi;
//   }
//   if (r > math.pi / 2) {
//     r -= math.pi;
//   }
//   canvas
//     ..drawLine(
//       ui.Offset(startPoint.x, startPoint.y),
//       ui.Offset(endPoint.x, endPoint.y),
//       p,
//     )
//     ..save()
//     ..translate(x, y)
//     ..rotate(r);
//
//   final span = m.TextSpan(
//     style: m.TextStyle(
//       color: m.Colors.black,
//       decorationColor: m.Colors.red,
//     ),
//     text: description.isEmpty ? null : isOutline ? '$description m' : description,
//   );
//
//   final painter = m.TextPainter(
//       text: span,
//       textAlign: m.TextAlign.left,
//       textDirection: m.TextDirection.ltr)
//     ..layout();
//
//   final paint = ui.Paint()
//     ..color = m.Colors.white.withOpacity(0.5);
//
//   final w = painter.width;
//   if (description.isNotEmpty) {
//     final rect = Offset(-(w + 5) / 2, 2.0) & Size(w + 5, 15.0);
//     canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(3.0)), paint);
//
// //    final rrect = RRect.fromLTRBR(-(w + 3) / 2, 2.0, w + 3, painter.height, Radius.circular(2.0));
// //    canvas.drawRRect(rrect, paint);
//   }
//   painter.paint(canvas, m.Offset(-w / 2, 0.0));
//
//   canvas.restore();
// }
