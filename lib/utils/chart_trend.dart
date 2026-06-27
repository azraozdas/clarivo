import 'dart:math' as math;



import 'package:flutter/material.dart';



import '../theme/app_colors.dart';



/// Chart trend + color — line, fill, and end dot all use full-period trend.

class ChartTrend {

  static const double sparklineTopPad = 0.05;

  static const double sparklineHeightFactor = 0.88;

  static const double mainTopPad = 0.05;

  static const double mainHeightFactor = 0.90;



  static double dataTrend(List<double> points) {

    if (points.length < 2) return 0;

    return points.last - points.first;

  }



  static double lastSegmentTrend(List<double> points) {

    if (points.length < 2) return 0;

    return points.last - points[points.length - 2];

  }



  /// Percent change from first → last plotted point.

  static double trendPercent(List<double> points) {

    if (points.length < 2 || points.first == 0) return 0;

    return ((points.last - points.first) / points.first.abs()) * 100;

  }



  static bool dataTrendIsUp(List<double> points) {

    if (points.length < 2) return true;

    return points.last >= points.first;

  }



  static bool lastSegmentTrendIsUp(List<double> points) {

    if (points.length < 2) return true;

    return points.last >= points[points.length - 2];

  }



  /// Line, fill, and end dot — single color from first → last point.
  static Color chartColorFromPoints(List<double> points) {
    if (points.length < 2) return kPositive;
    final isUp = points.last >= points.first;
    return isUp ? kPositive : kNegative;
  }

  static Color endDotColorFromPoints(List<double> points) {
    return chartColorFromPoints(points);
  }



  static bool visualTrendIsUp(

    List<double> points, {

    double topPad = sparklineTopPad,

    double heightFactor = sparklineHeightFactor,

  }) {

    if (points.length < 2) return true;

    final firstY = _normalizedY(

      points.first,

      points,

      topPad: topPad,

      heightFactor: heightFactor,

    );

    final lastY = _normalizedY(

      points.last,

      points,

      topPad: topPad,

      heightFactor: heightFactor,

    );

    return lastY <= firstY;

  }



  static double _normalizedY(

    double value,

    List<double> points, {

    required double topPad,

    required double heightFactor,

  }) {

    final minVal = points.reduce(math.min);

    final maxVal = points.reduce(math.max);

    final range = maxVal - minVal;

    if (range <= 0) return topPad + heightFactor * 0.5;

    final norm = 1.0 - (value - minVal) / range;

    return topPad + norm * heightFactor;

  }

}


