// Run: dart run tool/verify_chart_data.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

const _yahooHeaders = {
  'User-Agent': 'Mozilla/5.0 (compatible; ClarivoApp/1.0)',
};

Future<Map<String, dynamic>?> _yahooMeta(String symbol) async {
  final uri = Uri.parse(
    'https://query1.finance.yahoo.com/v8/finance/chart/$symbol'
    '?interval=1d&range=1d',
  );
  final r = await http.get(uri, headers: _yahooHeaders);
  if (r.statusCode != 200) return null;
  final json = jsonDecode(r.body) as Map<String, dynamic>;
  final results = (json['chart'] as Map)['result'] as List;
  return results.first['meta'] as Map<String, dynamic>;
}

Future<List<double>> _yahooCloses(String symbol) async {
  final uri = Uri.parse(
    'https://query1.finance.yahoo.com/v8/finance/chart/$symbol'
    '?interval=1d&range=2mo',
  );
  final r = await http.get(uri, headers: _yahooHeaders);
  final json = jsonDecode(r.body) as Map<String, dynamic>;
  final results = (json['chart'] as Map)['result'] as List;
  final quote = (results.first['indicators'] as Map)['quote'] as List;
  final closes = quote.first['close'] as List;
  return closes.whereType<num>().map((n) => n.toDouble()).toList();
}

void _auditSymbol(String symbol) {
  // sync wrapper - call async in main
}

Future<void> _auditSymbolAsync(String symbol) async {
  final meta = await _yahooMeta(symbol);
  final closes = await _yahooCloses(symbol);
  if (meta == null) {
    print('$symbol: meta unavailable');
    return;
  }

  final price = (meta['regularMarketPrice'] as num).toDouble();
  final prev = meta['previousClose'] ?? meta['chartPreviousClose'];
  final prevClose = prev is num ? prev.toDouble() : double.tryParse('$prev') ?? 0;
  final apiPct = (meta['regularMarketChangePercent'] as num?)?.toDouble();
  final calcPct =
      prevClose > 0 ? ((price - prevClose) / prevClose) * 100 : 0.0;
  final chartFirst = closes.isNotEmpty ? closes.first : 0.0;
  final chartLast = closes.isNotEmpty ? closes.last : 0.0;
  final chartTrendPct = chartFirst > 0
      ? ((chartLast - chartFirst) / chartFirst) * 100
      : 0.0;
  final dailyUp = calcPct >= 0;
  final chartUp = chartLast >= chartFirst;

  print('--- $symbol ---');
  print('latestPrice: ${price.toStringAsFixed(2)}');
  print('previousClose: ${prevClose.toStringAsFixed(2)}');
  print('dailyChange: ${(price - prevClose).toStringAsFixed(2)}');
  print('dailyChangePercent (calc): ${calcPct.toStringAsFixed(2)}%');
  print('dailyChangePercent (api): ${apiPct?.toStringAsFixed(2) ?? 'n/a'}%');
  print('dailyPositive: $dailyUp');
  print('chartPeriod: 2M');
  print('chartPoints: ${closes.length}');
  print('chartFirstClose: ${chartFirst.toStringAsFixed(2)}');
  print('chartLastClose: ${chartLast.toStringAsFixed(2)}');
  print('chartTrendPercent: ${chartTrendPct.toStringAsFixed(2)}%');
  print('chartColor: ${chartUp ? 'green' : 'red'}');
  print('');
}

Future<void> main() async {
  for (final sym in ['AAPL', 'TSLA', 'AMZN']) {
    await _auditSymbolAsync(sym);
  }
}
