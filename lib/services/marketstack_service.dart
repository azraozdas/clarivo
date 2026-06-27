import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class StockQuote {
  final String symbol;
  final double close;
  final double open;
  final double high;
  final double low;
  final double changePercent;
  final bool isPositive;

  const StockQuote({
    required this.symbol,
    required this.close,
    required this.open,
    required this.high,
    required this.low,
    required this.changePercent,
    required this.isPositive,
  });

  static double _num(Map<String, dynamic> json, String key, double fallback) {
    final v = json[key];
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return fallback;
  }

  factory StockQuote.fromJson(Map<String, dynamic> json) {
    final close = _num(json, 'close', 0);
    final open = _num(json, 'open', close);
    final high = _num(json, 'high', close);
    final low = _num(json, 'low', close);
    final pct = open != 0 ? ((close - open) / open) * 100 : 0.0;
    return StockQuote(
      symbol: json['symbol'] as String? ?? '',
      close: close,
      open: open,
      high: high,
      low: low,
      changePercent: pct,
      isPositive: pct >= 0,
    );
  }

  String get priceStr => '\$${close.toStringAsFixed(2)}';

  String get changeStr {
    final sign = isPositive ? '+' : '';
    return '$sign${changePercent.toStringAsFixed(1)}%';
  }
}

class EodBar {
  final String symbol;
  final String date;
  final double close;

  const EodBar({
    required this.symbol,
    required this.date,
    required this.close,
  });

  factory EodBar.fromJson(Map<String, dynamic> json) {
    final v = json['close'];
    final close = v is num ? v.toDouble() : 0.0;
    return EodBar(
      symbol: json['symbol'] as String? ?? '',
      date: (json['date'] as String? ?? '').substring(0, 10),
      close: close,
    );
  }
}

class MarketstackService {
  static const String _apiKey = '8fbd57ac60ec1d5ad58e3b33e753234e';
  // Marketstack free plan only supports HTTP, not HTTPS.
  // android:usesCleartextTraffic="true" in AndroidManifest.xml allows this.
  // Upgrading to a paid Marketstack plan enables HTTPS — just change http to https here.
  static const String _directBase = 'http://api.marketstack.com/v2';
  static const String _proxyBase = 'http://localhost:8089';

  static String get _base => kIsWeb ? _proxyBase : _directBase;

  // ── Latest quotes cache ──────────────────────────────────────────────────
  static List<StockQuote>? _cache;
  static DateTime? _cacheAt;
  static const Duration _cacheTtl = Duration(minutes: 5);
  static const int _quoteCacheVersion = 2;
  static int? _quoteCacheVersionAt;

