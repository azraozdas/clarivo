import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
    // Guard against empty/short date strings to avoid RangeError.
    final dateStr = json['date'] as String? ?? '';
    return EodBar(
      symbol: json['symbol'] as String? ?? '',
      date: dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr,
      close: close,
    );
  }
}

/// Thrown when Marketstack returns an API-level error inside the JSON body.
/// [code] maps to Marketstack error codes, e.g. "usage_limit_reached".
class MarketstackApiException implements Exception {
  final String code;
  final String message;
  const MarketstackApiException(this.code, this.message);

  /// True when the monthly request quota has been exhausted.
  bool get isRateLimit => code == 'usage_limit_reached';

  /// True when HTTPS is used on a free plan that only supports HTTP.
  bool get isHttpsRestricted => code == 'https_access_restricted';

  @override
  String toString() => 'MarketstackApiException[$code]: $message';
}

class MarketstackService {
  static const String _apiKey = 'd8vs3tpr01qgrv4qm9agd8vs3tpr01qgrv4qm9b0';
  // Marketstack free plan only supports HTTP, not HTTPS.
  // android:usesCleartextTraffic="true" in AndroidManifest.xml allows this.
  // Upgrading to a paid Marketstack plan enables HTTPS — just change http to https here.
  static const String _directBase = 'http://api.marketstack.com/v2';
  static const String _proxyBase = 'http://localhost:8089';

  static String get _base => kIsWeb ? _proxyBase : _directBase;

  // ── Persistent cache flags (set after each fetchLatest call) ────────────
  /// True when the last fetchLatest result came from SharedPreferences cache.
  static bool lastFetchFromCache = false;
  /// Date when the currently active cached data was originally saved.
  static DateTime? lastCacheDate;

  // ── Persistent cache keys ────────────────────────────────────────────────
  static const String _prefsQuotesKey = 'mkt_quotes_v1';
  static const String _prefsCacheDateKey = 'mkt_quotes_date_v1';

  // ── Latest quotes in-memory cache ────────────────────────────────────────
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

  // ── Persistent cache helpers ─────────────────────────────────────────────

  /// Saves [quotes] to SharedPreferences so they survive app restarts.
  static Future<void> _saveQuotesToPrefs(List<StockQuote> quotes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = quotes
          .map((q) => {
                'symbol': q.symbol,
                'close': q.close,
                'open': q.open,
                'high': q.high,
                'low': q.low,
              })
          .toList();
      await prefs.setString(_prefsQuotesKey, jsonEncode(data));
      await prefs.setString(
          _prefsCacheDateKey, DateTime.now().toIso8601String());
      debugPrint('[Marketstack] Quotes persisted to SharedPreferences.');
    } catch (e) {
      debugPrint('[Marketstack] Failed to persist quotes: $e');
    }
  }

  /// Loads previously saved quotes from SharedPreferences.
  /// Returns null if nothing was saved or parsing fails.
  static Future<List<StockQuote>?> _loadQuotesFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_prefsQuotesKey);
      if (str == null) return null;
      final list = jsonDecode(str) as List<dynamic>;
      final quotes = list
          .map((e) => StockQuote.fromJson(e as Map<String, dynamic>))
          .where((q) => q.symbol.isNotEmpty && q.close > 0)
          .toList();
      debugPrint(
          '[Marketstack] Loaded ${quotes.length} quotes from SharedPreferences.');
      return quotes.isEmpty ? null : quotes;
    } catch (e) {
      debugPrint('[Marketstack] Failed to load persisted quotes: $e');
      return null;
    }
  }

  /// Returns the date the persistent cache was last written, or null.
  static Future<DateTime?> _loadCacheDateFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_prefsCacheDateKey);
      return str != null ? DateTime.parse(str) : null;
    } catch (_) {
      return null;
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

  /// Fetches latest EOD quotes for [symbols].
  ///
  /// On success: saves to SharedPreferences persistent cache and returns.
  /// On any failure: tries the persistent cache first.
  ///   If cache exists  → sets [lastFetchFromCache]=true, returns stale data.
  ///   If no cache      → rethrows so callers can show an error state.
  static Future<List<StockQuote>> fetchLatest(List<String> symbols) async {
    // ── In-memory TTL cache ──────────────────────────────────────────────
    if (_quotesCacheValid() &&
        _cacheAt != null &&
        DateTime.now().difference(_cacheAt!) < _cacheTtl) {
      debugPrint('[Marketstack] fetchLatest: in-memory cache hit.');
      lastFetchFromCache = false;
      return _cache!;
    }
    _cache = null;

    // ── Live API request ─────────────────────────────────────────────────
    try {
      final String path =
          '/eod/latest?access_key=$_apiKey&symbols=${symbols.join(',')}';
      final uri = Uri.parse('$_base$path');
      debugPrint('[Marketstack] GET $uri');

      final response = await http
          .get(uri, headers: {'User-Agent': 'ClarivApp/1.0'})
          .timeout(const Duration(seconds: 12));

      debugPrint('[Marketstack] HTTP ${response.statusCode}');

      // Parse JSON body regardless of status code — error details may be inside.
      Map<String, dynamic>? json;
      try {
        json = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        final preview = response.body.length > 300
            ? response.body.substring(0, 300)
            : response.body;
        debugPrint('[Marketstack] Non-JSON response: $preview');
      }

      // API-level error object (present even on 200 for some Marketstack errors).
      if (json != null &&
          json.containsKey('error') &&
          json['error'] != null) {
        final err = json['error'] as Map<String, dynamic>;
        final code = err['code'] as String? ?? 'unknown_error';
        final msg = err['message'] as String? ?? 'Unknown API error.';
        debugPrint('[Marketstack] API error [$code]: $msg');
        throw MarketstackApiException(code, msg);
      }

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      if (json == null) throw Exception('Could not decode API response.');

      final data = json['data'];
      if (data == null) {
        throw Exception('API response missing "data" field.');
      }

      final list = data as List<dynamic>;
      debugPrint('[Marketstack] ${list.length} raw records received.');

      final quotes = list
          .map((e) => StockQuote.fromJson(e as Map<String, dynamic>))
          .where((q) => q.symbol.isNotEmpty && q.close > 0)
          .toList();

      debugPrint('[Marketstack] ${quotes.length} valid quotes parsed.');

      _cache = quotes;
      _cacheAt = DateTime.now();
      _quoteCacheVersionAt = _quoteCacheVersion;
      lastFetchFromCache = false;
      await _saveQuotesToPrefs(quotes); // persist for future fallback

      return quotes;
    } catch (e) {
      // ── Persistent cache fallback ────────────────────────────────────
      debugPrint('[Marketstack] Live fetch failed: $e');
      debugPrint('[Marketstack] Trying SharedPreferences cache...');

      final cached = await _loadQuotesFromPrefs();
      if (cached != null && cached.isNotEmpty) {
        _cache = cached;
        _cacheAt = DateTime.now();
        _quoteCacheVersionAt = _quoteCacheVersion;
        lastFetchFromCache = true;
        lastCacheDate = await _loadCacheDateFromPrefs();
        debugPrint('[Marketstack] Serving ${cached.length} cached quotes '
            '(originally saved: $lastCacheDate).');
        return cached;
      }

      debugPrint('[Marketstack] No cache available. Propagating error.');
      rethrow; // let the screen display the correct error state
    }
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
