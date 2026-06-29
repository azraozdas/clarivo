import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/visual_chart_trend.dart';

/// Shared sparkline painter — index 0 left, last index right, one line/fill/dot.
class ClarivoSparklinePainter extends CustomPainter {
  final List<double> values;
  final VisualChartTrend trend;
  final double strokeWidth;
  final bool showEndDot;
  final bool showFill;
  final bool showGrid;
  final double endDotRadius;
  final double padH;
  final double padTop;
  final double padBottom;

  const ClarivoSparklinePainter({
    required this.values,
    required this.trend,
    this.strokeWidth = 2.0,
    this.showEndDot = true,
    this.showFill = true,
    this.showGrid = false,
    this.endDotRadius = 3.5,
    this.padH = 0.02,
    this.padTop = 0.10,
    this.padBottom = 0.06,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final values = VisualChartTrend.cleanValues(this.values);
    if (values.length < 2 || size.width <= 1 || size.height <= 1) return;

    final plotLeft = size.width * padH;
    final plotRight = size.width * (1 - padH);
    final plotTop = size.height * padTop;
    final plotBottom = size.height * (1 - padBottom);
    final plotW = plotRight - plotLeft;
    final plotH = plotBottom - plotTop;
    if (plotW <= 1 || plotH <= 1) return;

    if (showGrid) {
      final gridPaint = Paint()
        ..color = kBorder.withValues(alpha: 0.35)
        ..strokeWidth = 1;
      for (int i = 1; i <= 3; i++) {
        final y = plotTop + plotH * i / 4;
        canvas.drawLine(
          Offset(plotLeft, y),
          Offset(plotRight, y),
          gridPaint,
        );
      }
    }

    final minVal = values.reduce(math.min);
    final maxVal = values.reduce(math.max);
    final range = maxVal - minVal;
    final n = values.length;

    final points = List.generate(n, (i) {
      final x = plotLeft + plotW * i / (n - 1);
      final norm = range > 0 ? 1.0 - (values[i] - minVal) / range : 0.5;
      final y = plotTop + norm * plotH;
      return Offset(x, y);
    });

    final trend = VisualChartTrend.trendFromPlottedGeometry(
      values: values,
      previousY: points[points.length - 2].dy,
      lastY: points.last.dy,
    );
    final color = trend.color;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    if (showFill) {
      final fillPath = Path.from(path)
        ..lineTo(points.last.dx, plotBottom)
        ..lineTo(points.first.dx, plotBottom)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: showGrid ? 0.38 : 0.55),
              color.withValues(alpha: 0.04),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt
        ..strokeJoin = StrokeJoin.miter,
    );

    if (showEndDot) {
      canvas.drawCircle(
        points.last,
        endDotRadius,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ClarivoSparklinePainter old) =>
      old.values != values ||
      old.trend.isUp != trend.isUp ||
      old.trend.percent != trend.percent ||
      old.strokeWidth != strokeWidth ||
      old.showGrid != showGrid ||
      old.showFill != showFill ||
      old.showEndDot != showEndDot ||
      old.endDotRadius != endDotRadius ||
      old.padTop != padTop ||
      old.padBottom != padBottom;
}

/// Chart widget — color is computed inside the painter from plotted values.
class ClarivoSparklineChart extends StatelessWidget {
  final List<double> values;
  final double height;
  final double? width;
  final bool loading;
  final double strokeWidth;
  final bool showEndDot;
  final bool showFill;
  final bool showGrid;
  final double endDotRadius;
  final String emptyLabel;
  final double padTop;
  final double padBottom;

  /// Labels next to the chart must use this with the same [values] list.
  static VisualChartTrend trendOf(List<double> values) =>
      VisualChartTrend.trendFromVisualValues(values);

  const ClarivoSparklineChart({
    super.key,
    required this.values,
    required this.height,
    this.width,
    this.loading = false,
    this.strokeWidth = 2.0,
    this.showEndDot = true,
    this.showFill = true,
    this.showGrid = false,
    this.endDotRadius = 3.5,
    this.emptyLabel = 'Chart unavailable',
    this.padTop = 0.10,
    this.padBottom = 0.06,
  });

  const ClarivoSparklineChart.main({
    super.key,
    required this.values,
    required this.height,
    this.width,
    this.loading = false,
    this.emptyLabel = 'Chart unavailable',
  })  : strokeWidth = 2.8,
        showEndDot = true,
        showFill = true,
        showGrid = true,
        endDotRadius = 4.5,
        padTop = 0.12,
        padBottom = 0.08;

  const ClarivoSparklineChart.mini({
    super.key,
    required this.values,
    required this.height,
    this.width,
    this.loading = false,
    this.emptyLabel = 'Chart unavailable',
  })  : strokeWidth = 1.8,
        showEndDot = true,
        showFill = true,
        showGrid = false,
        endDotRadius = 2.5,
        padTop = 0.14,
        padBottom = 0.08;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (loading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: kAccent,
            strokeWidth: 2,
          ),
        ),
      );
    }

    final plotted = VisualChartTrend.cleanValues(values);
    if (plotted.length < 2) {
      return Center(
        child: Text(
          emptyLabel,
          style: const TextStyle(color: kTextMuted, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      );
    }

    final trend = VisualChartTrend.trendFromVisualValues(plotted);

    return CustomPaint(
      painter: ClarivoSparklinePainter(
        values: plotted,
        trend: trend,
        strokeWidth: strokeWidth,
        showEndDot: showEndDot,
        showFill: showFill,
        showGrid: showGrid,
        endDotRadius: endDotRadius,
        padTop: padTop,
        padBottom: padBottom,
      ),
      child: const SizedBox.expand(),
    );
  }
}
