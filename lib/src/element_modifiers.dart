enum LineType {
  full,
  dashed,
  dotted,
  arrowStart,
  arrowEnd,
  arrowBetween,
}

extension LineTypeExt on LineType {
  double get dashGapLengthFactor => switch (this) {
        LineType.dashed => 2.0,
        LineType.dotted => 1.0,
        _ => 0.0,
      };

  double get dashLengthFactor => switch (this) {
        LineType.dashed => 4.0,
        LineType.dotted => 1.0,
        _ => 0.0,
      };
}
