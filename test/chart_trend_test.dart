import 'package:flutter_test/flutter_test.dart';

import 'package:clarivo/theme/app_colors.dart';
import 'package:clarivo/utils/visual_chart_trend.dart';
import 'package:clarivo/widgets/clarivo_sparkline_chart.dart';

void main() {
  group('VisualChartTrend terminal segment', () {
    test('endpoint segment up is green (portfolio-like recovery)', () {
      const values = [
        7000.0, 6800.0, 6500.0, 6400.0, 6443.18, 6597.87,
      ];
      final t = VisualChartTrend.trendFromVisualValues(values);
      expect(t.isUp, isTrue);
      expect(t.color, kPositive);
      expect(t.lastValue, 6597.87);
      expect(t.firstValue, 6443.18);
    });

    test('endpoint segment down is red', () {
      const values = [100.0, 110.0, 105.0, 99.0];
      final t = VisualChartTrend.trendFromVisualValues(values);
      expect(t.isUp, isFalse);
      expect(t.color, kNegative);
    });

    test('chart widget trendOf matches helper', () {
      const values = [275.15, 283.78];
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
  });
}
