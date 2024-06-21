import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:sketch/src/element_modifiers.dart';
import 'package:sketch/src/elements.dart';
import 'package:sketch/src/extensions.dart';

enum SketchMode {
  line,
  path,
  text,
  edit,
}

/// Max number of rows for the auto added text elements
const _maxAutoAddTextLength = 8;

class SketchController extends ChangeNotifier {
  SketchController({
    this.elements = const IListConst([]),
    this.selectionColor = Colors.orange,
    this.magnifierScale = 1.5,
    this.magnifierSize = 150,
    this.magnifierBorderWidth = 3.0,
    this.magnifierColor = Colors.grey,
    this.gridLinesColor = Colors.grey,
    this.onEditText,
    this.transformationController,
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

  TransformationController? transformationController;

  Future<String?> Function(String? text)? onEditText;

  SketchElement? _activeElement;
  HitPoint? hitPoint;

  /// The initial touchPoint on the sketch canvas
  Offset? _initialTouchPoint;

  SketchMode _sketchMode;

  Color _color;
  LineType _lineType;
  double _strokeWidth;
  bool _isGridLinesEnabled = false;

  final Color selectionColor;
  final Color gridLinesColor;

  Uint8List? _backgroundImageBytes;
  Size? _initialAspectRatio;

  // Returns true onLongPressStart if there is a touched element.
  // This will be the basis if the [onLongPressMoveUpdate] should trigger edit mode or not
  // This is set to false [onLongPressEnd]
  bool _isLongPressEdit = false;

  // magnifier properties
  final double magnifierScale;
  final double magnifierSize;
  final double magnifierBorderWidth;
  final Color magnifierColor;

  bool isZooming = false;
  final maxScale = 3.0;
  final minScale = 1.0;

  double baseScaleFactor = 1.0;
  double _scaleFactor = 1.0;
  double get scaleFactor => _scaleFactor;

  void zoomOut() => transformationController?.value = Matrix4.diagonal3Values(1.0, 1.0, 1.0);

  set scaleFactor(double scale) {
    _scaleFactor = scale > maxScale
        ? maxScale
        : scale < minScale
            ? minScale
            : scale;
  }

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
        case PolyEle():
          _activeElement = PolyEle(
            element.points,
            color,
            element.lineType,
            element.strokeWidth,
            closed: element.closed,
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
        case PolyEle():
          final isClosed = element.closed;
          _activeElement = PolyEle(
            element.points,
            element.color,
            isClosed && lineType.isArrow ? element.lineType : lineType,
            element.strokeWidth,
            closed: isClosed,
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
        case PolyEle():
          _activeElement = PolyEle(
            element.points,
            element.color,
            element.lineType,
            strokeWidth,
            closed: element.closed,
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

    // TODO(Jayvee) : Remove when a better implementation for activePointIndex is applied
    if (element is PolyEle) element.activePointIndex = null;

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

  /// Add a [text] element to the sketch
  /// If [position] is null, position it on the center of the sketch
  /// Move the other automatically added texts unto the top of the new text until it reaches the [_maxAutoAddTextLength]
  /// Replace [_autoAddedTextElements] value with the new text and the repositioned texts
  void addTextElement(String? text, {Point<double>? position}) {
    deactivateActiveElement();
    if (text != null && text.isNotEmpty) {
      final center = (initialAspectRatio ?? Size(0, 0)) / 2;
      final textPosition = position ?? Point<double>(center.width, center.height);
      final textEle = TextEle(text, color, textPosition, hasComputedPosition: true);

      // Assign it as the current active element
      _activeElement = textEle;

      // Separate the autoAddedTextElements from all the other elements
      final separatedElementsRecord =
          elements.fold<({List<SketchElement> otherElements, List<TextEle> autoAddedTextElements})>(
        (otherElements: [], autoAddedTextElements: []),
        (previousValue, element) {
          if (element is! TextEle || !element.hasComputedPosition) {
            return previousValue..otherElements.add(element);
          } else {
            return previousValue..autoAddedTextElements.add(element);
          }
        },
      );

      // Reposition the autoAddedTextElements to be pushed on top of the newly added text element
      final repositionedAutoAddedText =
          _repositionAutoAddedTexts(center, separatedElementsRecord.autoAddedTextElements.reversedView);

      elements = IList([
        ...separatedElementsRecord.otherElements,
        ...repositionedAutoAddedText.reversedView,
      ]);

      notifyListeners();
      _addChangeToHistory();
    }
  }

  /// If there is a touched element upon long press, triggers the [_onEditStart]
  /// Else, proceed with [_onPressStart] handling for the current [sketchMode]
  ///
  /// Set the value of [_isLongPressEdit] to true if there is a touched element
  void onLongPressStart(Offset localPosition) {
    final touchedElement = elements.reversed.firstWhereOrNull((e) => e.getHit(localPosition) != null);

    _isLongPressEdit = touchedElement != null;

    if (touchedElement != null) {
      deactivateActiveElement();
      _onEditStart(localPosition);
    } else {
      _onPressStart(localPosition);
    }
  }

  /// If currently editing an element on long press, trigger [_onEditUpdate]
  /// Else, trigger the [_onMoveUpdate] to handle move update for the current [sketchMode]
  void onLongPressMoveUpdate(Offset localPosition) =>
      _isLongPressEdit ? _onEditUpdate(localPosition) : _onMoveUpdate(localPosition);

  /// If [_isLongPressEdit] is true, set it to false and trigger [_onEditEnd]
  /// Else, trigger [_onMoveEnd] to handle press end for the current [sketchMode]
  void onLongPressEnd(LongPressEndDetails details) {
    if (_isLongPressEdit) {
      _onEditEnd();
      _isLongPressEdit = false;

      deactivateActiveElement();
      _addChangeToHistory();
    } else {
      _onMoveEnd();
    }

    _clearInitialTouchPoint();
  }

  void onPanDown(DragDownDetails details) {
    switch (sketchMode) {
      case SketchMode.line:
      case SketchMode.path:
      case SketchMode.text:
      case SketchMode.edit:
    }
  }

  void onPanStart(Offset position) => _onPressStart(position);

  void onPanUpdate(Offset position) => _onMoveUpdate(position);

  void onPanEnd() => _onMoveEnd();

  void onPanCancel() {
    if (sketchMode != SketchMode.edit) {
      deactivateActiveElement();
      notifyListeners();
    }
  }

  /// Set the [_initialTouchPoint] onTapDown
  /// This is to ensure that if the onPanStart triggers, we still have the actual initial touch point to use instead of
  /// the onPanStart's [localPosition] (inaccurate start position since onPanStart triggers later on).
  void onTapDown(Offset localPosition) {
    _initialTouchPoint = localPosition;
  }

  void onTapUp(Offset localPosition) {
    deactivateActiveElement();
    _clearInitialTouchPoint();
    switch (sketchMode) {
      // On tap up while text mode, call onEditText and
      // either pass the selected text or null if none to create a new text
      case SketchMode.text:
        final touchedElement = elements.reversed.firstWhereOrNull((e) => e.getHit(localPosition) != null) as TextEle?;

        if (touchedElement != null) {
          elements = elements.remove(touchedElement);
          _activeElement = touchedElement;
        }

        onEditText?.call(touchedElement?.text).then((value) {
          if (value != null && value.isNotEmpty) {
            final position = Point(localPosition.dx, localPosition.dy);
            _activeElement = TextEle(value, color, position);
            notifyListeners();
            _addChangeToHistory();
          }
        });
      // On tap up while edit mode and selected element is text, call onEditText and pass the text element's value
      case SketchMode.edit:
      case SketchMode.line:
      case SketchMode.path:
        final touchedElement = elements.reversed.firstWhereOrNull((e) => e.getHit(localPosition) != null);
        if (touchedElement == null) return;

        elements = elements.remove(touchedElement);
        _activeElement = touchedElement;

        switch (touchedElement) {
          case TextEle():
            final position = Point(localPosition.dx, localPosition.dy);
            onEditText?.call(touchedElement.text).then((value) {
              if (value != null && value.isNotEmpty) {
                _activeElement = TextEle(value, color, position);
                notifyListeners();
                _addChangeToHistory();
              }
            });
          case _:
            _sketchMode = SketchMode.edit;
            break;
        }
    }
    notifyListeners();
  }

  /// Handles the initial interaction for [SketchMode.edit]
  ///
  /// Triggers an early return if there is no selected element
  ///
  /// Set the selected element as the [_activeElement] and remove it from the current list of [elements]
  void _onEditStart(Offset localPosition) {
    final touchedElement = elements.reversed.firstWhereOrNull((e) => e.getHit(localPosition) != null);
    if (touchedElement == null) {
      // nothing touched
      return;
    }
    hitPoint = touchedElement.getHit(localPosition);

    // remove element from the elements list and hand it over to the active painter
    elements = elements.remove(touchedElement);
    _activeElement = touchedElement;
    notifyListeners();
  }

  /// Update the [_activeElement] based on the hit point's [localPosition]
  void _onEditUpdate(Offset localPosition) {
    final element = _activeElement;
    final localHitPoint = hitPoint;

    if (element == null) return;
    if (localHitPoint == null) return;

    switch (element) {
      case LineEle():
        if (localHitPoint is HitPointLine) {
          final touchedElement = elements.reversed.firstWhereOrNull((e) => e.getHit(localPosition) != null);
          if (touchedElement is LineEle) {
            _updateMagneticLine(localPosition, element, localHitPoint, touchedElement);
          } else if (touchedElement is PolyEle) {
            _updateMagneticLineToPoly(localPosition, element, localHitPoint, touchedElement);
          } else {
            _activeElement = element.update(
              localPosition,
              localHitPoint,
            );
          }

          notifyListeners();
        }
      case PathEle():
        if (localHitPoint is HitPointPath) {
          _activeElement = element.update(localPosition, localHitPoint);
          notifyListeners();
        }
      case PolyEle():
        if (localHitPoint is HitPointPoly) {
          final touchedElement = elements.reversed.firstWhereOrNull((e) => e.getHit(localPosition) != null);

          /// Poly merging to itself
          if (touchedElement == null) {
            final activePointIndex = element.activePointIndex;
            final selectedPoint = activePointIndex != null ? element.points.get(activePointIndex, orElse: null) : null;
            final firstElement = element.points.first;
            final lastElement = element.points.last;

            // If there is no selected point, or if there are only 3 points, we only update the active Elements normally
            if (selectedPoint == null || element.points.length <= 3) {
              _activeElement = element.update(localPosition, localHitPoint);
            } else {
              // If start and end point meet within the toleranceRadius, snap it to each other and update activeElement
              final isStart = selectedPoint == element.points.first;
              final isEnd = selectedPoint == element.points.last;
              final localPoint = localPosition.toPoint();

              if ((isStart && localPoint.distanceTo(lastElement) < element.touchTolerance) ||
                  (isEnd && localPoint.distanceTo(firstElement) < element.touchTolerance)) {
                final updatedPoint = isEnd ? firstElement : lastElement;
                _activeElement = element.update(updatedPoint.toOffset(), localHitPoint) as PolyEle;
              } else {
                _activeElement = element.update(localPosition, localHitPoint);
              }
            }
          } else if (touchedElement is PolyEle) {
            _handlePolyToPolyMerging(element, touchedElement, localPosition, localHitPoint);
          } else if (touchedElement is LineEle) {
            _handlePolyToLineMerging(element, touchedElement, localPosition, localHitPoint);
          } else {
            _activeElement = element.update(localPosition, localHitPoint);
          }
          notifyListeners();
        }
      case TextEle():
        // If auto added text is modified, we don't consider it as automatically added anymore
        element.hasComputedPosition = false;
        _activeElement = element.update(
          localPosition,
          localHitPoint,
        );
        notifyListeners();
        break;
      default:
        break;
    }
  }

  /// Handles the ending interaction for [SketchMode.edit]
  void _onEditEnd() {
    final element = _activeElement;

    /// Handle merging of PolyEle on pan end
    if (element is PolyEle && !element.closed) {
      final touchedElement = elements.firstWhereOrNull((e) {
        if (e is PolyEle || e is LineEle) {
          final startPointHit = e.getHit(element.points.first.toOffset()) != null;
          final endPointHit = e.getHit(element.points.last.toOffset()) != null;
          return startPointHit || endPointHit;
        }
        return false;
      });

      IList<Point<double>>? newPoints;

      if (touchedElement is PolyEle && !touchedElement.closed) {
        final firstPointsMatched = touchedElement.points.first == element.points.first;
        final lastPointsMatched = touchedElement.points.last == element.points.last;

        if (firstPointsMatched || lastPointsMatched) {
          final reversedElementPoints = firstPointsMatched ? element.points.reversed : element.points;
          final reversedTouchedPoints = firstPointsMatched ? touchedElement.points : touchedElement.points.reversed;
          newPoints = IList([...reversedElementPoints, ...reversedTouchedPoints]);
        } else if (touchedElement.points.first == element.points.last) {
          newPoints = IList([...element.points, ...touchedElement.points]);
        } else if (touchedElement.points.last == element.points.first) {
          newPoints = IList([...touchedElement.points, ...element.points]);
        }
      } else if (touchedElement is LineEle) {
        final points = _onMergePolyAndLine(element, touchedElement);
        if (points != null) newPoints = points;
      }

      if (touchedElement != null && newPoints != null) elements = elements.remove(touchedElement);

      newPoints ??= element.points;
      final isClosed = newPoints.first == newPoints.last || element.closed;

      _activeElement = PolyEle(
        newPoints.removeDuplicates(),
        color,
        isClosed && lineType.isArrow ? LineType.full : lineType,
        strokeWidth,
        closed: isClosed,
      );
    } else if (element is LineEle) {
      final hitPointLine = HitPointLine(
        element, // doesn't get used
        Offset.zero, // doesn't get used
        LineHitType.end,
      );
      _checkMergeLine(element, hitPointLine);
    }
  }

  /// Handles the initial press for the current [sketchMode]
  void _onPressStart(Offset localPosition) {
    deactivateActiveElement();
    final startPoint = (_initialTouchPoint ?? localPosition).toPoint();
    switch (sketchMode) {
      case SketchMode.line:
        _activeElement = LineEle(
          startPoint,
          startPoint + Point<double>(1.0, 1.0),
          color,
          _lineType,
          _strokeWidth,
        );
        notifyListeners();
        break;
      case SketchMode.path:
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
        _onEditStart(startPoint.toOffset());
    }
  }

  /// Handle move update for the current [sketchMode]
  void _onMoveUpdate(Offset localPosition) {
    switch (sketchMode) {
      case SketchMode.line:
        final element = _activeElement;
        if (element == null) return;
        final hitPointLine = HitPointLine(
          element, // doesn't get used
          Offset.zero, // doesn't get used
          LineHitType.end,
        );

        final touchedElement = elements.firstWhereOrNull((e) => e.getHit(localPosition) != null);
        if (touchedElement is LineEle) {
          _updateMagneticLine(localPosition, element, hitPointLine, touchedElement);
        } else if (touchedElement is PolyEle) {
          _updateMagneticLineToPoly(localPosition, element as LineEle, hitPointLine, touchedElement);
        } else {
          _activeElement = element.update(
            localPosition,
            hitPointLine,
          );
        }
        notifyListeners();
        break;
      case SketchMode.path:
        final element = _activeElement;
        final isPathElement = element is PathEle;
        if (element == null || !isPathElement) return;

        final currentPoint = Point(localPosition.dx, localPosition.dy);
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
        _onEditUpdate(localPosition);
    }
  }

  /// Handles the end interaction after moving for the current [sketchMode]
  void _onMoveEnd() {
    switch (sketchMode) {
      case SketchMode.line:
        final element = _activeElement;
        if (element == null) return;
        final hitPointLine = HitPointLine(
          element, // doesn't get used
          Offset.zero, // doesn't get used
          LineHitType.end,
        );

        _checkMergeLine(element as LineEle, hitPointLine);

        deactivateActiveElement();
        break;
      case SketchMode.path:
      case SketchMode.text:
        // deselect painted element in non-edit mode after painting is done
        deactivateActiveElement();
      case SketchMode.edit:
        _onEditEnd();
    }

    _clearInitialTouchPoint();
    _addChangeToHistory();
  }

  void _clearInitialTouchPoint() {
    _initialTouchPoint = null;
  }

  /// Poly to Poly can only merge on their endpoints
  void _handlePolyToPolyMerging(PolyEle element, PolyEle touchedElement, Offset localPosition, HitPoint localHitPoint) {
    final hitPointLine = touchedElement.getHit(localPosition);
    if (hitPointLine == null) return;
    final hitType = hitPointLine.hitType;

    switch (hitType) {
      case PolyHitType.line:
        final start = hitPointLine.lineHitEndPoints?.start;
        final end = hitPointLine.lineHitEndPoints?.end;

        final newPosition =
            start != null && end != null ? localPosition.findNearestPointOnLine(start, end) : localPosition;

        _activeElement = element.update(newPosition, localHitPoint);
      case PolyHitType.midPoints:
        final nearestMidPoint = touchedElement.points
            .firstWhereOrNull((point) => point.distanceTo(localPosition.toPoint()) < element.touchTolerance);
        if (nearestMidPoint != null) {
          _activeElement = element.update(nearestMidPoint.toOffset(), hitPointLine);
        }
      case PolyHitType.start:
      case PolyHitType.end:
        final newPoint =
            hitPointLine.hitType == PolyHitType.start ? touchedElement.points.first : touchedElement.points.last;
        _activeElement = element.update(newPoint.toOffset(), localHitPoint) as PolyEle;
    }
  }

  void _handlePolyToLineMerging(
      PolyEle activePolyElement, LineEle lineElement, Offset localPosition, HitPoint localHitPoint) {
    final hitPointLine = lineElement.getHit(localPosition);
    if (hitPointLine == null) return;
    final hitType = hitPointLine.hitType;

    if (hitType == LineHitType.line) {
      final newPoint = localPosition.findNearestPointOnLine(lineElement.start, lineElement.end);
      _activeElement = activePolyElement.update(newPoint, localHitPoint);
    } else {
      final newPoint = hitPointLine.hitType == LineHitType.start ? lineElement.start : lineElement.end;
      _activeElement = activePolyElement.update(newPoint.toOffset(), localHitPoint) as PolyEle;
    }
  }

  List<Point<double>>? _onMergeTwoLines(
    Point<double> line1Start,
    Point<double> line1End,
    Point<double> line2Start,
    Point<double> line2End,
  ) {
    List<Point<double>>? createMergedList(Point<double> a, Point<double> b, Point<double> c) => [a, b, c];

    if (line1Start == line2Start) {
      return createMergedList(line2End, line1Start, line1End);
    } else if (line1End == line2End) {
      return createMergedList(line1Start, line2End, line2Start);
    } else if (line1Start == line2End) {
      return createMergedList(line1End, line1Start, line2Start);
    } else if (line2Start == line1End) {
      return createMergedList(line1Start, line2Start, line2End);
    }

    return null;
  }

  /// Reposition the current automatically added texts to the top of the center position
  /// This would put all the other texts on top of the newly added text
  /// If the list reaches [_maxAutoAddTextLength], the position of the last texts would be the same
  List<TextEle> _repositionAutoAddedTexts(Size center, List<TextEle> autoAddedElements) {
    final repositionedTexts = <TextEle>[];
    final centerHeight = center.height;
    final maximumYPosition = centerHeight - (_maxAutoAddTextLength * 40);

    for (var index = 0; index < autoAddedElements.length; index++) {
      final currentText = autoAddedElements[index];
      final newY = centerHeight - ((index + 1) * 40.0);
      final y = currentText.point.y == maximumYPosition ? maximumYPosition : newY;

      repositionedTexts.add(
        TextEle(
          currentText.text,
          currentText.color,
          Point(currentText.point.x, y),
          hasComputedPosition: currentText.hasComputedPosition,
        ),
      );
    }

    return repositionedTexts;
  }

  /// Upon drag update, snaps the point of a line to the nearest endpoint of a poly within the tolerance radius
  /// If the point of line goes on the midpoints/line, no snapping will happen
  void _updateMagneticLineToPoly(
      Offset localPosition, LineEle activeLineElement, HitPointLine hitPointLine, PolyEle polyElement) {
    final touchedPolyHitPoint = polyElement.getHit(localPosition) as HitPointPoly;
    final polyStartPoint = polyElement.points.first;
    final polyEndPoint = polyElement.points.last;

    switch (touchedPolyHitPoint.hitType) {
      case PolyHitType.line:
        final start = touchedPolyHitPoint.lineHitEndPoints?.start;
        final end = touchedPolyHitPoint.lineHitEndPoints?.end;

        final newPosition =
            start != null && end != null ? localPosition.findNearestPointOnLine(start, end) : localPosition;

        _activeElement = activeLineElement.update(newPosition, hitPointLine);

        break;
      case PolyHitType.midPoints:
        final nearestMidPoint = polyElement.points
            .firstWhereOrNull((point) => point.distanceTo(localPosition.toPoint()) < polyElement.touchTolerance);
        if (nearestMidPoint != null) {
          _activeElement = activeLineElement.update(nearestMidPoint.toOffset(), hitPointLine);
        }
      case PolyHitType.start:
        _activeElement = activeLineElement.update(polyStartPoint.toOffset(), hitPointLine);
      case PolyHitType.end:
        _activeElement = activeLineElement.update(polyEndPoint.toOffset(), hitPointLine);
        break;
    }
  }

  /// Updates the active element with the new position and snaps
  /// the line to the nearest line if it is close enough
  void _updateMagneticLine(Offset localPosition, SketchElement element, HitPointLine hitPointLine, LineEle lineEle) {
    final nearestPoint = localPosition.findNearestPointOnLine(
      lineEle.start,
      lineEle.end,
    );

    _activeElement = element.update(
      nearestPoint,
      hitPointLine,
    );
  }

  void _checkMergeLine(LineEle lineElement, HitPointLine hitPointLine) {
    final touchedElement =
        elements.reversed.where((element) => element is LineEle || element is PolyEle).firstWhereOrNull((e) {
      return e.getHit(lineElement.start.toOffset()) != null || e.getHit(lineElement.end.toOffset()) != null;
    });

    if (touchedElement is LineEle) {
      final points = _onMergeTwoLines(touchedElement.start, touchedElement.end, lineElement.start, lineElement.end);

      if (points != null) {
        elements = elements.removeAll([touchedElement, lineElement]);
        _activeElement = PolyEle(IList(points), color, lineType, strokeWidth);
      }
      notifyListeners();
    } else if (touchedElement is PolyEle && !touchedElement.closed) {
      final newPoints = _onMergePolyAndLine(touchedElement, lineElement);
      if (newPoints != null) {
        elements = elements.removeAll([touchedElement, lineElement]);
        _activeElement = PolyEle(newPoints, color, lineType, strokeWidth, closed: touchedElement.closed);
        notifyListeners();
      }
    }
  }

  IList<Point<double>>? _onMergePolyAndLine(PolyEle polyLine, LineEle line) {
    final activeElementPoints = [
      line.start,
      line.end,
    ];

    final polyStartPoint = polyLine.points.first;
    final polyEndPoint = polyLine.points.last;

    if (activeElementPoints.contains(polyStartPoint)) {
      final newPoint = line.start == polyStartPoint ? line.end : line.start;
      return IList([newPoint, ...polyLine.points]);
    } else if (activeElementPoints.contains(polyEndPoint)) {
      final newPoint = line.start == polyEndPoint ? line.end : line.start;
      return IList([...polyLine.points, newPoint]);
    } else {
      return null;
    }
  }
}
