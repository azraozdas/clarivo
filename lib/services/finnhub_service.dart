import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/visual_chart_trend.dart';

// User-specified API key constant name for Finnhub integration.
// ignore: constant_identifier_names
const String FINNHUB_KEY = 'd90h8o9r01qj6ursvc1gd90h8o9r01qj6ursvc20';

class StockQuote {
  final String symbol;
  final double close;
  final double open;
  final double high;
  final double low;
  final double changePercent;
  final bool isPositive;
  final String date;
  final double? volume;
  final double? previousClose;

  const StockQuote({
    required this.symbol,
    required this.close,
    required this.open,
    required this.high,
    required this.low,
    required this.changePercent,
    required this.isPositive,
    this.date = '',
    this.volume,
    this.previousClose,
  });

  static double _num(dynamic v, [double fallback = 0]) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    final s = v.toString().trim().replaceAll('%', '');
    return double.tryParse(s) ?? fallback;
  }

  factory StockQuote.fromJson(Map<String, dynamic> json) {
    final close = _num(json['close']);
    final open = _num(json['open'], close);
    final high = _num(json['high'], close);
    final low = _num(json['low'], close);
    final pctRaw = json['changePercent'];
    final pc = json['previousClose'];
    final previousClose = pc == null ? null : _num(pc);
    final pct = pctRaw != null
        ? _num(pctRaw)
        : (previousClose != null && previousClose > 0
            ? ((close - previousClose) / previousClose) * 100
            : (open != 0 ? ((close - open) / open) * 100 : 0.0));
    final vol = json['volume'];
    return StockQuote(
      symbol: (json['symbol'] as String? ?? '').toUpperCase(),
      close: close,
      open: open,
      high: high,
      low: low,
      changePercent: pct,
      isPositive: pct >= 0,
      date: json['date'] as String? ?? '',
      volume: vol == null ? null : _num(vol),
      previousClose: previousClose,
    );
  }

  factory StockQuote.fromFinnhubQuote(String symbol, Map<String, dynamic> q) {
    final sym = symbol.toUpperCase();
    final close = _num(q['c']);
    final open = _num(q['o'], close);
    final high = _num(q['h'], close);
    final low = _num(q['l'], close);
    final previousCloseRaw = _num(q['pc'], 0);
    final previousClose = previousCloseRaw > 0 ? previousCloseRaw : null;
    final pct = _num(q['dp'], previousClose != null && previousClose > 0
        ? ((close - previousClose) / previousClose) * 100
        : 0.0);
    final ts = q['t'];
    final unix = ts is int ? ts : int.tryParse(ts?.toString() ?? '') ?? 0;
    final date = unix > 0
        ? DateTime.fromMillisecondsSinceEpoch(unix * 1000, isUtc: true)
            .toLocal()
            .toIso8601String()
            .substring(0, 10)
        : '';
    return StockQuote(
      symbol: sym,
      close: close,
      open: open,
      high: high,
      low: low,
      changePercent: pct,
      isPositive: pct >= 0,
      date: date,
      previousClose: previousClose,
    );
  }

  String get priceStr => '\$${close.toStringAsFixed(2)}';
  String get changeStr => dailyChangeStr;
  String get dateDisplay => date.isNotEmpty ? date : '--';

  String get volumeDisplay {
    if (volume == null || volume! <= 0) return '--';
    if (volume! >= 1000000) {
      return '${(volume! / 1000000).toStringAsFixed(1)}M';
    }
    if (volume! >= 1000) {
      return '${(volume! / 1000).toStringAsFixed(1)}K';
    }
    return volume!.toStringAsFixed(0);
  }

  String get previousCloseDisplay =>
      previousClose != null ? '\$${previousClose!.toStringAsFixed(2)}' : '--';

  double get dailyChangeAmount {
    if (previousClose != null && previousClose! > 0) {
      return close - previousClose!;
    }
    return close - open;
  }

  double get dailyChangePercentValue {
    if (previousClose != null && previousClose! > 0) {
      return ((close - previousClose!) / previousClose!.abs()) * 100;
    }
    if (open != 0) return ((close - open) / open.abs()) * 100;
    return changePercent;
  }

  bool get isDailyPositive => dailyChangeAmount >= 0;

  String get dailyChangeStr {
    final pct = dailyChangePercentValue;
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}%';
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
    if (v == null) {
      return const EodBar(symbol: '', date: '', close: 0);
    }
    final close = v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;
    final dateStr = json['date'] as String? ?? '';
    final rawSymbol = json['symbol'] as String? ?? '';
    return EodBar(
      symbol: rawSymbol.toUpperCase(),
      date: dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr,
      close: close,
    );
  }
}

enum ChartDataMode { historical, unavailable }

enum QuoteDataSource { finnhub, cache, unknown }

class ChartSeries {
  final List<double> points;
  final ChartDataMode mode;
  final String reason;
  final String? periodLabel;

  const ChartSeries({
    required this.points,
    required this.mode,
    required this.reason,
    this.periodLabel,
  });

  String get displayPeriodLabel => periodLabel ?? '';
}

class FinnhubApiException implements Exception {
  final String code;
  final String message;
  const FinnhubApiException(this.code, this.message);

  bool get isRateLimit => code == 'rate_limit';

  @override
  String toString() => 'FinnhubApiException[$code]: $message';
}

/// News item from Finnhub company-news.
class NewsArticle {
  final String title;
  final String source;
  final String time;
  final String tag;
  final String summary;
  final String url;
  final String? imageUrl;

  const NewsArticle({
    required this.title,
    required this.source,
    required this.time,
    required this.tag,
    required this.summary,
    required this.url,
    this.imageUrl,
  });
}

/// Quotes + history loaded together — avoids duplicate API calls across tabs.
class MarketBootstrapResult {
  final Map<String, List<EodBar>> history;
  final List<StockQuote> quotes;
  final bool fromCache;

  const MarketBootstrapResult({
    required this.history,
    required this.quotes,
    this.fromCache = false,
  });
}

class FinnhubService {
  static const String _apiKey = FINNHUB_KEY;
  static const String _base = 'https://finnhub.io/api/v1';

  static bool lastFetchFromCache = false;
  static QuoteDataSource lastQuoteSource = QuoteDataSource.unknown;
  static const int homeHistoryDays = 45;
  static const int minWavyChartPoints = 20;
  static const List<String> kChartSymbols = ['AAPL', 'TSLA', 'AMZN'];
  static DateTime? lastCacheDate;
  static bool lastHistoryFromCache = false;

  static const String _prefsQuotesKey = 'fh_quotes_v1';
  static const String _prefsCacheDateKey = 'fh_quotes_date_v1';
  static const String _prefsHistoryPrefix = 'fh_history_v1_';
  static const String _legacyHistoryPrefix = 'av_history_v1_';
  static const String _legacyQuotesKey = 'av_quotes_v1';
  static const String _prefsQuoteHistoryKey = 'fh_quote_history_v1';
  static const String _prefsNewsKey = 'fh_news_v1';
  static const String _prefsNewsDateKey = 'fh_news_date_v1';
  static const int _candleHistoryDays = 90;

  /// Set after Finnhub returns HTTP 403 on `/stock/candle` (premium-only).
  static bool? _candleAccessDenied;
  static bool get isCandleEndpointDenied => _candleAccessDenied == true;

  static List<StockQuote>? _cache;
  static DateTime? _cacheAt;
  static const Duration _cacheTtl = Duration(minutes: 5);
  static const int _quoteCacheVersion = 1;
  static int? _quoteCacheVersionAt;

  static Map<String, List<EodBar>>? _historyCache;
  static DateTime? _historyCacheAt;
  static int? _historyCacheDays;
  static const Duration _historyTtl = Duration(minutes: 60);
  static const int _historyCacheVersion = 1;
  static int? _historyCacheVersionAt;

  static List<NewsArticle>? _newsCache;
  static DateTime? _newsCacheAt;
  static const Duration _newsTtl = Duration(minutes: 60);
  static Future<List<NewsArticle>>? _newsFetchFuture;

  static const String _prefsRateLimitDayKey = 'fh_rate_limit_day_v1';
  static const String _prefsApiKeyIdKey = 'fh_api_key_id_v1';
  static bool _rateLimitFlagLoaded = false;

  /// Total Finnhub HTTP calls this app session (for diagnostics).
  static int apiRequestCount = 0;
  static int sessionCacheHits = 0;

  static Future<Map<String, List<EodBar>>>? _historyInFlight;
  static Future<List<StockQuote>>? _quotesInFlight;
  static Future<MarketBootstrapResult>? _bootstrapInFlight;

  static DateTime? _lastApiCall;
  static const Duration _minApiInterval = Duration(milliseconds: 350);
  static const Duration _quoteTimeout = Duration(seconds: 10);
  static const Duration _historyTimeout = Duration(seconds: 15);
  static const Duration _newsTimeout = Duration(seconds: 15);
  static final Map<String, Future<({List<EodBar> bars, StockQuote? quote})>>
      _dailyFutures = {};
  static Future<void>? _throttleChain;
  static bool _rateLimitActive = false;

