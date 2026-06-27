import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Chart color, arrow, and % follow the visible endpoint move:
/// last plotted value vs the point before it (the segment you see at the right).
class VisualChartTrend {
  final bool isUp;
  final double percent;
  final Color color;
  final String arrow;
  final String formattedPercent;
  final double? firstValue;
  final double? lastValue;
  final bool hasTrend;

  const VisualChartTrend({
    required this.isUp,
    required this.percent,
    required this.color,
    required this.arrow,
    required this.formattedPercent,
    required this.hasTrend,
    this.firstValue,
    this.lastValue,
  });

  static List<double> cleanValues(List<double> values) =>
      values.where((v) => v.isFinite).toList();

  factory VisualChartTrend.neutral() => const VisualChartTrend(
        isUp: true,
        percent: 0,
        color: kTextMuted,
        arrow: '',
        formattedPercent: '--',
        hasTrend: false,
      );

  /// Uses the terminal segment (second-to-last → last) — matches the visible
  /// direction at the endpoint dot on the right side of the chart.
  static VisualChartTrend trendFromVisualValues(List<double> values) {
    final clean = cleanValues(values);

    if (clean.length < 2) {
      return VisualChartTrend.neutral();
    }

    final previous = clean[clean.length - 2];
    final last = clean.last;

    if (previous == 0 || !previous.isFinite || !last.isFinite) {
      return VisualChartTrend.neutral();
    }

    final percent = ((last - previous) / previous.abs()) * 100;
    if (!percent.isFinite) {
      return VisualChartTrend.neutral();
    }

    final isUp = last >= previous;

    return VisualChartTrend(
      isUp: isUp,
      percent: percent,
      color: isUp ? kPositive : kNegative,
      arrow: isUp ? '↑' : '↓',
      formattedPercent:
          '${isUp ? '+' : ''}${percent.toStringAsFixed(1)}%',
      hasTrend: true,
      firstValue: previous,
      lastValue: last,
    );
  }

  /// Painter: same rule using canvas Y of the last segment.
  static VisualChartTrend trendFromPlottedGeometry({
    required List<double> values,
    required double previousY,
    required double lastY,
  }) {
    final valueTrend = trendFromVisualValues(values);
    if (!valueTrend.hasTrend) return valueTrend;

    final visualUp = lastY < previousY;
    if (visualUp == valueTrend.isUp) return valueTrend;

    return VisualChartTrend(
      isUp: visualUp,
      percent: valueTrend.percent,
      color: visualUp ? kPositive : kNegative,
      arrow: visualUp ? '↑' : '↓',
      formattedPercent: valueTrend.formattedPercent,
      hasTrend: true,
      firstValue: valueTrend.firstValue,
      lastValue: valueTrend.lastValue,
    );
  }

  IconData? get arrowIcon {
    if (!hasTrend) return null;
    return isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
  }
}