  static bool _quotesCacheValid() {
    if (_cache == null || _cache!.isEmpty) return false;
    if (_quoteCacheVersionAt != _quoteCacheVersion) return false;
    try {
      for (final q in _cache!) {
        final _ = q.high + q.low;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Historical (EOD) cache ───────────────────────────────────────────────
  static Map<String, List<EodBar>>? _historyCache;
  static DateTime? _historyCacheAt;
  static int? _historyCacheDays;
  static const Duration _historyTtl = Duration(minutes: 30);
  static const int _historyCacheVersion = 3;
  static int? _historyCacheVersionAt;

  static bool _historyCacheValid(int daysBack) {
    if (_historyCache == null || _historyCache!.isEmpty) return false;
    if (_historyCacheVersionAt != _historyCacheVersion) return false;
    if (_historyCacheDays != daysBack) return false;
    try {
      final dynamic cache = _historyCache;
      for (final entry in (cache as Map).entries) {
        final bars = entry.value;
        if (bars is! List || bars.isEmpty) continue;
        if (bars.first is! EodBar) return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Data helpers ─────────────────────────────────────────────────────────

  /// Returns an ascending list of close prices for [symbol] from [history].
  static List<double> closesForSymbol(
    Map<String, List<EodBar>> history,
    String symbol,
  ) {
    final bars = history[symbol];
    if (bars == null || bars.isEmpty) return [];
    final sorted = List<EodBar>.from(bars)
      ..sort((a, b) => a.date.compareTo(b.date));
    return sorted.map((b) => b.close).toList();
  }

  /// Sums (close × shares) per calendar date and returns values in date order.
  static List<double> portfolioTotalsByDate(
    Map<String, List<EodBar>> history,
    Map<String, int> shares,
  ) {
    final Map<String, double> byDate = {};
    for (final entry in history.entries) {
      final count = shares[entry.key] ?? 0;
      if (count == 0) continue;
      for (final bar in entry.value) {
        byDate[bar.date] = (byDate[bar.date] ?? 0) + bar.close * count;
      }
    }
    final dates = byDate.keys.toList()..sort();
    return dates.map((d) => byDate[d]!).toList();
  }

  // ── API calls ─────────────────────────────────────────────────────────────

  static Future<List<StockQuote>> fetchLatest(List<String> symbols) async {
    if (_quotesCacheValid() &&
        _cacheAt != null &&
        DateTime.now().difference(_cacheAt!) < _cacheTtl) {
      return _cache!;
    }
    _cache = null;

    final String path =
        '/eod/latest?access_key=$_apiKey&symbols=${symbols.join(',')}';
    final uri = Uri.parse('$_base$path');
    final response = await http
        .get(uri, headers: {'User-Agent': 'ClarivApp/1.0'})
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception(
          'Marketstack error ${response.statusCode}: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['data'] as List<dynamic>;
    final quotes = list
        .map((e) => StockQuote.fromJson(e as Map<String, dynamic>))
        .toList();

    _cache = quotes;
    _cacheAt = DateTime.now();
    _quoteCacheVersionAt = _quoteCacheVersion;
    return quotes;
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Fetches EOD close prices for [symbols] going back [daysBack] calendar days.
  /// Default is 30 days which typically yields ~20 trading days per stock.
  static Future<Map<String, List<EodBar>>> fetchWeeklyHistory(
    List<String> symbols, {
    int daysBack = 30,
  }) async {
    if (_historyCacheValid(daysBack) &&
        _historyCacheAt != null &&
        DateTime.now().difference(_historyCacheAt!) < _historyTtl) {
      return _historyCache!;
    }
    _historyCache = null;
    _historyCacheAt = null;
    _historyCacheVersionAt = null;
    _historyCacheDays = null;

    final to = DateTime.now();
    final from = to.subtract(Duration(days: daysBack));

    final path = '/eod'
        '?access_key=$_apiKey'
        '&symbols=${symbols.join(',')}'
        '&date_from=${_dateStr(from)}'
        '&date_to=${_dateStr(to)}'
        '&limit=150'
        '&sort=ASC';

    final uri = Uri.parse('$_base$path');
    final response = await http
        .get(uri, headers: {'User-Agent': 'ClarivApp/1.0'})
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
          'History error ${response.statusCode}: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json.containsKey('error') && json['error'] != null) {
      throw Exception('History API error: ${json['error']}');
    }

    final list = json['data'] as List<dynamic>;

    final Map<String, List<EodBar>> grouped = {};
    for (final item in list) {
      final bar = EodBar.fromJson(item as Map<String, dynamic>);
      if (bar.symbol.isEmpty || bar.close <= 0) continue;
      grouped.putIfAbsent(bar.symbol, () => []).add(bar);
    }

    final Map<String, List<EodBar>> result = {};
    for (final entry in grouped.entries) {
      final sorted = entry.value..sort((a, b) => a.date.compareTo(b.date));
      result[entry.key] = sorted;
    }

    _historyCache = result;
    _historyCacheAt = DateTime.now();
    _historyCacheVersionAt = _historyCacheVersion;
    _historyCacheDays = daysBack;
    return result;
  }

  /// Alias kept for backward compatibility.
  static Future<Map<String, List<EodBar>>> fetchHistoricalPrices(
    List<String> symbols, {
    int daysBack = 30,
  }) =>
      fetchWeeklyHistory(symbols, daysBack: daysBack);
}
