import 'package:flutter_test/flutter_test.dart';

import 'package:clarivo/theme/app_colors.dart';
import 'package:clarivo/utils/visual_chart_trend.dart';
import 'package:clarivo/widgets/clarivo_sparkline_chart.dart';

void main() {
  group('VisualChartTrend endpoint segment', () {
    test('rising endpoint segment is green', () {
      const values = [275.15, 280.0, 283.78];
      final t = VisualChartTrend.trendFromVisualValues(values);
      expect(t.isUp, isTrue);
      expect(t.color, kPositive);
      expect(t.firstValue, 280.0);
      expect(t.lastValue, 283.78);
      expect(t.hasTrend, isTrue);
    });

    test('falling endpoint segment is red', () {
      const values = [378.67, 375.12];
      final t = VisualChartTrend.trendFromVisualValues(values);
      expect(t.isUp, isFalse);
      expect(t.color, kNegative);
      expect(t.firstValue, 378.67);
      expect(t.lastValue, 375.12);
    });

    test('period down but endpoint up is green (visible hook)', () {
      const values = [378.67, 370.0, 375.12, 379.71];
      final t = VisualChartTrend.trendFromVisualValues(values);
      expect(t.isUp, isTrue);
      expect(t.color, kPositive);
      expect(t.lastValue, 379.71);
    });

    test('chart widget trendOf matches helper', () {
      const values = [375.12, 379.71];
      expect(
        ClarivoSparklineChart.trendOf(values).isUp,
        VisualChartTrend.trendFromVisualValues(values).isUp,
      );
      expect(ClarivoSparklineChart.trendOf(values).color, kPositive);
    });

    test('neutral for insufficient data', () {
      expect(
        VisualChartTrend.trendFromVisualValues([]).hasTrend,
        isFalse,
      );
    });

    test('flat endpoint has no arrow', () {
      const values = [100.0, 100.0];
      final t = VisualChartTrend.trendFromVisualValues(values);
      expect(t.isUp, isTrue);
      expect(t.color, kPositive);
      expect(t.hasTrend, isFalse);
      expect(t.formattedPercent, '0.0%');
    });
  });
}
