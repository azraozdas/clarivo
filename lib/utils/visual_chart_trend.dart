import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Single source of truth for chart line, fill, dot, arrow, and % labels.
/// Trend follows the visible endpoint move: second-to-last → last value
/// (matches the slope you see at the right end of the drawn line).
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

  /// Endpoint segment of the exact values passed to the chart painter.
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

    final isUp = percent >= 0;

    return VisualChartTrend(
      isUp: isUp,
      percent: percent,
      color: isUp ? kPositive : kNegative,
      arrow: isUp ? '↑' : '↓',
      formattedPercent:
          '${isUp && percent > 0 ? '+' : ''}${percent.toStringAsFixed(1)}%',
      hasTrend: percent != 0,
      firstValue: previous,
      lastValue: last,
    );
  }

  /// Confirms canvas Y direction matches value trend (higher price = lower Y).
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
