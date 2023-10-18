import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class SketcherGestureRecognizer extends OneSequenceGestureRecognizer {
  int? _currentPointerId;

  SketcherGestureRecognizer({
    Object? debugOwner,
    PointerDeviceKind? kind,
  }) : super(debugOwner: debugOwner);

  @override
  void addPointer(PointerDownEvent event) {
    if (_currentPointerId == null) {
      // If there is no pointer being tracked, we track it here
      _currentPointerId = event.pointer;

      startTrackingPointer(event.pointer);
      resolve(GestureDisposition.accepted);
    } else {
      debugPrint('Two finger detected');

      /// Intention is to give back the gesture to the interactive viewer outside, but that does not happen currently.
      stopTrackingPointer(_currentPointerId!);
      stopTrackingPointer(event.pointer);
      resolve(GestureDisposition.rejected);
      _currentPointerId = null;
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    /// If all goes well with the handling of one/two finger taps, we handle the different events here if possible (update, tapUp, etc)
    if (event.pointer == _currentPointerId) {
      if (event is PointerUpEvent) {
        stopTrackingPointer(event.pointer);
        _currentPointerId = null;
      }
    }
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    // Add the allowed pointer and track it.
    startTrackingPointer(event.pointer);
  }

  @override
  String get debugDescription => 'SketcherGestureRecognizer';

  @override
  void didStopTrackingLastPointer(int pointer) => _currentPointerId = null;
}