  /// True when Finnhub returned a rate-limit response this session/day.
  static bool get isRateLimitActive => _rateLimitActive;

  static void _logTiming(String label, Stopwatch sw) {
    debugPrint('[Finnhub] $label ${sw.elapsedMilliseconds}ms');
  }

  static String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  static Future<void> _ensureRateLimitFlagLoaded() async {
    if (_rateLimitFlagLoaded) return;
    _rateLimitFlagLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedKeyId = prefs.getString(_prefsApiKeyIdKey);
      if (storedKeyId != _apiKey) {
        _rateLimitActive = false;
        await prefs.remove(_prefsRateLimitDayKey);
        await prefs.setString(_prefsApiKeyIdKey, _apiKey);
        debugPrint('[Finnhub] new API key — cleared rate-limit block');
        return;
      }
      final day = prefs.getString(_prefsRateLimitDayKey);
      if (day == _todayKey()) {
        _rateLimitActive = true;
        debugPrint(
          '[Finnhub] daily API limit flag active for $day — network disabled',
        );
      }
    } catch (e) {
      debugPrint('[Finnhub] rate limit flag load failed: $e');
    }
  }

  static Future<void> _persistRateLimitFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsRateLimitDayKey, _todayKey());
    } catch (e) {
      debugPrint('[Finnhub] rate limit flag persist failed: $e');
    }
  }

  static Future<void> _clearRateLimitFlag() async {
    _rateLimitActive = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsRateLimitDayKey);
    } catch (_) {}
  }

  static void _recordApiRequest(String kind, String target) {
    apiRequestCount++;
    debugPrint(
      '[Finnhub] API request #$apiRequestCount kind=$kind target=$target',
    );
  }

  static void _logRawResponse(
    String kind,
    String target,
    Map<String, dynamic> json,
  ) {
    final status = json['s']?.toString() ?? 'ok';
    debugPrint('[Finnhub] RAW $kind $target status=$status keys=${json.keys.join(', ')}');
  }

  static void _recordCacheHit(String label) {
    sessionCacheHits++;
    debugPrint('[Finnhub] cache-hit #$sessionCacheHits $label');
  }

  static bool _quotesCacheValid() {
    if (_cache == null || _cache!.isEmpty) return false;
    if (_quoteCacheVersionAt != _quoteCacheVersion) return false;
    return true;
  }

  static bool _quotesCacheFresh() {
    if (!_quotesCacheValid() || _cacheAt == null) return false;
    return DateTime.now().difference(_cacheAt!) < _cacheTtl;
  }

  static bool _historyCacheFresh() {
    if (_historyCache == null ||
        _historyCacheAt == null ||
        _historyCacheVersionAt != _historyCacheVersion) {
      return false;
    }
    if (DateTime.now().difference(_historyCacheAt!) >= _historyTtl) {
      return false;
    }
    return _historyCompleteForSymbols(_historyCache!, kChartSymbols);
  }

  static bool _historyCompleteForSymbols(
    Map<String, List<EodBar>> history,
    List<String> symbols,
  ) {
    for (final sym in symbols) {
      if (closesForSymbol(history, sym).length < 2) return false;
    }
    return true;
  }

  static bool _historyHasChartData(
    Map<String, List<EodBar>> history,
    List<String> symbols,
  ) {
    for (final sym in symbols) {
      if (closesForSymbol(history, sym).length >= 2) return true;
    }
    return false;
  }

  static bool historyHasWavyChartData(
    Map<String, List<EodBar>> history,
    List<String> symbols,
  ) {
    for (final sym in symbols) {
      if (closesForSymbol(history, sym).length >= minWavyChartPoints) {
        return true;
      }
    }
    return false;
  }

  static Map<String, List<EodBar>> combineHistoryMaps(
    Map<String, List<EodBar>>? a,
    Map<String, List<EodBar>>? b,
  ) {
    final merged = <String, List<EodBar>>{};
    final keys = {...?a?.keys, ...?b?.keys};
    for (final key in keys) {
      final bars = _sortedBars([
        ...?a?[key],
        ...?b?[key],
      ]);
      if (bars.isNotEmpty) merged[key.toUpperCase()] = bars;
    }
    return merged;
  }

  static int _historyScore(
    Map<String, List<EodBar>> history,
    List<String> symbols,
  ) {
    var score = 0;
    for (final sym in symbols) {
      score += closesForSymbol(history, sym).length;
    }
    return score;
  }

  static Future<void> _throttle() {
    final previous = _throttleChain ?? Future<void>.value();
    final next = previous.then((_) async {
      if (_lastApiCall != null) {
        final elapsed = DateTime.now().difference(_lastApiCall!);
        if (elapsed < _minApiInterval) {
          await Future<void>.delayed(_minApiInterval - elapsed);
        }
      }
      _lastApiCall = DateTime.now();
    });
    _throttleChain = next;
    return next;
  }

  static void _markRateLimit(Object message) {
    _rateLimitActive = true;
    debugPrint('[Finnhub] rate limit detected: $message');
    _persistRateLimitFlag();
  }

  static void _checkFinnhubError(Map<String, dynamic> json, int statusCode) {
    if (statusCode == 429) {
      _markRateLimit('HTTP 429');
      throw FinnhubApiException('rate_limit', 'Finnhub rate limit');
    }
    if (statusCode == 401 || statusCode == 403) {
      throw FinnhubApiException('auth_error', 'Finnhub auth error $statusCode');
    }
    if (json.containsKey('error')) {
      throw FinnhubApiException('api_error', json['error'].toString());
    }
  }

  static String _formatNewsTimeFromUnix(int unixSeconds) {
    if (unixSeconds <= 0) return '';
    final dt =
        DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000, isUtc: true)
            .toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  static String? _validImageUrl(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return trimmed;
  }

  static String _newsTagFromRelated(String related, {required String fallbackSymbol}) {
    final parts = related
        .split(',')
        .map((s) => s.trim().toUpperCase())
        .where((s) => s.isNotEmpty);
    for (final sym in parts) {
      if (kChartSymbols.contains(sym)) return sym;
    }
    return fallbackSymbol.toUpperCase();
  }

  static String _formatFinnhubDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _unixToDate(int unixSeconds) {
    if (unixSeconds <= 0) return '';
    return DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000, isUtc: true)
        .toLocal()
        .toIso8601String()
        .substring(0, 10);
  }

  static Future<Map<String, List<EodBar>>> _baselineHistory(
    List<String> fetchSymbols,
    int daysBack,
  ) async {
    var merged = Map<String, List<EodBar>>.from(_historyCache ?? {});
    final fromPrefs = await _loadBestHistoryFromPrefs(
      symbols: fetchSymbols,
      preferredDays: daysBack,
    );
    if (fromPrefs != null) {
      for (final entry in fromPrefs.entries) {
        merged[entry.key.toUpperCase()] = _sortedBars(entry.value);
      }
    }
    return merged;
  }

  static String sanitizeUrl(Uri uri) {
    final params = Map<String, String>.from(uri.queryParameters);
    if (params.containsKey('token')) params['token'] = '***';
    return uri.replace(queryParameters: params).toString();
  }

  static List<EodBar> _sortedBars(List<EodBar> bars) {
    final byDate = <String, EodBar>{};
    for (final bar in bars) {
      if (bar.date.isEmpty || bar.close <= 0) continue;
      byDate[bar.date] = bar;
    }
    final dates = byDate.keys.toList()..sort();
    return dates.map((d) => byDate[d]!).toList();
  }

  static DateTime? _parseBarDate(String date) {
    try {
      final parts = date.split('-');
      if (parts.length < 3) return null;
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (_) {
      return null;
    }
  }

  static String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _previousTradingDayIso(String isoDate) {
    final d = _parseBarDate(isoDate);
    if (d == null) return '';
    var prev = d.subtract(const Duration(days: 1));
    while (prev.weekday == DateTime.saturday ||
        prev.weekday == DateTime.sunday) {
      prev = prev.subtract(const Duration(days: 1));
    }
    return _isoDate(prev);
  }

  static List<EodBar> barsFromQuote(StockQuote q) {
    final sym = q.symbol.toUpperCase();
    final out = <EodBar>[];
    if (q.date.isNotEmpty && q.close > 0) {
      out.add(EodBar(symbol: sym, date: q.date, close: q.close));
    }
    if (q.previousClose != null &&
        q.previousClose! > 0 &&
        q.date.isNotEmpty) {
      final prevDate = _previousTradingDayIso(q.date);
      if (prevDate.isNotEmpty) {
        out.add(
          EodBar(symbol: sym, date: prevDate, close: q.previousClose!),
        );
      }
    }
    return out;
  }

  static Map<String, List<EodBar>> _mergeHistorySources(
    Map<String, List<EodBar>> base,
    Map<String, List<EodBar>> incoming,
  ) {
    if (incoming.isEmpty) return base;
    final merged = Map<String, List<EodBar>>.from(base);
    for (final entry in incoming.entries) {
      final key = entry.key.toUpperCase();
      final inc = _sortedBars(entry.value);
      if (inc.isEmpty) continue;
      final prev = merged[key];
      merged[key] = _sortedBars([...(prev ?? const []), ...inc]);
    }
    return merged;
  }

  static Future<Map<String, List<EodBar>>> _loadQuoteHistoryLedger() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_prefsQuoteHistoryKey);
      if (str == null) return {};
      final raw = jsonDecode(str) as Map<String, dynamic>;
      final result = <String, List<EodBar>>{};
      for (final entry in raw.entries) {
        final list = entry.value as List<dynamic>;
        final bars = list
            .map((e) => EodBar.fromJson(e as Map<String, dynamic>))
            .where((b) => b.symbol.isNotEmpty && b.close > 0)
            .toList();
        if (bars.isNotEmpty) {
          result[entry.key.toUpperCase()] = _sortedBars(bars);
        }
      }
      return result;
    } catch (e) {
      debugPrint('[Finnhub] quote history ledger load failed: $e');
      return {};
    }
  }

  static Future<void> _saveQuoteHistoryLedger(
    Map<String, List<EodBar>> ledger,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = <String, dynamic>{};
      for (final entry in ledger.entries) {
        final bars = _sortedBars(entry.value);
        if (bars.isEmpty) continue;
        encoded[entry.key] = bars
            .map((b) => {
                  'symbol': b.symbol,
                  'date': b.date,
                  'close': b.close,
                })
            .toList();
      }
      if (encoded.isEmpty) {
        await prefs.remove(_prefsQuoteHistoryKey);
        return;
      }
      await prefs.setString(_prefsQuoteHistoryKey, jsonEncode(encoded));
    } catch (e) {
      debugPrint('[Finnhub] quote history ledger save failed: $e');
    }
  }

  static Future<Map<String, List<EodBar>>> recordQuoteHistoryFromQuotes(
    List<StockQuote> quotes,
  ) async {
    if (quotes.isEmpty) return _loadQuoteHistoryLedger();
    final ledger = await _loadQuoteHistoryLedger();
    var changed = false;
    for (final q in quotes) {
      final sym = q.symbol.toUpperCase();
      final incoming = _sortedBars(barsFromQuote(q));
      if (incoming.isEmpty) continue;
      final existing = ledger[sym] ?? const [];
      final merged = _sortedBars([...existing, ...incoming]);
      if (merged.length != existing.length ||
          (merged.isNotEmpty &&
              existing.isNotEmpty &&
              merged.last.close != existing.last.close)) {
        ledger[sym] = merged;
        changed = true;
      }
    }
    if (changed) await _saveQuoteHistoryLedger(ledger);
    return ledger;
  }

  static Future<Map<String, List<EodBar>>?> _loadHistoryWithLegacyFallback(
    int daysBack,
  ) async {
    final fh = await _loadHistoryFromPrefs(
      daysBack,
      prefix: _prefsHistoryPrefix,
    );
    final legacy = await _loadHistoryFromPrefs(
      daysBack,
      prefix: _legacyHistoryPrefix,
    );
    if (fh == null && legacy == null) return null;

    final merged = combineHistoryMaps(fh, legacy);
    if (merged.isEmpty) return null;

    final legacyScore = _historyScore(legacy ?? {}, kChartSymbols);
    final fhScore = _historyScore(fh ?? {}, kChartSymbols);
    if (legacy != null && legacy.isNotEmpty && legacyScore > fhScore) {
      debugPrint(
        '[Finnhub] restored legacy cached history ($daysBack days, '
        'AAPL=${closesForSymbol(merged, 'AAPL').length} '
        'TSLA=${closesForSymbol(merged, 'TSLA').length} '
        'AMZN=${closesForSymbol(merged, 'AMZN').length})',
      );
      await _saveHistoryToPrefs(merged, daysBack);
    }

    return merged;
  }

  static Future<({List<EodBar> bars, StockQuote? quote})>
      _fetchDailySeriesFallback(String sym) async {
    final ledger = await _loadQuoteHistoryLedger();
    final fromPrefs = await _loadHistoryWithLegacyFallback(_candleHistoryDays);
    var bars = <EodBar>[];
    if (fromPrefs?[sym] != null) {
      bars = _sortedBars(fromPrefs![sym]!);
    }
    if (ledger[sym] != null) {
      bars = _sortedBars([...bars, ...ledger[sym]!]);
    }
    if (bars.length < 2) {
      throw Exception(
        'No cached Finnhub history for $sym (candle endpoint unavailable)',
      );
    }
    debugPrint('[Finnhub] $sym fallback history bars: ${bars.length}');
    return (bars: bars, quote: _quoteFromBars(sym, bars));
  }

  static List<String> _expandChartSymbols(List<String> symbols) {
    final set = {for (final s in kChartSymbols) s.toUpperCase()};
    for (final s in symbols) {
      if (s.isNotEmpty) set.add(s.toUpperCase());
    }
    return set.toList()..sort();
  }

  static Map<String, List<EodBar>> _pickSymbols(
    Map<String, List<EodBar>> history,
    List<String> symbols,
  ) {
    final out = <String, List<EodBar>>{};
    for (final sym in symbols) {
      final upper = sym.toUpperCase();
      final bars = history[upper];
      if (bars != null && bars.isNotEmpty) {
        out[upper] = _sortedBars(bars);
      }
    }
    return out;
  }

  static StockQuote? _quoteFromBars(String symbol, List<EodBar> bars) {
    final sorted = _sortedBars(bars);
    if (sorted.isEmpty) return null;
    final last = sorted.last;
    final prev = sorted.length >= 2 ? sorted[sorted.length - 2] : null;
    final pc = prev?.close;
    final pct = pc != null && pc > 0
        ? ((last.close - pc) / pc) * 100
        : 0.0;
    return StockQuote(
      symbol: symbol.toUpperCase(),
      close: last.close,
      open: last.close,
      high: last.close,
      low: last.close,
      changePercent: pct,
      isPositive: pct >= 0,
      date: last.date,
      previousClose: pc,
    );
  }

  static List<StockQuote> _quotesFromHistory(
    Map<String, List<EodBar>> history,
    List<String> symbols,
  ) {
    final out = <StockQuote>[];
    for (final sym in symbols) {
      final bars = history[sym.toUpperCase()];
      if (bars == null) continue;
      final q = _quoteFromBars(sym, bars);
      if (q != null && q.close > 0) out.add(q);
    }
    return out;
  }

  static Future<({List<EodBar> bars, StockQuote? quote})> _fetchDailySeries(
    String symbol,
  ) async {
    final sym = symbol.toUpperCase();
    if (_dailyFutures.containsKey(sym)) {
      return _dailyFutures[sym]!;
    }

    final future = _fetchDailySeriesImpl(sym);
    _dailyFutures[sym] = future;
    try {
      return await future;
    } finally {
      _dailyFutures.remove(sym);
    }
  }

  static Future<({List<EodBar> bars, StockQuote? quote})>
      _fetchDailySeriesImpl(String sym) async {
    if (_candleAccessDenied == true) {
      return _fetchDailySeriesFallback(sym);
    }

    await _throttle();
    final now = DateTime.now();
    final to = now.millisecondsSinceEpoch ~/ 1000;
    final from = now
        .subtract(const Duration(days: _candleHistoryDays))
        .millisecondsSinceEpoch ~/
        1000;
    final uri = Uri.parse(
      '$_base/stock/candle?symbol=$sym&resolution=D&from=$from&to=$to&token=$_apiKey',
    );
    _recordApiRequest('candle', sym);
    debugPrint(
      '[Finnhub] GET candle $sym ${sanitizeUrl(uri)} from=$from to=$to',
    );

    final parseSw = Stopwatch()..start();
    final response = await http
        .get(uri, headers: {'User-Agent': 'ClarivoApp/1.0'})
        .timeout(_historyTimeout);

    if (response.statusCode == 403) {
      _candleAccessDenied = true;
      debugPrint(
        '[Finnhub] CANDLE $sym HTTP 403 — premium endpoint required. '
        'body=${response.body}',
      );
      return _fetchDailySeriesFallback(sym);
    }

    if (response.statusCode != 200) {
      debugPrint(
        '[Finnhub] CANDLE $sym HTTP ${response.statusCode} body=${response.body}',
      );
      return _fetchDailySeriesFallback(sym);
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    _logRawResponse('candle', sym, json);
    _logTiming('candle parse $sym', parseSw);

    final status = json['s']?.toString() ?? '';
    if (status != 'ok') {
      debugPrint('[Finnhub] CANDLE $sym s=$status body=${response.body}');
      if (json.containsKey('error')) {
        debugPrint('[Finnhub] CANDLE $sym error=${json['error']}');
      }
      return _fetchDailySeriesFallback(sym);
    }

    final timestamps = json['t'] as List<dynamic>? ?? [];
    final closes = json['c'] as List<dynamic>? ?? [];
    if (timestamps.length < 2 || closes.length < 2) {
      debugPrint(
        '[Finnhub] CANDLE $sym insufficient arrays '
        't=${timestamps.length} c=${closes.length}',
      );
      return _fetchDailySeriesFallback(sym);
    }

    final bars = <EodBar>[];
    final len =
        timestamps.length < closes.length ? timestamps.length : closes.length;
    for (var i = 0; i < len; i++) {
      final tsRaw = timestamps[i];
      final closeRaw = closes[i];
      final unix = tsRaw is int ? tsRaw : int.tryParse(tsRaw.toString()) ?? 0;
      final close = closeRaw is num
          ? closeRaw.toDouble()
          : double.tryParse(closeRaw.toString()) ?? 0;
      if (unix <= 0 || close <= 0) continue;
      bars.add(EodBar(symbol: sym, date: _unixToDate(unix), close: close));
    }

    final sorted = _sortedBars(bars);
    if (sorted.length < 2) {
      return _fetchDailySeriesFallback(sym);
    }

    final quote = _quoteFromBars(sym, sorted);

    debugPrint('[Finnhub] $sym candle bars: ${sorted.length}');
    await _clearRateLimitFlag();
    return (bars: sorted, quote: quote);
  }

  static Future<StockQuote?> _fetchFinnhubQuote(String symbol) async {
    final sym = symbol.toUpperCase();
    await _throttle();
    final uri = Uri.parse('$_base/quote?symbol=$sym&token=$_apiKey');
    _recordApiRequest('quote', sym);
    debugPrint('[Finnhub] GET quote $sym ${sanitizeUrl(uri)}');

    final response = await http
        .get(uri, headers: {'User-Agent': 'ClarivoApp/1.0'})
        .timeout(_quoteTimeout);

    if (response.statusCode != 200) return null;

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      _logRawResponse('quote', sym, json);
      _checkFinnhubError(json, response.statusCode);
      final close = StockQuote._num(json['c']);
      if (close <= 0) return null;
      final q = normalizeDailyChange(StockQuote.fromFinnhubQuote(sym, json));
      await _clearRateLimitFlag();
      return q;
    } catch (e) {
      debugPrint('[Finnhub] Quote parse error $sym: $e');
      return null;
    }
  }

  static Future<StockQuote?> _fetchGlobalQuote(String symbol) async {
    return _fetchFinnhubQuote(symbol);
  }

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
                'changePercent': q.changePercent,
                'date': q.date,
                if (q.volume != null) 'volume': q.volume,
                if (q.previousClose != null) 'previousClose': q.previousClose,
              })
          .toList();
      await prefs.setString(_prefsQuotesKey, jsonEncode(data));
      await prefs.setString(
          _prefsCacheDateKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('[Finnhub] Failed to persist quotes: $e');
    }
  }

  static Future<List<StockQuote>?> _loadQuotesFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var str = prefs.getString(_prefsQuotesKey);
      if (str == null) {
        str = prefs.getString(_legacyQuotesKey);
        if (str != null) {
          debugPrint('[Finnhub] loaded legacy cached quotes');
        }
      }
      if (str == null) return null;
      final list = jsonDecode(str) as List<dynamic>;
      final quotes = list
          .map((e) =>
              normalizeDailyChange(StockQuote.fromJson(e as Map<String, dynamic>)))
          .where((q) => q.symbol.isNotEmpty && q.close > 0)
          .toList();
      return quotes.isEmpty ? null : quotes;
    } catch (e) {
      debugPrint('[Finnhub] Failed to load quotes from prefs: $e');
      return null;
    }
  }

  static Future<DateTime?> _loadCacheDateFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_prefsCacheDateKey);
      return str != null ? DateTime.parse(str) : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _saveHistoryToPrefs(
    Map<String, List<EodBar>> history,
    int daysBack,
  ) async {
    try {
      final existing = combineHistoryMaps(
        await _loadHistoryFromPrefs(daysBack),
        await _loadHistoryFromPrefs(
          daysBack,
          prefix: _legacyHistoryPrefix,
        ),
      );
      final merged = Map<String, List<EodBar>>.from(existing);
      for (final entry in history.entries) {
        final incoming = _sortedBars(entry.value);
        if (incoming.length < 2) continue;
        final key = entry.key.toUpperCase();
        final prev = merged[key];
        merged[key] = _sortedBars([...(prev ?? const []), ...incoming]);
      }
      if (!historyHasWavyChartData(merged, kChartSymbols)) return;

      final prefs = await SharedPreferences.getInstance();
      final encoded = <String, dynamic>{};
      for (final entry in merged.entries) {
        final bars = _sortedBars(entry.value);
        if (bars.length < 2) continue;
        encoded[entry.key] = bars
            .map((b) => {
                  'symbol': b.symbol,
                  'date': b.date,
                  'close': b.close,
                })
            .toList();
      }
      if (encoded.isEmpty) return;
      await prefs.setString(
        '$_prefsHistoryPrefix$daysBack',
        jsonEncode(encoded),
      );
    } catch (e) {
      debugPrint('[Finnhub] Failed to persist history: $e');
    }
  }

  static Future<Map<String, List<EodBar>>?> _loadHistoryFromPrefs(
    int daysBack, {
    String prefix = _prefsHistoryPrefix,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('$prefix$daysBack');
      if (str == null) return null;
      final raw = jsonDecode(str) as Map<String, dynamic>;
      final result = <String, List<EodBar>>{};
      for (final entry in raw.entries) {
        final list = entry.value as List<dynamic>;
        final bars = list
            .map((e) => EodBar.fromJson(e as Map<String, dynamic>))
            .where((b) => b.symbol.isNotEmpty && b.close > 0)
            .toList();
        if (bars.isNotEmpty) {
          result[entry.key.toUpperCase()] = _sortedBars(bars);
        }
      }
      return result.isEmpty ? null : result;
    } catch (e) {
      debugPrint('[Finnhub] Failed to load history from prefs ($prefix): $e');
      return null;
    }
  }

  static void _mergeIntoHistoryCache(
    Map<String, List<EodBar>> incoming,
    int daysBack,
  ) {
    final merged = Map<String, List<EodBar>>.from(_historyCache ?? {});
    for (final entry in incoming.entries) {
      final key = entry.key.toUpperCase();
      final incomingBars = _sortedBars(entry.value);
      if (incomingBars.isEmpty) continue;
      final existing = merged[key];
      merged[key] = _sortedBars([...(existing ?? const []), ...incomingBars]);
    }
    _historyCache = merged;
    _historyCacheAt = DateTime.now();
    _historyCacheVersionAt = _historyCacheVersion;
    if (_historyCacheDays == null || daysBack > _historyCacheDays!) {
      _historyCacheDays = daysBack;
    }
  }

  static Map<String, List<EodBar>>? _sliceHistoryFromCache(
    List<String> symbols,
    int daysBack,
  ) {
    if (_historyCache == null || _historyCache!.isEmpty) return null;
    if (_historyCacheVersionAt != _historyCacheVersion) return null;
    if (_historyCacheAt == null ||
        DateTime.now().difference(_historyCacheAt!) >= _historyTtl) {
      return null;
    }
    final trimmed = trimHistoryToDaysBack(_historyCache!, daysBack);
    final out = <String, List<EodBar>>{};
    for (final sym in symbols) {
      final upper = sym.toUpperCase();
      final bars = trimmed[upper];
      if (bars == null || _sortedBars(bars).length < 2) continue;
      out[upper] = _sortedBars(bars);
    }
    return out.isEmpty ? null : out;
  }

  static void _storeQuotes(List<StockQuote> quotes) {
    _cache = quotes.map(normalizeDailyChange).toList();
    _cacheAt = DateTime.now();
    _quoteCacheVersionAt = _quoteCacheVersion;
    lastFetchFromCache = false;
    lastQuoteSource = QuoteDataSource.finnhub;
  }

  static List<StockQuote> _dedupeQuotes(List<StockQuote> quotes) {
    final bySym = <String, StockQuote>{};
    for (final q in quotes) {
      if (q.symbol.isEmpty || q.close <= 0) continue;
      bySym[q.symbol.toUpperCase()] = q;
    }
    return bySym.values.toList();
  }

  // ── Public chart / portfolio helpers (unchanged contract) ───────────────

  static String chartPeriodLabel(int daysBack) {
    if (daysBack <= 7) return '1W';
    if (daysBack <= 14) return '2W';
    if (daysBack <= 30) return '1M';
    if (daysBack <= 45) return '2M';
    if (daysBack <= 90) return '3M';
    return '${daysBack}D';
  }

  static List<StockQuote> deriveQuotesFromHistory(
    Map<String, List<EodBar>> history,
    List<String> symbols,
  ) =>
      _quotesFromHistory(history, symbols);

  static StockQuote normalizeDailyChange(StockQuote q) {
    if (q.previousClose != null && q.previousClose! > 0) {
      final pct =
          ((q.close - q.previousClose!) / q.previousClose!.abs()) * 100;
      return StockQuote(
        symbol: q.symbol,
        close: q.close,
        open: q.open,
        high: q.high,
        low: q.low,
        changePercent: pct,
        isPositive: pct >= 0,
        date: q.date,
        volume: q.volume,
        previousClose: q.previousClose,
      );
    }
    return q;
  }

  static Map<String, StockQuote> enrichQuotesFromHistory(
    Map<String, StockQuote> quotes,
    Map<String, List<EodBar>> history,
  ) {
    final out = <String, StockQuote>{};
    for (final entry in quotes.entries) {
      var q = normalizeDailyChange(entry.value);
      if (q.previousClose == null || q.previousClose! <= 0) {
        final bars = history[entry.key.toUpperCase()] ?? [];
        final sorted = _sortedBars(bars);
        if (sorted.length >= 2) {
          q = normalizeDailyChange(StockQuote(
            symbol: q.symbol,
            close: q.close,
            open: q.open,
            high: q.high,
            low: q.low,
            changePercent: q.changePercent,
            isPositive: q.isPositive,
            date: q.date,
            volume: q.volume,
            previousClose: sorted[sorted.length - 2].close,
          ));
        }
      }
      out[entry.key.toUpperCase()] = q;
    }
    return out;
  }

  static double portfolioDailyGain(
    Map<String, StockQuote> quotes,
    Map<String, int> shares,
  ) {
    var gain = 0.0;
    for (final e in shares.entries) {
      final q = quotes[e.key.toUpperCase()] ?? quotes[e.key];
      if (q == null) continue;
      gain += q.dailyChangeAmount * e.value;
    }
    return gain;
  }

  static double portfolioPreviousValue(
    Map<String, StockQuote> quotes,
    Map<String, int> shares,
  ) {
    var prev = 0.0;
    for (final e in shares.entries) {
      final q = quotes[e.key.toUpperCase()] ?? quotes[e.key];
      if (q == null) continue;
      final base = q.previousClose != null && q.previousClose! > 0
          ? q.previousClose!
          : q.open;
      prev += base * e.value;
    }
    return prev;
  }

  static List<double> chartClosesWithLatest(
    Map<String, List<EodBar>> history,
    String symbol,
    StockQuote? quote,
  ) {
    final sym = symbol.toUpperCase();
    final bars = _sortedBars(history[sym] ?? history[symbol] ?? []);
    final closes = bars.map((b) => b.close).toList();

    if (closes.isEmpty) {
      if (quote != null && quote.close > 0) return [quote.close];
      return closes;
    }

    if (quote != null &&
        quote.close > 0 &&
        quote.date.isNotEmpty &&
        bars.isNotEmpty &&
        bars.last.date == quote.date &&
        (closes.last - quote.close).abs() > 0.005) {
      closes[closes.length - 1] = quote.close;
    }

    if (closes.length >= 2) return closes;
    if (quote != null && quote.close > 0) return [quote.close];
    return closes;
  }

  static List<double> portfolioChartWithLatest(
    Map<String, List<EodBar>> history,
    Map<String, int> shares,
    Map<String, StockQuote> quotes,
  ) {
    return portfolioTotalsByDate(history, shares);
  }

  static Map<String, List<EodBar>> trimHistoryToDaysBack(
    Map<String, List<EodBar>> history,
    int daysBack,
  ) {
    if (daysBack <= 0 || history.isEmpty) return history;
    final out = <String, List<EodBar>>{};
    for (final entry in history.entries) {
      final sorted = _sortedBars(entry.value);
      if (sorted.isEmpty) continue;
      final newest = _parseBarDate(sorted.last.date);
      if (newest == null) {
        out[entry.key] = sorted;
        continue;
      }
      final cutoff = newest.subtract(Duration(days: daysBack));
      final trimmed = sorted.where((b) {
        final d = _parseBarDate(b.date);
        return d != null && !d.isBefore(cutoff);
      }).toList();
      if (trimmed.isNotEmpty) out[entry.key] = trimmed;
    }
    return out;
  }

  static List<double> closesForSymbol(
    Map<String, List<EodBar>> history,
    String symbol,
  ) {
    final sym = symbol.toUpperCase();
    final bars = history[sym] ?? history[symbol];
    if (bars == null || bars.isEmpty) return [];
    return _sortedBars(bars).map((b) => b.close).toList();
  }

  static List<double> portfolioTotalsByDate(
    Map<String, List<EodBar>> history,
    Map<String, int> shares,
  ) {
    final held = shares.entries
        .where((e) => e.value > 0)
        .map((e) => e.key.toUpperCase())
        .toList();
    if (held.isEmpty) return [];

    final closesBySymbolDate = <String, Map<String, double>>{};
    for (final sym in held) {
      final bars = history[sym] ?? history[sym.toUpperCase()] ?? [];
      final byDate = <String, double>{};
      for (final bar in _sortedBars(bars)) {
        if (bar.date.isNotEmpty && bar.close > 0) {
          byDate[bar.date] = bar.close;
        }
      }
      if (byDate.isEmpty) return [];
      closesBySymbolDate[sym] = byDate;
    }

    final commonDates = closesBySymbolDate.values
        .map((m) => m.keys.toSet())
        .reduce((a, b) => a.intersection(b))
        .toList()
      ..sort();

    return commonDates.map((date) {
      var total = 0.0;
      for (final sym in held) {
        total += closesBySymbolDate[sym]![date]! * shares[sym]!;
      }
      return total;
    }).toList();
  }

  static ChartSeries stockChartSeries(
    Map<String, List<EodBar>> history,
    String symbol,
    StockQuote? quote, {
    String context = '',
    String periodLabel = '',
  }) {
    final sym = symbol.toUpperCase();
    final closes = chartClosesWithLatest(history, sym, quote);
    if (closes.length >= minWavyChartPoints) {
      return ChartSeries(
        points: closes,
        mode: ChartDataMode.historical,
        reason: 'Using ${closes.length} historical close prices for $sym',
        periodLabel: periodLabel,
      );
    }
    if (closes.length >= 2) {
      return ChartSeries(
        points: [],
        mode: ChartDataMode.unavailable,
        reason:
            'Only ${closes.length} close points for $sym — need $minWavyChartPoints+ for chart',
        periodLabel: periodLabel,
      );
    }
    return ChartSeries(
      points: [],
      mode: ChartDataMode.unavailable,
      reason: 'Insufficient historical data for $sym',
      periodLabel: periodLabel,
    );
  }

  static ChartSeries portfolioChartSeries(
    Map<String, List<EodBar>> history,
    Map<String, int> shares,
    Map<String, StockQuote> quotes, {
    String context = '',
    String periodLabel = '',
  }) {
    if (history.isNotEmpty) {
      final totals = portfolioChartWithLatest(history, shares, quotes);
      if (totals.length >= minWavyChartPoints) {
        return ChartSeries(
          points: totals,
          mode: ChartDataMode.historical,
          reason:
              'Using ${totals.length} aligned portfolio historical totals',
          periodLabel: periodLabel,
        );
      }
      if (totals.length >= 2) {
        return ChartSeries(
          points: [],
          mode: ChartDataMode.unavailable,
          reason:
              'Only ${totals.length} portfolio points — need $minWavyChartPoints+ for chart',
          periodLabel: periodLabel,
        );
      }
    }
    return ChartSeries(
      points: [],
      mode: ChartDataMode.unavailable,
      reason: 'Insufficient portfolio historical data',
      periodLabel: periodLabel,
    );
  }

  /// Clears in-memory session caches only — never deletes SharedPreferences.
  static void invalidateSessionCache() {
    _cache = null;
    _cacheAt = null;
    _historyCache = null;
    _historyCacheAt = null;
    _newsCache = null;
    _newsCacheAt = null;
  }

  /// Cached quotes, history, and news loaded from memory or SharedPreferences.
  static Future<({
    List<StockQuote>? quotes,
    Map<String, List<EodBar>>? history,
    List<NewsArticle>? news,
  })> warmSessionFromPrefs({
    int daysBack = homeHistoryDays,
  }) async {
    await _ensureRateLimitFlagLoaded();
    final sw = Stopwatch()..start();
    final results = await Future.wait<Object?>([
      warmQuotesFromPrefs(),
      warmHistoryFromPrefs(daysBack: daysBack),
      warmNewsFromPrefs(),
    ]);
    _logTiming('warmSessionFromPrefs', sw);
    return (
      quotes: results[0] as List<StockQuote>?,
      history: results[1] as Map<String, List<EodBar>>?,
      news: results[2] as List<NewsArticle>?,
    );
  }

  static Future<List<StockQuote>?> warmQuotesFromPrefs() async {
    if (_quotesCacheValid() && _cache != null && _cache!.isNotEmpty) {
      lastFetchFromCache = true;
      lastQuoteSource = QuoteDataSource.cache;
      return _cache;
    }

    final sw = Stopwatch()..start();
    final cached = await _loadQuotesFromPrefs();
    _logTiming('warmQuotesFromPrefs', sw);
    if (cached == null || cached.isEmpty) return null;
    _cache = cached;
    _cacheAt = DateTime.now();
    _quoteCacheVersionAt = _quoteCacheVersion;
    lastFetchFromCache = true;
    lastCacheDate = await _loadCacheDateFromPrefs();
    lastQuoteSource = QuoteDataSource.cache;
    return cached;
  }

  static Future<Map<String, List<EodBar>>?> _loadBestHistoryFromPrefs({
    List<String> symbols = const ['AAPL', 'TSLA', 'AMZN'],
    int? preferredDays,
  }) async {
    final dayKeys = <int>{?preferredDays, 45, 30, 14, 7}.toList()
      ..sort((a, b) => b.compareTo(a));

    Map<String, List<EodBar>>? best;
    var bestScore = -1;

    for (final days in dayKeys) {
      final cached = await _loadHistoryWithLegacyFallback(days);
      if (cached == null || cached.isEmpty) continue;
      if (!_historyHasChartData(cached, symbols)) continue;
      final score = _historyScore(cached, symbols);
      if (score > bestScore) {
        bestScore = score;
        best = cached;
      }
    }

    if (best != null && bestScore >= 2) {
      if (preferredDays != null) {
        return trimHistoryToDaysBack(best, preferredDays);
      }
      return best;
    }
    return null;
  }

  static Future<Map<String, List<EodBar>>?> warmHistoryFromPrefs({
    int daysBack = 45,
  }) async {
    final fromMemory = _sliceHistoryFromCache(kChartSymbols, daysBack);
    if (fromMemory != null) {
      lastHistoryFromCache = false;
      return fromMemory;
    }

    final sw = Stopwatch()..start();
    final cached =
        await _loadBestHistoryFromPrefs(preferredDays: daysBack);
    final ledger = await _loadQuoteHistoryLedger();
    var merged = cached ?? <String, List<EodBar>>{};
    if (ledger.isNotEmpty) {
      merged = _mergeHistorySources(merged, ledger);
    }
    _logTiming('warmHistoryFromPrefs', sw);
    if (merged.isEmpty || !_historyHasChartData(merged, kChartSymbols)) {
      return null;
    }
    final trimmed = trimHistoryToDaysBack(merged, daysBack);
    _mergeIntoHistoryCache(merged, daysBack);
    lastHistoryFromCache = true;
    return trimmed;
  }

  /// Single entry point for Home/Portfolio — dedupes concurrent callers.
  static Future<MarketBootstrapResult> bootstrapMarketData({
    int daysBack = homeHistoryDays,
    bool forceRefresh = false,
  }) async {
    await _ensureRateLimitFlagLoaded();
    if (!forceRefresh && _bootstrapInFlight != null) {
      _recordCacheHit('bootstrapMarketData in-flight');
      return _bootstrapInFlight!;
    }
    final future = _bootstrapMarketDataImpl(daysBack, forceRefresh);
    if (!forceRefresh) _bootstrapInFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_bootstrapInFlight, future)) {
        _bootstrapInFlight = null;
      }
    }
  }

  static Future<MarketBootstrapResult> _bootstrapMarketDataImpl(
    int daysBack,
    bool forceRefresh,
  ) async {
    if (forceRefresh && !_rateLimitActive) {
      invalidateSessionCache();
    }

    if (!forceRefresh) {
      final warm = await warmSessionFromPrefs(daysBack: daysBack);
      var hist = warm.history;
      if (hist == null || !_historyHasChartData(hist, kChartSymbols)) {
        final warmedH = await warmHistoryFromPrefs(daysBack: daysBack);
        if (warmedH != null) hist = warmedH;
      }
      if (hist != null && _historyHasChartData(hist, kChartSymbols)) {
        var quotes = warm.quotes ?? <StockQuote>[];
        if (quotes.isEmpty) {
          quotes = deriveQuotesFromHistory(hist, kChartSymbols);
        }
        if (quotes.isNotEmpty) {
          _storeQuotes(quotes);
          await _saveQuotesToPrefs(quotes);
        }
        _mergeIntoHistoryCache(hist, daysBack);
        _recordCacheHit('bootstrap warm session');
        return MarketBootstrapResult(
          history: trimHistoryToDaysBack(hist, daysBack),
          quotes: quotes,
          fromCache: true,
        );
      }
    }

    Map<String, List<EodBar>> history = {};
    final preLedger = await _loadQuoteHistoryLedger();
    if (preLedger.isNotEmpty) {
      history = _mergeHistorySources(history, preLedger);
    }
    try {
      history = await fetchWeeklyHistory(
        kChartSymbols,
        daysBack: daysBack,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      debugPrint('[Finnhub] bootstrap history error: $e');
      final warmed = await warmHistoryFromPrefs(daysBack: daysBack);
      if (warmed != null) {
        history = _mergeHistorySources(history, warmed);
      }
    }

    List<StockQuote> quotes = [];
    if (_cache != null && _cache!.isNotEmpty) {
      quotes = _cache!;
    } else {
      try {
        // Fetch live Finnhub quotes when cache is stale.
        quotes = await fetchLatest(kChartSymbols, forceRefresh: false);
      } catch (e) {
        debugPrint('[Finnhub] bootstrap quotes error: $e');
        final prefs = await _loadQuotesFromPrefs();
        if (prefs != null) quotes = prefs;
      }
    }

    if (quotes.isEmpty && _historyHasChartData(history, kChartSymbols)) {
      quotes = deriveQuotesFromHistory(history, kChartSymbols);
    }

    if (!_quotesCacheFresh() && !_rateLimitActive) {
      try {
        final live = await fetchLatest(kChartSymbols, forceRefresh: true);
        if (live.isNotEmpty) quotes = live;
      } catch (e) {
        debugPrint('[Finnhub] bootstrap live quotes error: $e');
      }
    }

    if (quotes.isNotEmpty) {
      _storeQuotes(quotes);
      await _saveQuotesToPrefs(quotes);
      final ledger = await recordQuoteHistoryFromQuotes(quotes);
      if (ledger.isNotEmpty) {
        history = _mergeHistorySources(history, ledger);
        _mergeIntoHistoryCache(history, daysBack);
        if (historyHasWavyChartData(history, kChartSymbols)) {
          await _saveHistoryToPrefs(
            trimHistoryToDaysBack(history, daysBack),
            daysBack,
          );
        }
      }
    }

    return MarketBootstrapResult(
      history: history,
      quotes: quotes,
      fromCache: lastFetchFromCache || lastHistoryFromCache,
    );
  }

  static Future<List<StockQuote>> fetchLatest(
    List<String> symbols, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _quotesInFlight != null) {
      _recordCacheHit('fetchLatest in-flight');
      return _quotesInFlight!;
    }
    final future = _fetchLatestImpl(symbols, forceRefresh: forceRefresh);
    if (!forceRefresh) _quotesInFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_quotesInFlight, future)) _quotesInFlight = null;
    }
  }

  static Future<List<StockQuote>> _fetchLatestImpl(
    List<String> symbols, {
    bool forceRefresh = false,
  }) async {
    await _ensureRateLimitFlagLoaded();
    final sw = Stopwatch()..start();
    final upper = symbols.map((s) => s.toUpperCase()).toList();

    if (!forceRefresh && _quotesCacheFresh()) {
      lastFetchFromCache = false;
      _recordCacheHit('fetchLatest memory TTL');
      _logTiming('fetchLatest cache-hit', sw);
      return _cache!;
    }

    if (_historyCacheFresh()) {
      final derived = _quotesFromHistory(_historyCache!, upper);
      if (derived.length >= upper.length) {
        final quotes =
            _dedupeQuotes(derived.map(normalizeDailyChange).toList());
        _storeQuotes(quotes);
        await _saveQuotesToPrefs(quotes);
        _logTiming('fetchLatest from-history', sw);
        return quotes;
      }
    }

    if (_historyCache != null && _historyCache!.isNotEmpty) {
      final derived = _quotesFromHistory(_historyCache!, upper);
      if (derived.isNotEmpty) {
        final bySym = <String, StockQuote>{};
        if (_cache != null) {
          for (final q in _cache!) {
            bySym[q.symbol.toUpperCase()] = q;
          }
        }
        for (final q in derived) {
          bySym[q.symbol.toUpperCase()] = normalizeDailyChange(q);
        }
        final quotes = _dedupeQuotes(bySym.values.toList());
        _storeQuotes(quotes);
        await _saveQuotesToPrefs(quotes);
        lastFetchFromCache = _rateLimitActive;
        _logTiming('fetchLatest partial-history', sw);
        return quotes;
      }
    }

    if (!forceRefresh && _quotesCacheValid() && _cache != null) {
      _recordCacheHit('fetchLatest stale memory');
      lastFetchFromCache = true;
      lastQuoteSource = QuoteDataSource.cache;
      return _cache!;
    }

    final cached = await _loadQuotesFromPrefs();
    if (cached != null && cached.isNotEmpty) {
      _cache = cached;
      _cacheAt = DateTime.now();
      _quoteCacheVersionAt = _quoteCacheVersion;
      lastFetchFromCache = true;
      lastQuoteSource = QuoteDataSource.cache;
      lastCacheDate = await _loadCacheDateFromPrefs();
      _recordCacheHit('fetchLatest prefs');
      _logTiming('fetchLatest prefs-fallback', sw);
      return cached;
    }

    if (_rateLimitActive || !forceRefresh) {
      _logTiming('fetchLatest no-network', sw);
      throw Exception('No market data available from Finnhub.');
    }

    if (forceRefresh) {
      _cache = null;
      _cacheAt = null;
    }

    final quoteResults = await Future.wait(
      upper.map((sym) async {
        try {
          return await _fetchGlobalQuote(sym);
        } catch (e) {
          debugPrint('[Finnhub] Quote failed for $sym: $e');
          return null;
        }
      }),
    );
    final quotes = <StockQuote>[];
    for (final q in quoteResults) {
      if (q != null) quotes.add(q);
    }

    final result = _dedupeQuotes(quotes.map(normalizeDailyChange).toList());
    if (result.isNotEmpty) {
      _storeQuotes(result);
      await _saveQuotesToPrefs(result);
      await recordQuoteHistoryFromQuotes(result);
      _logTiming('fetchLatest network', sw);
      return result;
    }

    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    _logTiming('fetchLatest failed', sw);
    throw Exception('No market data available from Finnhub.');
  }

  static Future<Map<String, List<EodBar>>> fetchWeeklyHistory(
    List<String> symbols, {
    int daysBack = 45,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _historyInFlight != null) {
      _recordCacheHit('fetchWeeklyHistory in-flight');
      final full = await _historyInFlight!;
      return _pickSymbols(full, symbols);
    }
    final future = _fetchWeeklyHistoryImpl(
      symbols,
      daysBack: daysBack,
      forceRefresh: forceRefresh,
    );
    if (!forceRefresh) _historyInFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_historyInFlight, future)) _historyInFlight = null;
    }
  }

  static Future<Map<String, List<EodBar>>> _fetchWeeklyHistoryImpl(
    List<String> symbols, {
    int daysBack = 45,
    bool forceRefresh = false,
  }) async {
    await _ensureRateLimitFlagLoaded();
    final sw = Stopwatch()..start();
    final fetchSymbols = _expandChartSymbols(symbols);

    if (!forceRefresh) {
      final sliced = _sliceHistoryFromCache(symbols, daysBack);
      if (sliced != null) {
        lastHistoryFromCache = false;
        _recordCacheHit('fetchWeeklyHistory memory TTL');
        _logTiming('fetchWeeklyHistory memory-cache', sw);
        return sliced;
      }
    }

    final cached = await _loadBestHistoryFromPrefs(
      symbols: fetchSymbols,
      preferredDays: daysBack,
    );
    if (!forceRefresh &&
        cached != null &&
        _historyHasChartData(cached, symbols)) {
      final trimmed = trimHistoryToDaysBack(cached, daysBack);
      _mergeIntoHistoryCache(cached, daysBack);
      lastHistoryFromCache = true;
      _recordCacheHit('fetchWeeklyHistory prefs');
      _logTiming('fetchWeeklyHistory prefs-cache', sw);
      return _pickSymbols(trimmed, symbols);
    }

    var merged = await _baselineHistory(fetchSymbols, daysBack);
    final quoteLedger = await _loadQuoteHistoryLedger();
    if (quoteLedger.isNotEmpty) {
      merged = _mergeHistorySources(merged, quoteLedger);
    }
    if (_cache != null && _cache!.isNotEmpty) {
      final fromQuotes = await recordQuoteHistoryFromQuotes(_cache!);
      merged = _mergeHistorySources(merged, fromQuotes);
    }
    if (!forceRefresh && _historyHasChartData(merged, symbols)) {
      final trimmed = trimHistoryToDaysBack(merged, daysBack);
      _mergeIntoHistoryCache(merged, daysBack);
      _recordCacheHit('fetchWeeklyHistory baseline');
      _logTiming('fetchWeeklyHistory baseline-only', sw);
      return _pickSymbols(trimmed, symbols);
    }

    if (_rateLimitActive) {
      if (_historyHasChartData(merged, symbols)) {
        final trimmed = trimHistoryToDaysBack(merged, daysBack);
        _mergeIntoHistoryCache(merged, daysBack);
        lastHistoryFromCache = true;
        _logTiming('fetchWeeklyHistory rate-limit-cached', sw);
        return _pickSymbols(trimmed, symbols);
      }
      if (cached != null && _historyHasChartData(cached, symbols)) {
        final trimmed = trimHistoryToDaysBack(cached, daysBack);
        _mergeIntoHistoryCache(cached, daysBack);
        lastHistoryFromCache = true;
        return _pickSymbols(trimmed, symbols);
      }
      _logTiming('fetchWeeklyHistory rate-limit-no-data', sw);
      throw Exception(
        'Finnhub rate limit reached — no cached history for ${symbols.join(', ')}',
      );
    }

    // Fetch only symbols still missing after cache/baseline merge.
    final needFetch = fetchSymbols.where((sym) {
      final bars = merged[sym];
      return bars == null || _sortedBars(bars).length < 2;
    }).toList();

    if (needFetch.isEmpty && _historyHasChartData(merged, symbols)) {
      final trimmed = trimHistoryToDaysBack(merged, daysBack);
      _mergeIntoHistoryCache(merged, daysBack);
      _logTiming('fetchWeeklyHistory baseline-complete', sw);
      return _pickSymbols(trimmed, symbols);
    }

    final quoteUpdates = <StockQuote>[];
    var hitRateLimit = false;

    for (final sym in needFetch) {
      if (_rateLimitActive) {
        hitRateLimit = true;
        break;
      }
      try {
        final daily = await _fetchDailySeries(sym);
        if (daily.bars.isNotEmpty) {
          merged[sym] = daily.bars;
        }
        if (daily.quote != null) quoteUpdates.add(daily.quote!);
      } catch (e) {
        debugPrint('[Finnhub] History fetch failed for $sym: $e');
        if (e is FinnhubApiException && e.isRateLimit) {
          hitRateLimit = true;
          break;
        }
      }
    }

    _mergeIntoHistoryCache(merged, daysBack);

    if (_historyHasChartData(merged, symbols)) {
      final trimmed = trimHistoryToDaysBack(merged, daysBack);
      await _saveHistoryToPrefs(trimmed, daysBack);
      if (quoteUpdates.isNotEmpty) {
        _storeQuotes(_dedupeQuotes(quoteUpdates));
        await _saveQuotesToPrefs(_cache!);
        await recordQuoteHistoryFromQuotes(_cache!);
      }
      lastHistoryFromCache = hitRateLimit;
      _logTiming('fetchWeeklyHistory network', sw);
      debugPrint(
        '[Finnhub] history points AAPL=${closesForSymbol(trimmed, 'AAPL').length} '
        'TSLA=${closesForSymbol(trimmed, 'TSLA').length} '
        'AMZN=${closesForSymbol(trimmed, 'AMZN').length}',
      );
      return _pickSymbols(trimmed, symbols);
    }

    if (cached != null && _historyHasChartData(cached, symbols)) {
      final trimmed = trimHistoryToDaysBack(cached, daysBack);
      _mergeIntoHistoryCache(cached, daysBack);
      lastHistoryFromCache = true;
      _logTiming('fetchWeeklyHistory prefs-fallback', sw);
      return _pickSymbols(trimmed, symbols);
    }

    _logTiming('fetchWeeklyHistory failed', sw);
    throw Exception(
      'Finnhub history unavailable for ${symbols.join(', ')}',
    );
  }

  static NewsArticle? _parseFinnhubNewsItem(
    Map<String, dynamic> item, {
    required String fallbackSymbol,
  }) {
    final title = (item['headline'] as String? ?? '').trim();
    if (title.isEmpty) return null;
    final url = (item['url'] as String? ?? '').trim();
    if (url.isEmpty) return null;
    final summary = (item['summary'] as String? ?? '').trim();
    final source = (item['source'] as String? ?? 'News').trim();
    final datetimeRaw = item['datetime'];
    final unixSeconds = datetimeRaw is int
        ? datetimeRaw
        : int.tryParse(datetimeRaw?.toString() ?? '') ?? 0;
    return NewsArticle(
      title: title,
      source: source.isNotEmpty ? source : 'News',
      time: _formatNewsTimeFromUnix(unixSeconds),
      tag: _newsTagFromRelated(
        item['related'] as String? ?? '',
        fallbackSymbol: fallbackSymbol,
      ),
      summary: summary,
      url: url,
      imageUrl: _validImageUrl(item['image'] as String?),
    );
  }

  static Future<List<NewsArticle>> _fetchNewsImpl(int limit) async {
    if (_rateLimitActive) {
      final cached = await _loadNewsFromPrefs();
      return cached ?? _newsCache ?? [];
    }
    try {
      final now = DateTime.now();
      final fromStr = _formatFinnhubDate(now.subtract(const Duration(days: 7)));
      final toStr = _formatFinnhubDate(now);
      const perSymbol = 2;
      final merged = <({NewsArticle article, int publishedAt})>[];

      for (final symbol in kChartSymbols) {
        await _throttle();
        final uri = Uri.parse(
          '$_base/company-news?symbol=$symbol&from=$fromStr&to=$toStr&token=$_apiKey',
        );
        _recordApiRequest('news', symbol);
        debugPrint('[Finnhub] GET company-news $symbol ${sanitizeUrl(uri)}');

        final response = await http
            .get(uri, headers: {'User-Agent': 'ClarivoApp/1.0'})
            .timeout(_newsTimeout);

        if (response.statusCode != 200) {
          throw Exception('News HTTP ${response.statusCode}');
        }

        final body = response.body.trim();
        if (body.isEmpty) continue;

        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          _checkFinnhubError(decoded, response.statusCode);
          continue;
        }
        if (decoded is! List<dynamic>) continue;

        for (final item in decoded.take(perSymbol)) {
          if (item is! Map<String, dynamic>) continue;
          final article = _parseFinnhubNewsItem(item, fallbackSymbol: symbol);
          if (article == null) continue;
          final dtRaw = item['datetime'];
          final unix = dtRaw is int
              ? dtRaw
              : int.tryParse(dtRaw?.toString() ?? '') ?? 0;
          merged.add((article: article, publishedAt: unix));
        }
      }

      if (merged.isEmpty) {
        final cached = await _loadNewsFromPrefs();
        return cached ?? _newsCache ?? [];
      }

      merged.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      final articles =
          merged.take(limit).map((e) => e.article).toList(growable: false);

      _storeNewsCache(articles);
      await _saveNewsToPrefs(articles);
      await _clearRateLimitFlag();
      return articles;
    } catch (e) {
      debugPrint('[Finnhub] News fetch failed: $e');
    }

    final cached = await _loadNewsFromPrefs();
    if (cached != null && cached.isNotEmpty) {
      final cachedAt = await _loadNewsDateFromPrefs();
      _storeNewsCache(cached, at: cachedAt ?? _newsCacheAt);
      return cached;
    }

    return _newsCache ?? [];
  }

  static List<NewsArticle> _parseNewsArticles(List<dynamic> list) {
    return list
        .map((e) {
          final m = e as Map<String, dynamic>;
          return NewsArticle(
            title: m['title'] as String? ?? '',
            source: m['source'] as String? ?? '',
            time: m['time'] as String? ?? '',
            tag: m['tag'] as String? ?? 'MARKET',
            summary: m['summary'] as String? ?? '',
            url: m['url'] as String? ?? '',
            imageUrl: m['imageUrl'] as String?,
          );
        })
        .where((a) => a.title.isNotEmpty)
        .toList();
  }

  static Future<List<NewsArticle>?> _loadNewsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_prefsNewsKey);
      if (str == null) return null;
      final list = jsonDecode(str) as List<dynamic>;
      final articles = _parseNewsArticles(list);
      return articles.isEmpty ? null : articles;
    } catch (e) {
      debugPrint('[Finnhub] Failed to load news from prefs: $e');
      return null;
    }
  }

  static Future<DateTime?> _loadNewsDateFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_prefsNewsDateKey);
      return str != null ? DateTime.tryParse(str) : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _saveNewsToPrefs(List<NewsArticle> articles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsNewsKey,
        jsonEncode(articles
            .map((a) => {
                  'title': a.title,
                  'source': a.source,
                  'time': a.time,
                  'tag': a.tag,
                  'summary': a.summary,
                  'url': a.url,
                  'imageUrl': a.imageUrl,
                })
            .toList()),
      );
      await prefs.setString(
        _prefsNewsDateKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('[Finnhub] Failed to persist news: $e');
    }
  }

  static void _storeNewsCache(List<NewsArticle> articles, {DateTime? at}) {
    _newsCache = articles;
    _newsCacheAt = at ?? DateTime.now();
  }

  /// Loads persisted news into memory for instant UI display.
  static Future<List<NewsArticle>?> warmNewsFromPrefs() async {
    if (_newsCache != null &&
        _newsCache!.isNotEmpty &&
        _newsCacheAt != null &&
        DateTime.now().difference(_newsCacheAt!) < _newsTtl) {
      return _newsCache;
    }

    final articles = await _loadNewsFromPrefs();
    if (articles == null || articles.isEmpty) return null;

    final cachedAt = await _loadNewsDateFromPrefs();
    _storeNewsCache(articles, at: cachedAt ?? DateTime.now());
    debugPrint(
      '[Finnhub] warmNewsFromPrefs: ${articles.length} articles.',
    );
    return articles;
  }

  static Future<List<NewsArticle>> fetchNews({
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    await _ensureRateLimitFlagLoaded();

    if (!forceRefresh &&
        _newsCache != null &&
        _newsCacheAt != null &&
        DateTime.now().difference(_newsCacheAt!) < _newsTtl) {
      _recordCacheHit('fetchNews memory TTL');
      return _newsCache!;
    }

    if (!forceRefresh && _newsFetchFuture != null) {
      _recordCacheHit('fetchNews in-flight');
      return _newsFetchFuture!;
    }

    if (!forceRefresh) {
      final warmed = await warmNewsFromPrefs();
      if (warmed != null && warmed.isNotEmpty) {
        return warmed;
      }
      if (_rateLimitActive) {
        return _newsCache ?? [];
      }
    }

    if (_rateLimitActive && !forceRefresh) {
      final cached = await _loadNewsFromPrefs();
      return cached ?? _newsCache ?? [];
    }

    final future = _fetchNewsImpl(limit);
    if (!forceRefresh) {
      _newsFetchFuture = future;
    }
    try {
      return await future;
    } finally {
      if (identical(_newsFetchFuture, future)) {
        _newsFetchFuture = null;
      }
    }
  }

  static Future<List<NewsArticle>> fetchNewsForSymbol(
    String symbol, {
    int limit = 5,
  }) async {
    final sym = symbol.toUpperCase();
    final warmed = await warmNewsFromPrefs();
    if (warmed != null && warmed.isNotEmpty) {
      final filtered = warmed
          .where((a) => a.tag == sym || a.title.toUpperCase().contains(sym));
      if (filtered.isNotEmpty) {
        return filtered.take(limit).toList();
      }
    }
    final all = await fetchNews(limit: 50, forceRefresh: false);
    final filtered =
        all.where((a) => a.tag == sym || a.title.toUpperCase().contains(sym));
    if (filtered.isNotEmpty) {
      return filtered.take(limit).toList();
    }
    return all.take(limit).toList();
  }

  static void logChartPointsAudit({
    required String label,
    required List<double> points,
    String periodLabel = '',
    double? dailyPct,
    bool? dailyPositive,
    double? dailyGain,
  }) {
    if (!kDebugMode) return;
    final plotted = VisualChartTrend.trendFromVisualValues(points);
    debugPrint('[Audit][$label] source=${lastQuoteSource.name} '
        'historyFromCache=$lastHistoryFromCache '
        'points=${points.length} '
        'isUp=${plotted.isUp} pct=${plotted.formattedPercent}');
  }

  static void logStockAudit(
    String symbol,
    StockQuote? quote,
    List<double> chartCloses, {
    String chartPeriod = '',
  }) {
    if (!kDebugMode || quote == null) return;
    logChartPointsAudit(
      label: symbol,
      points: chartCloses,
      periodLabel: chartPeriod,
      dailyPct: quote.dailyChangePercentValue,
      dailyPositive: quote.isDailyPositive,
    );
  }

  static void logPortfolioAudit(
    List<double> chartTotals, {
    String chartPeriod = '',
    double? dailyGain,
  }) {
    if (!kDebugMode) return;
    logChartPointsAudit(
      label: 'PORTFOLIO',
      points: chartTotals,
      periodLabel: chartPeriod,
      dailyGain: dailyGain,
    );
  }

  static void debugLogChartCounts(
    Map<String, List<EodBar>> history,
    Map<String, int> shares,
    Map<String, StockQuote> quotes, {
    String screen = '',
  }) {
    if (!kDebugMode) return;
    final tag = screen.isEmpty ? 'Chart' : 'Chart][$screen';
    debugPrint('[$tag] history symbols: ${history.keys.join(', ')}');
    for (final sym in kChartSymbols) {
      final count = closesForSymbol(history, sym).length;
      debugPrint('[$tag] $sym chart points: $count');
    }
    final totals = portfolioTotalsByDate(history, shares);
    debugPrint('[$tag] portfolio chart points: ${totals.length}');
  }

  /// Exposed for unit tests only.
  @visibleForTesting
  static List<EodBar> barsFromQuoteForTest(StockQuote q) => barsFromQuote(q);

  @visibleForTesting
  static NewsArticle? mapArticleForTest(
    Map<String, dynamic> item, {
    required String fallbackSymbol,
  }) {
    return _parseFinnhubNewsItem(item, fallbackSymbol: fallbackSymbol);
  }
}
