// Run: dart run tool/verify_portfolio_chart.dart
// Simulates the app's chart pipeline with Yahoo 2M data + default shares.
import 'dart:convert';
import 'package:http/http.dart' as http;

const _headers = {'User-Agent': 'Mozilla/5.0 (compatible; ClarivoApp/1.0)'};
const _shares = {'AAPL': 10, 'TSLA': 5, 'AMZN': 8};
const _summaryWindowSize = 8;

Future<List<double>> _yahooCloses(String symbol) async {
  final uri = Uri.parse(
    'https://query1.finance.yahoo.com/v8/finance/chart/$symbol'
    '?interval=1d&range=2mo',
  );
  final r = await http.get(uri, headers: _headers);
  final json = jsonDecode(r.body) as Map<String, dynamic>;
  final results = (json['chart'] as Map)['result'] as List;
  final quote = (results.first['indicators'] as Map)['quote'] as List;
  final closes = quote.first['close'] as List;
  return closes.whereType<num>().map((n) => n.toDouble()).toList();
}

Future<double?> _yahooPrice(String symbol) async {
  final uri = Uri.parse(
    'https://query1.finance.yahoo.com/v8/finance/chart/$symbol'
    '?interval=1d&range=1d',
  );
  final r = await http.get(uri, headers: _headers);
  final json = jsonDecode(r.body) as Map<String, dynamic>;
  final meta = ((json['chart'] as Map)['result'] as List).first['meta']
      as Map<String, dynamic>;
  return (meta['regularMarketPrice'] as num?)?.toDouble();
}

List<double> _lastWindow(List<double> full) {
  if (full.length <= _summaryWindowSize) return List<double>.from(full);
  return full.sublist(full.length - _summaryWindowSize);
}

void _audit(String name, List<double> pts, {String label = 'summary'}) {
  if (pts.length < 2) {
    print('$name: insufficient points');
    return;
  }
  final first = pts.first;
  final last = pts.last;
  final pct = ((last - first) / first.abs()) * 100;
  final up = pct >= 0;
  print('--- $name ($label, n=${pts.length}) ---');
  print('first: ${first.toStringAsFixed(2)}');
  print('last:  ${last.toStringAsFixed(2)}');
  print('trend: ${up ? '+' : ''}${pct.toStringAsFixed(2)}%');
  print('color: ${up ? 'green' : 'red'}');
  print('last10: ${pts.length > 10 ? pts.sublist(pts.length - 10) : pts}');
  print('');
}

Future<void> main() async {
  final bySym = <String, List<double>>{};
  final live = <String, double>{};

  for (final sym in _shares.keys) {
    bySym[sym] = await _yahooCloses(sym);
    live[sym] = (await _yahooPrice(sym)) ?? bySym[sym]!.last;
    final closes = List<double>.from(bySym[sym]!);
    if ((closes.last - live[sym]!).abs() > 0.005) {
      closes.add(live[sym]!);
    }
    bySym[sym] = closes;
    _audit(sym, closes, label: 'full 2M+live');
    _audit(sym, _lastWindow(closes), label: 'summary window');
  }

  // Portfolio totals on common dates (simplified — all symbols same length from Yahoo)
  final n = bySym['AAPL']!.length;
  final totals = <double>[];
  for (var i = 0; i < n; i++) {
    var t = 0.0;
    for (final e in _shares.entries) {
      t += bySym[e.key]![i] * e.value;
    }
    totals.add(t);
  }
  _audit('PORTFOLIO', totals, label: 'full 2M+live');
  _audit('PORTFOLIO', _lastWindow(totals), label: 'summary window (Home card)');
}
