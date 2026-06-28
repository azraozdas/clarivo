import 'package:clarivo/services/twelve_data_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Twelve Data daily history parsing', () {
    test('EodBar.fromJson maps close and date', () {
      final bar = EodBar.fromJson({
        'symbol': 'AAPL',
        'date': '2026-06-26',
        'close': 201.5,
      });
      expect(bar.symbol, 'AAPL');
      expect(bar.date, '2026-06-26');
      expect(bar.close, 201.5);
    });

    test('trimHistoryToDaysBack keeps enough wavy points', () {
      final history = <String, List<EodBar>>{};
      for (final sym in ['AAPL', 'TSLA', 'AMZN']) {
        final bars = <EodBar>[];
        for (var i = 0; i < 100; i++) {
          final d = DateTime(2026, 6, 26).subtract(Duration(days: i));
          bars.add(EodBar(
            symbol: sym,
            date:
                '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
            close: 100 + i.toDouble(),
          ));
        }
        history[sym] = bars;
      }

      final trimmed =
          TwelveDataService.trimHistoryToDaysBack(history, 45);
      for (final sym in ['AAPL', 'TSLA', 'AMZN']) {
        final count = TwelveDataService.closesForSymbol(trimmed, sym).length;
        expect(count, greaterThanOrEqualTo(20));
        expect(count, lessThanOrEqualTo(60));
      }

      const shares = {'AAPL': 10, 'TSLA': 5, 'AMZN': 3};
      final totals =
          TwelveDataService.portfolioTotalsByDate(trimmed, shares);
      expect(totals.length, greaterThanOrEqualTo(20));
    });

    test('barsFromQuote builds two real Twelve Data quote closes', () {
      final q = StockQuote(
        symbol: 'AAPL',
        close: 283.78,
        open: 275,
        high: 285.95,
        low: 274.21,
        changePercent: 3.14,
        isPositive: true,
        date: '2026-06-26',
        previousClose: 275.15,
      );
      final bars = TwelveDataService.barsFromQuoteForTest(q);
      expect(bars.length, 2);
      expect(bars.map((b) => b.close).toSet(), {283.78, 275.15});
    });

    test('stockChartSeries unavailable with fewer than 2 points', () {
      final series = TwelveDataService.stockChartSeries(
        {'AAPL': [const EodBar(symbol: 'AAPL', date: '2026-06-26', close: 1)]},
        'AAPL',
        null,
      );
      expect(series.mode, ChartDataMode.unavailable);
    });

    test('stockChartSeries unavailable with only two quote points', () {
      final bars = [
        const EodBar(symbol: 'AAPL', date: '2026-06-25', close: 275.15),
        const EodBar(symbol: 'AAPL', date: '2026-06-26', close: 283.78),
      ];
      final series = TwelveDataService.stockChartSeries(
        {'AAPL': bars},
        'AAPL',
        null,
      );
      expect(series.mode, ChartDataMode.unavailable);
      expect(series.points, isEmpty);
    });

    test('stockChartSeries historical with many points', () {
      final bars = List.generate(
        30,
        (i) => EodBar(
          symbol: 'AAPL',
          date:
              '2026-${(i + 1).toString().padLeft(2, '0')}-${(i + 1).toString().padLeft(2, '0')}',
          close: 150.0 + i,
        ),
      );
      final series = TwelveDataService.stockChartSeries(
        {'AAPL': bars},
        'AAPL',
        null,
      );
      expect(series.mode, ChartDataMode.historical);
      expect(series.points.length, greaterThanOrEqualTo(20));
    });

    test('deriveQuotesFromHistory builds quote from daily closes', () {
      final bars = List.generate(
        25,
        (i) {
          final d = DateTime(2026, 1, 1).add(Duration(days: i));
          return EodBar(
            symbol: 'AAPL',
            date:
                '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
            close: 200.0 + i,
          );
        },
      );
      final quotes = TwelveDataService.deriveQuotesFromHistory(
        {'AAPL': bars},
        ['AAPL'],
      );
      expect(quotes.length, 1);
      expect(quotes.first.close, greaterThan(200));
    });

    test('portfolio chart uses aligned real closes', () {
      final history = <String, List<EodBar>>{};
      for (final sym in ['AAPL', 'TSLA', 'AMZN']) {
        history[sym] = List.generate(
          30,
          (i) {
            final d = DateTime(2026, 1, 1).add(Duration(days: i));
            return EodBar(
              symbol: sym,
              date:
                  '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
              close: 100.0 + i,
            );
          },
        );
      }
      const shares = {'AAPL': 10, 'TSLA': 5, 'AMZN': 3};
      final series = TwelveDataService.portfolioChartSeries(
        history,
        shares,
        {},
      );
      expect(series.mode, ChartDataMode.historical);
      expect(series.points.length, greaterThanOrEqualTo(20));
    });
  });
}
