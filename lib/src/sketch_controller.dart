import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';

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
    this.magnifierScale = 1.5,
    this.magnifierSize = 100,
    this.magnifierBorderWidth = 3.0,
    this.magnifierColor = Colors.grey,
    this.gridLinesColor = Colors.grey,
    this.onEditText,
    Uint8List? backgroundImageBytes,
    LineType? lineType,
    Color? color,
    SketchMode? sketchMode,
    double? strokeWidth,
    bool? isGridLinesEnabled,
  })  : _history = Queue<IList<SketchElement>>.of(<IList<SketchElement>>[elements]),
        _sketchMode = sketchMode ?? SketchMode.edit,
        _lineType = lineType ?? LineType.full,
        _color = color ?? Colors.black,
        _strokeWidth = strokeWidth ?? 10,
        _backgroundImageBytes = backgroundImageBytes,
        _isGridLinesEnabled = isGridLinesEnabled ?? false;

  // ignore: unused_field
  Queue<IList<SketchElement>> _history;

  IList<SketchElement> elements;

  Future<String?> Function(String? text)? onEditText;

  SketchElement? _activeElement;
  HitPoint? hitPoint;

  SketchMode _sketchMode;

  Color _color;
  LineType _lineType;
  double _strokeWidth;
  bool _isGridLinesEnabled = false;
  final Color selectionColor;
  final Color gridLinesColor;

  Uint8List? _backgroundImageBytes;
  Size? _initialAspectRatio;

  // magnifier properties
  final double magnifierScale;
  final double magnifierSize;
  final double magnifierBorderWidth;
  final Color magnifierColor;

  SketchElement? get activeElement => _activeElement;

  SketchMode get sketchMode => _sketchMode;

  Color get color => activeElementColor ?? _color;

  LineType get lineType => activeElementLineType ?? _lineType;

  double get strokeWidth => activeElementStrokeWidth ?? _strokeWidth;

  bool get isGridLinesEnabled => _isGridLinesEnabled;

  Size? get initialAspectRatio => _initialAspectRatio;

  Uint8List? get backgroundImageBytes => _backgroundImageBytes;

  /// Returns the color of the active/selected element if there is one
  Color? get activeElementColor {
    final element = _activeElement;
    if (element == null) return null;
    return element.getEditableValues().$1;
  }

  /// Returns the lineType of the active/selected element if there is one
  LineType? get activeElementLineType {
    final element = _activeElement;
    if (element == null) return null;
    return element.getEditableValues().$2;
  }

  /// Returns the strokeWidth of the active/selected element if there is one
  double? get activeElementStrokeWidth {
    final element = _activeElement;
    if (element == null) return null;
    return element.getEditableValues().$3;
  }

  set sketchMode(SketchMode sketchMode) {
    // prevent selection throughout the sketch modes
    deactivateActiveElement();
    _sketchMode = sketchMode;
  }

  /// Sets color for activeElement or, in case no
  /// active element is selected, as default color
  set color(Color color) {
    final element = _activeElement;
    if (element == null) {
      // set default color
      _color = color;
    } else {
      // set active element color
      switch (element) {
        case LineEle():
          _activeElement = LineEle(
            element.start,
            element.end,
            color,
            element.lineType,
            element.strokeWidth,
          );
        case PathEle():
          _activeElement = PathEle(
            element.points,
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
    final element = _activeElement;
    if (element == null) {
      // set default lineType
      _lineType = lineType;
    } else {
      // set active lineType
      switch (element) {
        case LineEle():
          _activeElement = LineEle(
            element.start,
            element.end,
            element.color,
            lineType,
            element.strokeWidth,
          );
        case PathEle():
          _activeElement = PathEle(
            element.points,
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
    final element = _activeElement;
    if (element == null) {
      // set default lineType
      _strokeWidth = strokeWidth;
    } else {
      // set active lineType
      switch (element) {
        case LineEle():
          _activeElement = LineEle(
            element.start,
            element.end,
            element.color,
            element.lineType,
            strokeWidth,
          );
        case PathEle():
          _activeElement = PathEle(
            element.points,
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

  /// Set the boolean value to determine if grid lines should be enabled
  set isGridLinesEnabled(bool enabled) {
    _isGridLinesEnabled = enabled;
    notifyListeners();
  }

  /// Set the initial aspect ratio for the sketch area to be able
  /// to scale the sketch correctly when the aspect ratio changes
  set initialAspectRatio(Size? initialAspectRatio) {
    if (_initialAspectRatio != null) return;
    _initialAspectRatio = initialAspectRatio;
    notifyListeners();
  }

  /// Set the background image for the sketch area
  set backgroundImageBytes(Uint8List? backgroundImageBytes) {
    _backgroundImageBytes = backgroundImageBytes;
    notifyListeners();
  }

  void undo() {
    if (_history.isEmpty) return;
    deactivateActiveElement();
    _history.removeLast();
    elements = _history.last;
    notifyListeners();
  }

  bool get undoPossible => _history.length > 1;

  bool get deletePossible => _activeElement != null;

  /// Add all elements (even the active element) to history
  void _addChangeToHistory() {
    // add activeElement to all elements
    final element = _activeElement;
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
  void deactivateActiveElement() {
    final element = _activeElement;
    if (element != null) {
      elements = elements.add(element);
      _activeElement = null;
      notifyListeners();
    }
  }

  void deleteActiveElement() {
    _activeElement = null;
    _addChangeToHistory();
    notifyListeners();
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
  Point<double> _findNearestPointOnLine(Point<double> p1, Point<double> p2, Offset targetPoint) {
    // Calculate the vector from point p1 to point p2
    Point<double> lineVector = Point<double>(p2.x - p1.x, p2.y - p1.y);

    // Calculate the vector from point p1 to the target point
    Point<double> targetVector = Point<double>(targetPoint.dx - p1.x, targetPoint.dy - p1.y);

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
      return p1;
    } else if (t > 1) {
      return p2;
    } else {
      // Calculate the nearest point on the line
      double nearestX = p1.x + t * lineVector.x;
      double nearestY = p1.y + t * lineVector.y;
      return Point<double>(nearestX, nearestY);
    }
  }

  /// Updates the active element with the new position and snaps
  /// the line to the nearest line if it is close enough
  void _updateMagneticLine(DragUpdateDetails details, SketchElement element, HitPointLine hitPointLine) {
    final touchedElement = elements.reversed.firstWhereOrNull((e) => e.getHit(details.localPosition) != null);
    if (touchedElement == null || touchedElement is! LineEle) {
      // update line end
      _activeElement = element.update(
        details.localPosition,
        hitPointLine,
      );
    } else {
      // calculate nearest point on line and snap the line end to that point
      final nearestPoint = _findNearestPointOnLine(
        touchedElement.start,
        touchedElement.end,
        details.localPosition,
      );
      _activeElement = element.update(
        Offset(nearestPoint.x, nearestPoint.y),
        hitPointLine,
      );
    }
    notifyListeners();
  }

  void onPanDown(DragDownDetails details) {
    deactivateActiveElement();
    switch (sketchMode) {
      case SketchMode.line:
        final startPoint = Point(details.localPosition.dx, details.localPosition.dy);
        _activeElement = LineEle(
          startPoint,
          startPoint + Point(1, 1),
          color,
          _lineType,
          _strokeWidth,
        );
        notifyListeners();
        break;
      case SketchMode.path:
        final startPoint = Point(details.localPosition.dx, details.localPosition.dy);
        _activeElement = PathEle(
          IList([startPoint]),
          color,
          _lineType,
          _strokeWidth,
        );
        notifyListeners();
        break;

      case SketchMode.text:
        break;
      case SketchMode.edit:
        final touchedElement = elements.reversed.firstWhereOrNull((e) => e.getHit(details.localPosition) != null);
        if (touchedElement == null) {
          // nothing touched
          return;
        }
        hitPoint = touchedElement.getHit(details.localPosition);

        // remove element from the elements list and hand it over to the active painter
        elements = elements.remove(touchedElement);
        _activeElement = touchedElement;
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
        final element = _activeElement;
        if (element == null) return;
        final hitPointLine = HitPointLine(
          element, // doesn't get used
          Offset.zero, // doesn't get used
          LineHitType.end,
        );
        _updateMagneticLine(details, element, hitPointLine);
        break;
      case SketchMode.path:
        final element = _activeElement;
        final isPathElement = element is PathEle;
        if (element == null || !isPathElement) return;

        final currentPoint = Point(details.localPosition.dx, details.localPosition.dy);
        _activeElement = PathEle(
          IList([
            ...element.points,
            currentPoint,
          ]),
          element.color,
          element.lineType,
          element.strokeWidth,
        );

        notifyListeners();
        break;
      case SketchMode.text:
      case SketchMode.edit:
        final element = _activeElement;
        final localHitPoint = hitPoint;

        if (element == null) return;
        if (localHitPoint == null) return;

        switch (element) {
          case LineEle():
            if (localHitPoint is HitPointLine) {
              _updateMagneticLine(details, element, localHitPoint);
            }
          case PathEle():
            if (localHitPoint is HitPointPath) {
              _activeElement = element.update(details.localPosition, localHitPoint);
              notifyListeners();
            }
          case TextEle():
            _activeElement = element.update(
              details.localPosition,
              localHitPoint,
            );
            notifyListeners();
            break;
          case _:
        }
    }
  }

  void onPanEnd(DragEndDetails details) {
    switch (sketchMode) {
      case SketchMode.line:
        deactivateActiveElement();
        break;
      case SketchMode.path:
      case SketchMode.text:
        // deselect painted element in non-edit mode after painting is done
        deactivateActiveElement();
      case SketchMode.edit:
    }
    _addChangeToHistory();
  }

  void onPanCancel() {
    switch (sketchMode) {
      case SketchMode.line:
      case SketchMode.path:
      case SketchMode.text:
      case SketchMode.edit:
    }
  }

  void onTapUp(TapUpDetails tapUpDetails) {
    switch (sketchMode) {
      // On tap up while text mode, call onEditText and pass a null value for the string value of the text since it is new
      case SketchMode.text:
        final position = Point(tapUpDetails.localPosition.dx, tapUpDetails.localPosition.dy);
        onEditText?.call(null).then((value) {
          if (value != null && value.isNotEmpty) {
            _activeElement = TextEle(value, color, position);
            notifyListeners();
          }
        });
      // On tap up while edit mode and selected element is text, call onEditText and pass the text element's value
      case SketchMode.edit:
        final element = _activeElement;
        final localHitPoint = hitPoint;

        if (element == null) return;
        if (localHitPoint == null) return;

        switch (element) {
          case TextEle():
            final position = Point(tapUpDetails.localPosition.dx, tapUpDetails.localPosition.dy);
            onEditText?.call(element.text).then((value) {
              if (value != null && value.isNotEmpty) {
                _activeElement = TextEle(value, color, position);
                notifyListeners();
              }
            });
          case _:
            break;
        }
      case _:
        break;
    }
    _addChangeToHistory();
  }
}
