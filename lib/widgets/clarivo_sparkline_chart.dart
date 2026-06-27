import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/chart_trend.dart';

/// Shared sparkline painter — scales points to the full paint area.
class ClarivoSparklinePainter extends CustomPainter {
  final List<double> values;
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

    final color = ChartTrend.chartColorFromPoints(values);
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

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    if (showFill) {
      final fillPath = Path.from(path)
        ..lineTo(plotRight, plotBottom)
        ..lineTo(plotLeft, plotBottom)
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
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
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
      old.strokeWidth != strokeWidth ||
      old.showGrid != showGrid ||
      old.showFill != showFill ||
      old.showEndDot != showEndDot;
}

/// Size-safe chart container used on Home, Portfolio, Holdings, and Detail.
class ClarivoSparklineChart extends StatelessWidget {
  final List<double> values;
  final double height;
  final double? width;
  final bool loading;
  final String? periodLabel;
  final double strokeWidth;
  final bool showEndDot;
  final bool showFill;
  final bool showGrid;
  final double endDotRadius;
  final String emptyLabel;
  final double padTop;
  final double padBottom;

  const ClarivoSparklineChart({
    super.key,
    required this.values,
    required this.height,
    this.width,
    this.loading = false,
    this.periodLabel,
    this.strokeWidth = 2.0,
    this.showEndDot = true,
    this.showFill = true,
    this.showGrid = false,
    this.endDotRadius = 3.5,
    this.emptyLabel = 'Chart unavailable',
    this.padTop = 0.10,
    this.padBottom = 0.06,
  });

  /// Large portfolio / balance chart preset.
  const ClarivoSparklineChart.main({
    super.key,
    required this.values,
    required this.height,
    this.width,
    this.loading = false,
    this.periodLabel,
    this.emptyLabel = 'Chart unavailable',
  })  : strokeWidth = 2.8,
        showEndDot = true,
        showFill = true,
        showGrid = true,
        endDotRadius = 4.5,
        padTop = 0.12,
        padBottom = 0.08;

  /// Compact card sparkline preset.
  const ClarivoSparklineChart.mini({
    super.key,
    required this.values,
    required this.height,
    this.width,
    this.loading = false,
    this.periodLabel,
    this.emptyLabel = 'Chart unavailable',
  })  : strokeWidth = 2.0,
        showEndDot = true,
        showFill = true,
        showGrid = false,
        endDotRadius = 3.0,
        padTop = 0.14,
        padBottom = 0.08;

  @override
  Widget build(BuildContext context) {
    final box = SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: _buildBody(),
    );
    return box;
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

    if (values.length < 2) {
      return Center(
        child: Text(
          emptyLabel,
          style: const TextStyle(color: kTextMuted, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      );
    }

    final chart = CustomPaint(
      painter: ClarivoSparklinePainter(
        values: values,
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

    if (periodLabel == null || periodLabel!.isEmpty) {
      return chart;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$periodLabel trend',
              style: TextStyle(
                color: kTextMuted.withValues(alpha: 0.85),
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        Expanded(child: chart),
      ],
    );
  }
}
