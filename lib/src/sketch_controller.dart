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
    this.selectionColor = Colors.orange,
    LineType? lineType,
    Color? color,
    SketchMode? sketchMode,
    double? strokeWidth,
  })  : _history = Queue<IList<SketchElement>>.of(<IList<SketchElement>>[elements]),
        _sketchMode = sketchMode ?? SketchMode.edit,
        _lineType = lineType ?? LineType.full,
        _color = color ?? Colors.black,
        _strokeWidth = strokeWidth ?? 10;

  // ignore: unused_field
  Queue<IList<SketchElement>> _history;

  IList<SketchElement> elements;

  SketchElement? activeElement;
  HitPoint? hitPoint;

  SketchMode _sketchMode;

  Color _color;
  LineType _lineType;
  double _strokeWidth;
  final Color selectionColor;

  SketchMode get sketchMode => _sketchMode;

  Color get color => activeElementColor ?? _color;

  LineType get lineType => activeElementLineType ?? _lineType;

  double get strokeWidth => activeElementStrokeWidth ?? _strokeWidth;

  /// Returns the color of the active/selected element if there is one
  Color? get activeElementColor {
    final element = activeElement;
    if (element == null) return null;
    return element.getEditableValues().$1;
  }

  /// Returns the lineType of the active/selected element if there is one
  LineType? get activeElementLineType {
    final element = activeElement;
    if (element == null) return null;
    return element.getEditableValues().$2;
  }

  /// Returns the strokeWidth of the active/selected element if there is one
  double? get activeElementStrokeWidth {
    final element = activeElement;
    if (element == null) return null;
    return element.getEditableValues().$3;
  }

  set sketchMode(SketchMode sketchMode) {
    // prevent selection throughout the sketch modes
    _removeActiveElement();
    _sketchMode = sketchMode;
  }

  /// Sets color for activeElement or, in case no
  /// active element is selected, as default color
  set color(Color color) {
    final element = activeElement;
    if (element == null) {
      // set default color
      _color = color;
    } else {
      // set active element color
      switch (element) {
        case LineEle():
          activeElement = LineEle(
            element.start,
            element.end,
            color,
            element.lineType,
            element.strokeWidth,
          );
        case _:
      }
    }
    notifyListeners();
    _addChangeToHistory();
  }

  /// Sets lineType for activeElement or, in case no
  /// active element is selected, as default lineType
  set lineType(LineType lineType) {
    final element = activeElement;
    if (element == null) {
      // set default lineType
      _lineType = lineType;
    } else {
      // set active lineType
      switch (element) {
        case LineEle():
          activeElement = LineEle(
            element.start,
            element.end,
            element.color,
            lineType,
            element.strokeWidth,
          );
        case _:
      }
    }
    notifyListeners();
    _addChangeToHistory();
  }

  /// Sets strokeWidth for activeElement or, in case no
  /// active element is selected, as default lineType
  set strokeWidth(double strokeWidth) {
    final element = activeElement;
    if (element == null) {
      // set default lineType
      _strokeWidth = strokeWidth;
    } else {
      // set active lineType
      switch (element) {
        case LineEle():
          activeElement = LineEle(
            element.start,
            element.end,
            element.color,
            element.lineType,
            strokeWidth,
          );
        case _:
      }
    }
    notifyListeners();
    _addChangeToHistory();
  }

  void undo() {
    if (_history.isEmpty) return;
    _removeActiveElement();
    _history.removeLast();
    elements = _history.last;
    notifyListeners();
  }

  bool get undoPossible => _history.length > 1;

  /// Add all elements (even the active element) to history
  void _addChangeToHistory() {
    // add activeElement to all elements
    final element = activeElement;
    final allElements = element == null ? elements : elements.add(element);

    // save a history entry only if the current elements list differs from the last
    if (_history.last != allElements) {
      _history.add(allElements);
    }

    // keep history length at max. 5 steps
    if (_history.length > 6) _history.removeFirst();

    notifyListeners();
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
          _lineType,
          _strokeWidth,
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
        // deselect painted element in non-edit mode after painting is done
        _removeActiveElement();
        _addChangeToHistory();
      case SketchMode.edit:
        _addChangeToHistory();
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
