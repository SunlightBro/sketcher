import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:sketch/src/element_modifiers.dart';
import 'package:sketch/src/elements.dart';

enum SketchMode {
  line,
  path,
  text,
  edit,
}

class SketchController extends ChangeNotifier {
  SketchController({
    this.elements = const IListConst([]),
    this.strokeWidth = 10,
    this.activeElementColor = Colors.orange,
    this.color = Colors.black,
    this.lineType = LineType.full,
    SketchMode? sketchMode,
  })  : _history = Queue<IList<SketchElement>>.of(<IList<SketchElement>>[elements]),
        _sketchMode = sketchMode ?? SketchMode.edit;

  // ignore: unused_field
  Queue<IList<SketchElement>> _history;

  IList<SketchElement> elements;

  SketchElement? activeElement;
  HitPoint? hitPoint;

  SketchMode _sketchMode;

  Color color;
  LineType lineType;
  double strokeWidth;
  final Color activeElementColor;

  SketchMode get sketchMode => _sketchMode;

  set sketchMode(SketchMode sketchMode) {
    _removeActiveElement();
    _sketchMode = sketchMode;
  }

  /// Removes activeElement if it exists and moves it back to the elements list
  void _removeActiveElement() {
    final element = activeElement;
    if (element != null) {
      elements = elements.add(element);
      activeElement = null;
      notifyListeners();
    }
  }

  void onPanDown(DragDownDetails details) {
    _removeActiveElement();
    switch (sketchMode) {
      case SketchMode.line:
        final startPoint = Point(details.localPosition.dx, details.localPosition.dy);
        activeElement = LineEle(
          startPoint,
          startPoint + Point(1, 1),
          color,
          lineType,
          strokeWidth,
        );
        notifyListeners();
        break;
      case SketchMode.path:
      case SketchMode.text:
      case SketchMode.edit:
        final touchedElement = elements.reversed.firstWhereOrNull((e) => e.getHit(details.localPosition) != null);
        if (touchedElement == null) {
          print("Nothing touched");
          return;
        }
        hitPoint = touchedElement.getHit(details.localPosition);
        if (hitPoint is HitPointLine) {
          print("Success");
          //print(hitPoint?.hitType);
        }

        // remove element from the elements list and hand it over to the active painter
        elements = elements.remove(touchedElement);
        activeElement = touchedElement;
        notifyListeners();
    }
  }

  void onPanStart(DragStartDetails details) {
    switch (sketchMode) {
      case SketchMode.line:
      case SketchMode.path:
      case SketchMode.text:
      case SketchMode.edit:
    }
  }

  void onPanUpdate(DragUpdateDetails details) {
    switch (sketchMode) {
      case SketchMode.line:
        final element = activeElement;
        if (element == null) return;
        activeElement = element.update(
          details.localPosition,
          HitPointLine(
            element, // doesn't get used
            Offset.zero, // doesn't get used
            LineHitType.end,
          ),
        );
        notifyListeners();
        break;
      case SketchMode.path:
      case SketchMode.text:
      case SketchMode.edit:
        final element = activeElement;
        final HitPointLine? hitPointLine = hitPoint as HitPointLine?;
        if (element == null || hitPointLine == null) return;
        activeElement = element.update(
          details.localPosition,
          hitPointLine,
        );
        notifyListeners();
    }
  }

  void onPanEnd(DragEndDetails details) {
    switch (sketchMode) {
      case SketchMode.line:
      case SketchMode.path:
      case SketchMode.text:
      case SketchMode.edit:
    }
  }

  void onPanCancel() {
    switch (sketchMode) {
      case SketchMode.line:
      case SketchMode.path:
      case SketchMode.text:
      case SketchMode.edit:
    }
  }
}
