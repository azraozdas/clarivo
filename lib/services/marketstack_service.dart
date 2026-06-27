import 'dart:async' show unawaited;
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
import 'package:flutter/material.dart' show Color;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/chart_trend.dart';

class StockQuote {
  final String symbol;
  final double close;
  final double open;
  final double high;
  final double low;
  final double changePercent;
  final bool isPositive;
  /// Trading date from API (YYYY-MM-DD) or empty when unavailable.
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
    return double.tryParse(v.toString()) ?? fallback;
  }

  static String _dateFromUnix(dynamic ts) {
    if (ts == null) return '';
    final sec = ts is num ? ts.toInt() : int.tryParse(ts.toString());
    if (sec == null || sec <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(sec * 1000, isUtc: true);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
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

  /// Builds a [StockQuote] from a Finnhub `/quote` response.
  factory StockQuote.fromFinnhub(String symbol, Map<String, dynamic> json) {
    final close = _num(json['c']);
    final open = _num(json['o'], close);
    final high = _num(json['h'], close);
    final low = _num(json['l'], close);
    final pct = _num(json['dp']);
    final pc = json['pc'] == null ? null : _num(json['pc']);
    return StockQuote(
      symbol: symbol.toUpperCase(),
      close: close,
      open: open,
      high: high,
      low: low,
      changePercent: pct,
      isPositive: pct >= 0,
      date: _dateFromUnix(json['t']),
      previousClose: pc,
    );
  }

  /// Builds a [StockQuote] from a Marketstack `/eod/latest` or `/eod` row.
  factory StockQuote.fromMarketstackEod(Map<String, dynamic> json) {
    final close = _num(json['close']);
    final open = _num(json['open'], close);
    final high = _num(json['high'], close);
    final low = _num(json['low'], close);
    final dateStr = json['date'] as String? ?? '';
    final symbol = (json['symbol'] as String? ?? '').toUpperCase();
    final vol = json['volume'];
    final pc = json['previousClose'];
    final previousClose = pc == null ? null : _num(pc);
    final pct = previousClose != null && previousClose > 0
        ? ((close - previousClose) / previousClose) * 100
        : (open != 0 ? ((close - open) / open) * 100 : 0.0);
    return StockQuote(
      symbol: symbol,
      close: close,
      open: open,
      high: high,
      low: low,
      changePercent: pct,
      isPositive: pct >= 0,
      date: dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr,
      volume: vol == null ? null : _num(vol),
      previousClose: previousClose,
    );
  }

  String get priceStr => '\$${close.toStringAsFixed(2)}';

  String get changeStr => dailyChangeStr;

  /// Display date — API value or `--` when missing.
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

  /// Daily move vs previous close when available, else vs session open.
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
    // Guard against empty/short date strings to avoid RangeError.
    final dateStr = json['date'] as String? ?? '';
    final rawSymbol = json['symbol'] as String? ?? '';
    return EodBar(
      symbol: rawSymbol.toUpperCase(),
      date: dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr,
      close: close,
    );
  }
}

/// Whether chart data came from live historical closes or is unavailable.
enum ChartDataMode { historical, unavailable }

/// Where the latest quote batch originated.
enum QuoteDataSource { marketstack, yahoo, finnhub, cache, unknown }

/// Resolved chart points plus mode/reason for debug logging.
class ChartSeries {
  final List<double> points;
  final ChartDataMode mode;
  final String reason;
  /// Human label for sparkline period, e.g. "2M". Use [displayPeriodLabel] in UI.
  final String? periodLabel;

  const ChartSeries({
    required this.points,
    required this.mode,
    required this.reason,
    this.periodLabel,
  });

  /// Never null — safe for widget parameters and after hot reload.
  String get displayPeriodLabel => periodLabel ?? '';
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
  /// Chart line/fill color follows plotted data trend (last − first).
  static bool chartTrendIsUp(List<double> points) =>
      ChartTrend.dataTrendIsUp(points);

  static Color chartColorFromPoints(List<double> points) =>
      ChartTrend.chartColorFromPoints(points);

  static Color chartColorFromMainPoints(List<double> points) =>
      ChartTrend.chartColorFromPoints(points);

  /// Logs chart mode, data values, both trends, API %, and chosen color.
  static void logChartValidation({
    required String symbol,
    required List<double> points,
    ChartDataMode? mode,
    StockQuote? quote,
    double? apiChangePercent,
    bool mainChartStyle = false,
  }) {
    logChartAudit(
      symbol: symbol,
      points: points,
      mode: mode,
      quote: quote,
      apiChangePercent: apiChangePercent,
      mainChartStyle: mainChartStyle,
    );
  }

  /// Full chart audit — proves data source, trend, and color decisions.
  static void logChartAudit({
    required String symbol,
    required List<double> points,
    ChartDataMode? mode,
    StockQuote? quote,
    double? apiChangePercent,
    bool mainChartStyle = false,
  }) {
    if (!kDebugMode) return;
    final modeLabel = switch (mode) {
      ChartDataMode.historical => 'HISTORICAL',
      ChartDataMode.unavailable => 'UNAVAILABLE',
      null => 'unknown',
    };

    final pct = apiChangePercent ?? quote?.changePercent;
    final chartUp = points.length >= 2 && ChartTrend.dataTrendIsUp(points);
    final pctUp = pct == null ? true : pct >= 0;

    debugPrint('[$symbol]');
    debugPrint('chartMode: $modeLabel');
    debugPrint('pointsCount: ${points.length}');
    if (points.isNotEmpty) {
      debugPrint(
          'points: [${points.map((p) => p.toStringAsFixed(2)).join(', ')}]');
      debugPrint('firstPoint: ${points.first.toStringAsFixed(2)}');
      debugPrint('lastPoint: ${points.last.toStringAsFixed(2)}');
      debugPrint(
          'chartTrend: ${ChartTrend.dataTrend(points).toStringAsFixed(4)}');
      debugPrint(
          'fullPeriodTrend: ${ChartTrend.dataTrend(points).toStringAsFixed(4)}');
      debugPrint(
          'lastSegmentTrend: ${ChartTrend.lastSegmentTrend(points).toStringAsFixed(4)}');
    } else {
      debugPrint('points: []');
      debugPrint('firstPoint: n/a');
      debugPrint('lastPoint: n/a');
      debugPrint('chartTrend: n/a');
      debugPrint('fullPeriodTrend: n/a');
      debugPrint('lastSegmentTrend: n/a');
    }
    if (quote != null) {
      debugPrint('apiOpen: ${quote.open.toStringAsFixed(2)}');
      debugPrint('apiClose: ${quote.close.toStringAsFixed(2)}');
      debugPrint('apiChangePercent: ${quote.changePercent.toStringAsFixed(2)}');
    } else {
      debugPrint('apiOpen: n/a');
      debugPrint('apiClose: n/a');
      debugPrint(
          'apiChangePercent: ${pct?.toStringAsFixed(2) ?? 'n/a'}');
    }
    debugPrint('selectedChartColor: ${chartUp ? 'green/teal' : 'red'}');
    debugPrint('selectedPercentColor: ${pctUp ? 'green/teal' : 'red'}');
    if (points.length >= 2) {
      debugPrint(
          'chartTrendPercent: ${ChartTrend.trendPercent(points).toStringAsFixed(2)}%');
    } else {
      debugPrint('chartTrendPercent: n/a');
    }
  }

  @Deprecated('Use logChartValidation')
  static void logChartColor({
    required String symbol,
    required List<double> points,
    double? apiChangePercent,
    ChartDataMode? mode,
    bool mainChartStyle = false,
  }) {
    logChartValidation(
      symbol: symbol,
      points: points,
      mode: mode,
      apiChangePercent: apiChangePercent,
      mainChartStyle: mainChartStyle,
    );
  }

  static const String _finnhubKey = 'd8vs3tpr01qgrv4qm9agd8vs3tpr01qgrv4qm9b0';
  static const String _marketstackKey = '8fbd57ac60ec1d5ad58e3b33e753234e';
  // Latest quotes: Finnhub HTTPS fallback when Marketstack quota is exhausted.
  static const String _finnhubBase = 'https://finnhub.io/api/v1';
  // Marketstack v1 — single version for latest + history (HTTP on free tier).
  static const String _marketstackV1 = 'http://api.marketstack.com/v1';
  // Yahoo Finance — free HTTPS historical + latest when Marketstack quota fails.
  static const String _yahooChartBase =
      'https://query1.finance.yahoo.com/v8/finance/chart';
  static const Map<String, String> _yahooHeaders = {
    'User-Agent': 'Mozilla/5.0 (compatible; ClarivoApp/1.0)',
  };
  static const String _proxyBase = 'http://localhost:8089';

  static String get _quoteBase => kIsWeb ? _proxyBase : _finnhubBase;
  static String get _marketstackBase => kIsWeb ? _proxyBase : _marketstackV1;

  // ── Persistent cache flags (set after each fetchLatest call) ────────────
  /// True when the last fetchLatest result came from SharedPreferences cache.
  static bool lastFetchFromCache = false;
  /// Which API supplied the active latest quotes.
  static QuoteDataSource lastQuoteSource = QuoteDataSource.unknown;
  /// Calendar days used for Home sparkline history.
  static const int homeHistoryDays = 45;
  /// Date when the currently active cached data was originally saved.
  static DateTime? lastCacheDate;

  /// True when the last history fetch came from SharedPreferences cache.
  static bool lastHistoryFromCache = false;

  // ── Persistent cache keys ────────────────────────────────────────────────
  static const String _prefsQuotesKey = 'mkt_quotes_v1';
  static const String _prefsCacheDateKey = 'mkt_quotes_date_v1';
  static const String _prefsHistoryPrefix = 'mkt_history_v1_';

  // ── Latest quotes in-memory cache ────────────────────────────────────────
  static List<StockQuote>? _cache;
  static DateTime? _cacheAt;
  static const Duration _cacheTtl = Duration(minutes: 5);
  static const int _quoteCacheVersion = 5;
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
                'changePercent': q.changePercent,
                'date': q.date,
                if (q.volume != null) 'volume': q.volume,
                if (q.previousClose != null) 'previousClose': q.previousClose,
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
          .map((e) => normalizeDailyChange(StockQuote.fromJson(e as Map<String, dynamic>)))
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

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Persists historical EOD bars so charts survive API quota limits.
  static Future<void> _saveHistoryToPrefs(
    Map<String, List<EodBar>> history,
    int daysBack,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = <String, dynamic>{};
      for (final entry in history.entries) {
        encoded[entry.key] = entry.value
            .map((b) => {
                  'symbol': b.symbol,
                  'date': b.date,
                  'close': b.close,
                })
            .toList();
      }
      await prefs.setString(
        '$_prefsHistoryPrefix$daysBack',
        jsonEncode(encoded),
      );
      debugPrint('[Marketstack] History persisted ($daysBack days).');
    } catch (e) {
      debugPrint('[Marketstack] Failed to persist history: $e');
    }
  }

  /// Loads previously saved historical bars for [daysBack], or null.
  static Future<Map<String, List<EodBar>>?> _loadHistoryFromPrefs(
    int daysBack,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('$_prefsHistoryPrefix$daysBack');
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
      debugPrint('[Marketstack] Failed to load persisted history: $e');
      return null;
    }
  }

  // ── Historical (EOD) cache ───────────────────────────────────────────────
  static Map<String, List<EodBar>>? _historyCache;
  static DateTime? _historyCacheAt;
  static int? _historyCacheDays;
  static const Duration _historyTtl = Duration(minutes: 30);
  static const int _historyCacheVersion = 7;
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

  static String chartPeriodLabel(int daysBack) {
    if (daysBack <= 7) return '1W';
    if (daysBack <= 14) return '2W';
    if (daysBack <= 30) return '1M';
    if (daysBack <= 45) return '2M';
    if (daysBack <= 90) return '3M';
    return '${daysBack}D';
  }

  /// Recomputes daily % from previous close when present.
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

  /// Fills missing previous close from the last two historical EOD bars.
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

  static void logStockAudit(
    String symbol,
    StockQuote? quote,
    List<double> chartCloses, {
    String chartPeriod = '',
  }) {
    if (!kDebugMode || quote == null) return;
    final chartUp = ChartTrend.dataTrendIsUp(chartCloses);
    debugPrint('[Audit][$symbol] source=${lastQuoteSource.name} '
        'price=${quote.close.toStringAsFixed(2)} '
        'prevClose=${quote.previousClose?.toStringAsFixed(2) ?? 'n/a'} '
        'dailyPct=${quote.dailyChangePercentValue.toStringAsFixed(2)}% '
        'dailyPositive=${quote.isDailyPositive} '
        'chartPeriod=$chartPeriod '
        'chartPoints=${chartCloses.length} '
        'chartFirst=${chartCloses.isNotEmpty ? chartCloses.first.toStringAsFixed(2) : 'n/a'} '
        'chartLast=${chartCloses.isNotEmpty ? chartCloses.last.toStringAsFixed(2) : 'n/a'} '
        'chartTrendPct=${chartCloses.length >= 2 ? ChartTrend.trendPercent(chartCloses).toStringAsFixed(2) : 'n/a'}% '
        'chartColor=${chartUp ? 'green' : 'red'}');
  }

  /// Historical closes plus today's latest price when it extends the series.
  static List<double> chartClosesWithLatest(
    Map<String, List<EodBar>> history,
    String symbol,
    StockQuote? quote,
  ) {
    final closes = List<double>.from(closesForSymbol(history, symbol));
    if (quote == null || quote.close <= 0) return closes;
    if (closes.isEmpty) return [quote.close];
    if ((closes.last - quote.close).abs() > 0.005) {
      closes.add(quote.close);
    }
    return closes;
  }

  /// Portfolio historical totals plus current live total when it differs.
  static List<double> portfolioChartWithLatest(
    Map<String, List<EodBar>> history,
    Map<String, int> shares,
    Map<String, StockQuote> quotes,
  ) {
    final totals = portfolioTotalsByDate(history, shares);
    if (totals.isEmpty) return totals;
    var liveTotal = 0.0;
    var hasLive = false;
    for (final e in shares.entries) {
      final q = quotes[e.key.toUpperCase()] ?? quotes[e.key];
      if (q == null || q.close <= 0) continue;
      hasLive = true;
      liveTotal += q.close * e.value;
    }
    if (!hasLive) return totals;
    final out = List<double>.from(totals);
    if ((out.last - liveTotal).abs() > 0.01) {
      out.add(liveTotal);
    }
    return out;
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

  static void _logChartMode(
    String context,
    String label,
    ChartDataMode mode,
    int pointCount,
    String reason,
  ) {
    if (!kDebugMode) return;
    final modeStr = switch (mode) {
      ChartDataMode.historical => 'HISTORICAL',
      ChartDataMode.unavailable => 'UNAVAILABLE',
    };
    debugPrint(
      '[Chart${context.isEmpty ? '' : '][$context'}] $label: '
      'mode=$modeStr points=$pointCount reason=$reason',
    );
  }

  static String _bodyPreview(String body, [int max = 1000]) =>
      body.length > max ? body.substring(0, max) : body;

  /// Hides API keys in logged URLs.
  static String sanitizeUrl(Uri uri) {
    final params = Map<String, String>.from(uri.queryParameters);
    if (params.containsKey('access_key')) params['access_key'] = '***';
    if (params.containsKey('token')) params['token'] = '***';
    return uri.replace(queryParameters: params).toString();
  }

  static void _logJsonSummary(String tag, http.Response response) {
    debugPrint('[$tag] URL resolved HTTP ${response.statusCode}');
    debugPrint('[$tag] body preview: ${_bodyPreview(response.body)}');
    try {
      final json = jsonDecode(response.body);
      if (json is Map<String, dynamic>) {
        debugPrint('[$tag] has data: ${json.containsKey('data')}');
        debugPrint('[$tag] has error: ${json.containsKey('error')}');
        if (json['error'] != null) {
          debugPrint('[$tag] Marketstack error: ${json['error']}');
        }
        if (json['data'] is List) {
          debugPrint('[$tag] data count: ${(json['data'] as List).length}');
        }
      }
    } catch (_) {
      debugPrint('[$tag] response is not JSON');
    }
  }

  /// Returns an ascending list of close prices for [symbol] from [history].
  static List<double> closesForSymbol(
    Map<String, List<EodBar>> history,
    String symbol,
  ) {
    final sym = symbol.toUpperCase();
    final bars = history[sym] ?? history[symbol];
    if (bars == null || bars.isEmpty) return [];
    return _sortedBars(bars).map((b) => b.close).toList();
  }

  /// Sums (close × shares) per calendar date where every held symbol has EOD data.
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

  /// Stock mini chart: real historical closes only (no synthetic 2-point lines).
  static ChartSeries stockChartSeries(
    Map<String, List<EodBar>> history,
    String symbol,
    StockQuote? quote, {
    String context = '',
    String periodLabel = '',
  }) {
    final sym = symbol.toUpperCase();
    final closes = chartClosesWithLatest(history, sym, quote);
    if (closes.length >= 2) {
      final reason =
          'Using ${closes.length} historical close prices for $sym';
      _logChartMode(context, sym, ChartDataMode.historical, closes.length, reason);
      return ChartSeries(
        points: closes,
        mode: ChartDataMode.historical,
        reason: reason,
        periodLabel: periodLabel,
      );
    }

    String histReason;
    if (history.isEmpty) {
      histReason = 'History map empty — API failed or not loaded yet';
    } else if (closes.isEmpty) {
      histReason =
          'No historical bars for $sym (history keys: ${history.keys.join(', ')})';
    } else {
      histReason =
          'Only ${closes.length} historical close(s) for $sym — need >= 2';
    }

    final reason = '$histReason → chart unavailable (no synthetic fallback)';
    _logChartMode(context, sym, ChartDataMode.unavailable, 0, reason);
    return ChartSeries(
      points: [],
      mode: ChartDataMode.unavailable,
      reason: reason,
      periodLabel: periodLabel,
    );
  }

  /// Portfolio main chart: historical totals from aligned EOD closes only.
  static ChartSeries portfolioChartSeries(
    Map<String, List<EodBar>> history,
    Map<String, int> shares,
    Map<String, StockQuote> quotes, {
    String context = '',
    String periodLabel = '',
  }) {
    if (history.isNotEmpty) {
      final totals = portfolioChartWithLatest(history, shares, quotes);
      if (totals.length >= 2) {
        final reason =
            'Using ${totals.length} aligned portfolio historical totals';
        _logChartMode(
          context,
          'PORTFOLIO',
          ChartDataMode.historical,
          totals.length,
          reason,
        );
        return ChartSeries(
          points: totals,
          mode: ChartDataMode.historical,
          reason: reason,
          periodLabel: periodLabel,
        );
      }
    }

    final histReason = history.isEmpty
        ? 'History map empty — API failed or not loaded yet'
        : 'Only ${portfolioTotalsByDate(history, shares).length} aligned '
            'portfolio point(s) — need >= 2';

    final reason = '$histReason → chart unavailable (no synthetic fallback)';
    _logChartMode(context, 'PORTFOLIO', ChartDataMode.unavailable, 0, reason);
    return ChartSeries(
      points: [],
      mode: ChartDataMode.unavailable,
      reason: reason,
      periodLabel: periodLabel,
    );
  }

  /// Sparkline: historical closes when available.
  static List<double> sparklinePoints(
    Map<String, List<EodBar>> history,
    String symbol,
    StockQuote? quote,
  ) =>
      stockChartSeries(history, symbol, quote).points;

  /// Main portfolio chart: aligned historical totals only.
  static List<double> portfolioChartPoints(
    Map<String, List<EodBar>> history,
    Map<String, int> shares,
    Map<String, StockQuote> quotes,
  ) =>
      portfolioChartSeries(history, shares, quotes).points;

  /// Debug helper — logs chart mode per symbol (debug mode only).
  static void debugLogChartCounts(
    Map<String, List<EodBar>> history,
    Map<String, int> shares,
    Map<String, StockQuote> quotes, {
    String screen = '',
  }) {
    if (!kDebugMode) return;
    debugPrint('[Chart${screen.isEmpty ? '' : '][$screen'}] '
        'history symbols loaded: ${history.keys.join(', ')}');
    debugPrint('[Chart${screen.isEmpty ? '' : '][$screen'}] '
        'AAPL history count: ${closesForSymbol(history, 'AAPL').length}');
    debugPrint('[Chart${screen.isEmpty ? '' : '][$screen'}] '
        'TSLA history count: ${closesForSymbol(history, 'TSLA').length}');
    debugPrint('[Chart${screen.isEmpty ? '' : '][$screen'}] '
        'AMZN history count: ${closesForSymbol(history, 'AMZN').length}');
    debugPrint('[Chart${screen.isEmpty ? '' : '][$screen'}] '
        'Portfolio history point count: '
        '${portfolioTotalsByDate(history, shares).length}');

    for (final sym in ['AAPL', 'TSLA', 'AMZN']) {
      stockChartSeries(history, sym, quotes[sym], context: screen);
    }
    portfolioChartSeries(history, shares, quotes, context: screen);
  }

  /// Clears in-memory caches — used by Retry to force a fresh network fetch.
  static void invalidateSessionCache() {
    _cache = null;
    _cacheAt = null;
    _historyCache = null;
    _historyCacheAt = null;
    debugPrint('[Marketstack] Session cache invalidated.');
  }

  /// Loads persisted quotes without a network call — warms UI on cold start.
  static Future<List<StockQuote>?> warmQuotesFromPrefs() async {
    final cached = await _loadQuotesFromPrefs();
    if (cached == null || cached.isEmpty) return null;
    _cache = cached;
    _cacheAt = DateTime.now();
    _quoteCacheVersionAt = _quoteCacheVersion;
    lastFetchFromCache = true;
    lastCacheDate = await _loadCacheDateFromPrefs();
    debugPrint('[Marketstack] warmQuotesFromPrefs: ${cached.length} quotes.');
    return cached;
  }

  /// Loads the richest saved history across common day-range keys.
  static Future<Map<String, List<EodBar>>?> _loadBestHistoryFromPrefs({
    List<String> symbols = const ['AAPL', 'TSLA', 'AMZN'],
    int? preferredDays,
  }) async {
    final dayKeys = <int>{
      ?preferredDays,
      45,
      30,
      14,
      7,
    }.toList()
      ..sort((a, b) => b.compareTo(a));

    Map<String, List<EodBar>>? best;
    var bestMin = -1;

    for (final days in dayKeys) {
      final cached = await _loadHistoryFromPrefs(days);
      if (cached == null || cached.isEmpty) continue;
      final minBars = _minBarCount(cached, symbols);
      debugPrint(
          '[Marketstack] Persisted history ($days days): minBars=$minBars');
      if (minBars > bestMin) {
        bestMin = minBars;
        best = cached;
      }
    }

    if (best != null && bestMin >= 2) {
      debugPrint(
          '[Marketstack] Using best persisted history (minBars=$bestMin).');
      return best;
    }
    return null;
  }

  /// Loads persisted history without a network call.
  static Future<Map<String, List<EodBar>>?> warmHistoryFromPrefs({
    int daysBack = 45,
  }) async {
    final cached =
        await _loadBestHistoryFromPrefs(preferredDays: daysBack);
    if (cached == null || cached.isEmpty) return null;
    _historyCache = cached;
    _historyCacheAt = DateTime.now();
    _historyCacheVersionAt = _historyCacheVersion;
    _historyCacheDays = daysBack;
    lastHistoryFromCache = true;
    debugPrint(
        '[Marketstack] warmHistoryFromPrefs: ${cached.length} symbols.');
    return cached;
  }

  static bool _endpointProbeDone = false;

  /// One-time probe of v1/v2 endpoints — logs which return valid data.
  static Future<void> probeEndpointsOnce() async {
    if (_endpointProbeDone) return;
    _endpointProbeDone = true;
    const symbols = 'AAPL';
    final to = DateTime.now();
    final from = to.subtract(const Duration(days: 30));
    final dateFrom =
        '${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}';
    final dateTo =
        '${to.year}-${to.month.toString().padLeft(2, '0')}-${to.day.toString().padLeft(2, '0')}';

    final probes = <String, String>{
      'v1 latest': 'http://api.marketstack.com/v1/eod/latest'
          '?access_key=$_marketstackKey&symbols=$symbols',
      'v2 latest': 'http://api.marketstack.com/v2/eod/latest'
          '?access_key=$_marketstackKey&symbols=$symbols',
      'v1 history': 'http://api.marketstack.com/v1/eod'
          '?access_key=$_marketstackKey&symbols=$symbols'
          '&date_from=$dateFrom&date_to=$dateTo&limit=10&sort=ASC',
      'v2 history': 'http://api.marketstack.com/v2/eod'
          '?access_key=$_marketstackKey&symbols=$symbols'
          '&date_from=$dateFrom&date_to=$dateTo&limit=10&sort=ASC',
    };

    debugPrint('[Marketstack] === endpoint probe (one-time) ===');
    for (final entry in probes.entries) {
      try {
        final response = await http
            .get(Uri.parse(entry.value),
                headers: {'User-Agent': 'ClarivApp/1.0'})
            .timeout(const Duration(seconds: 12));
        debugPrint('[Marketstack] ${entry.key} status: ${response.statusCode}');
        debugPrint(
            '[Marketstack] ${entry.key} body: ${_bodyPreview(response.body, 400)}');
      } catch (e) {
        debugPrint('[Marketstack] ${entry.key} probe failed: $e');
      }
    }
    debugPrint('[Marketstack] === using v1 consistently in app code ===');
  }

  static void _logLatestApiAudit(http.Response response, Uri uri, int parsed) {
    debugPrint('latestApiUrl: ${sanitizeUrl(uri)}');
    debugPrint('latestStatusCode: ${response.statusCode}');
    debugPrint('latestBodyFirst1000Chars: ${_bodyPreview(response.body)}');
    debugPrint('latestParsedCount: $parsed');
  }

  static void _logHistoryApiAudit(
    http.Response response,
    Uri uri,
    int parsed,
    Map<String, List<EodBar>> result,
    List<String> symbols,
  ) {
    debugPrint('historyApiUrl: ${sanitizeUrl(uri)}');
    debugPrint('historyStatusCode: ${response.statusCode}');
    debugPrint('historyBodyFirst1000Chars: ${_bodyPreview(response.body)}');
    debugPrint('historyParsedCount: $parsed');
    for (final sym in symbols) {
      final closes = closesForSymbol(result, sym);
      final bars = result[sym.toUpperCase()] ?? [];
      debugPrint('$sym history count: ${closes.length}');
      if (bars.isNotEmpty) {
        debugPrint('$sym firstDate: ${bars.first.date}');
        debugPrint('$sym lastDate: ${bars.last.date}');
        debugPrint('$sym firstClose: ${bars.first.close.toStringAsFixed(2)}');
        debugPrint('$sym lastClose: ${bars.last.close.toStringAsFixed(2)}');
        if (closes.length >= 2) {
          debugPrint(
              '$sym chartTrendPercent: ${ChartTrend.trendPercent(closes).toStringAsFixed(2)}%');
          debugPrint(
              '$sym selectedChartColor: ${ChartTrend.dataTrendIsUp(closes) ? 'green/teal' : 'red'}');
        }
      }
    }
  }

  static List<StockQuote> _dedupeQuotes(List<StockQuote> quotes) {
    final bySym = <String, StockQuote>{};
    for (final q in quotes) {
      if (q.symbol.isEmpty || q.close <= 0) continue;
      bySym[q.symbol.toUpperCase()] = q;
    }
    return bySym.values.toList();
  }

  static void _storeQuotes(List<StockQuote> quotes, QuoteDataSource source) {
    _cache = quotes.map(normalizeDailyChange).toList();
    _cacheAt = DateTime.now();
    _quoteCacheVersionAt = _quoteCacheVersion;
    lastFetchFromCache = false;
    lastQuoteSource = source;
  }

  /// Marketstack `/v1/eod/latest` — one request for all symbols.
  static Future<List<StockQuote>> _fetchMarketstackLatest(
    List<String> symbols,
  ) async {
    final uri = Uri.parse(
      '$_marketstackBase/eod/latest'
      '?access_key=$_marketstackKey'
      '&symbols=${symbols.join(',')}',
    );
    debugPrint('[Marketstack] GET latest (v1) $uri');

    final response = await http
        .get(uri, headers: {'User-Agent': 'ClarivApp/1.0'})
        .timeout(const Duration(seconds: 15));

    _logJsonSummary('Marketstack latest', response);

    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Could not decode Marketstack latest response.');
    }

    if (json.containsKey('error') && json['error'] != null) {
      final err = json['error'] as Map<String, dynamic>;
      final code = err['code'] as String? ?? 'unknown_error';
      final msg = err['message'] as String? ?? 'Latest API error.';
      debugPrint('[Marketstack] Latest API error [$code]: $msg');
      throw MarketstackApiException(code, msg);
    }

    if (response.statusCode != 200) {
      throw Exception('Marketstack latest HTTP ${response.statusCode}');
    }

    final list = json['data'] as List<dynamic>? ?? [];
    final quotes = <StockQuote>[];
    for (final item in list) {
      try {
        final q = StockQuote.fromMarketstackEod(item as Map<String, dynamic>);
        if (q.symbol.isNotEmpty && q.close > 0) quotes.add(q);
      } catch (e) {
        debugPrint('[Marketstack] Skip bad latest row: $e');
      }
    }

    debugPrint('[Marketstack] Latest parsed quote count: ${quotes.length}');
    _logLatestApiAudit(response, uri, quotes.length);
    if (quotes.isEmpty) {
      throw Exception('Marketstack latest returned no usable quotes.');
    }
    return quotes;
  }

  static String _yahooRangeForDays(int daysBack) {
    if (daysBack <= 7) return '5d';
    if (daysBack <= 14) return '1mo';
    if (daysBack <= 45) return '2mo';
    if (daysBack <= 90) return '3mo';
    return '6mo';
  }

  static List<EodBar> _parseYahooChartResult(
    String symbol,
    Map<String, dynamic> result,
  ) {
    final sym = symbol.toUpperCase();
    final timestamps = result['timestamp'] as List<dynamic>? ?? [];
    final indicators = result['indicators'] as Map<String, dynamic>?;
    final quoteList = indicators?['quote'] as List<dynamic>?;
    if (quoteList == null || quoteList.isEmpty) return [];

    final quote = quoteList.first as Map<String, dynamic>;
    final closes = quote['close'] as List<dynamic>? ?? [];
    final bars = <EodBar>[];

    for (var i = 0; i < timestamps.length && i < closes.length; i++) {
      final closeRaw = closes[i];
      if (closeRaw == null) continue;
      final close = closeRaw is num
          ? closeRaw.toDouble()
          : double.tryParse(closeRaw.toString()) ?? 0.0;
      if (close <= 0) continue;

      final ts = timestamps[i];
      final sec = ts is num ? ts.toInt() : int.tryParse(ts.toString());
      if (sec == null || sec <= 0) continue;

      final dt = DateTime.fromMillisecondsSinceEpoch(sec * 1000, isUtc: true);
      bars.add(EodBar(symbol: sym, date: _dateStr(dt), close: close));
    }

    return _sortedBars(bars);
  }

  /// Yahoo Finance chart API — daily closes (HTTPS, no API key).
  static Future<List<EodBar>> _fetchYahooHistoryForSymbol(
    String symbol,
    int daysBack,
  ) async {
    final sym = symbol.toUpperCase();
    final range = _yahooRangeForDays(daysBack);
    final uri = Uri.parse('$_yahooChartBase/$sym?interval=1d&range=$range');
    debugPrint('[Marketstack] GET Yahoo history $sym range=$range');

    final response = await http
        .get(uri, headers: _yahooHeaders)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Yahoo history HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final chart = json['chart'] as Map<String, dynamic>?;
    if (chart == null) throw Exception('Yahoo: missing chart object');

    final results = chart['result'] as List<dynamic>?;
    if (results == null || results.isEmpty) {
      throw Exception('Yahoo: empty chart result');
    }

    final bars = _parseYahooChartResult(
      sym,
      results.first as Map<String, dynamic>,
    );
    debugPrint('[Marketstack] Yahoo $sym history count: ${bars.length}');
    if (bars.length < 2) {
      throw Exception('Yahoo: insufficient close prices for $sym');
    }
    return bars;
  }

  static Future<Map<String, List<EodBar>>> _fetchYahooHistoryBatch(
    List<String> symbols,
    int daysBack,
  ) async {
    final result = <String, List<EodBar>>{};
    for (final sym in symbols) {
      try {
        final bars = await _fetchYahooHistoryForSymbol(sym, daysBack);
        result[sym.toUpperCase()] = bars;
      } catch (e) {
        debugPrint('[Marketstack] Yahoo history failed for $sym: $e');
      }
    }
    if (result.isEmpty) {
      throw Exception('Yahoo history returned no usable data.');
    }
    debugPrint('[Marketstack] Yahoo batch loaded ${result.length} symbols.');
    return result;
  }

  /// Yahoo Finance chart meta — latest regular-session quote (HTTPS).
  static Future<StockQuote?> _fetchYahooQuote(String symbol) async {
    final sym = symbol.toUpperCase();
    final uri = Uri.parse('$_yahooChartBase/$sym?interval=1d&range=1d');
    debugPrint('[Marketstack] GET Yahoo quote $sym');

    final response = await http
        .get(uri, headers: _yahooHeaders)
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) return null;

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final chart = json['chart'] as Map<String, dynamic>?;
      final results = chart?['result'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;

      final result = results.first as Map<String, dynamic>;
      final meta = result['meta'] as Map<String, dynamic>?;
      if (meta == null) return null;

      final close = StockQuote._num(meta['regularMarketPrice']);
      if (close <= 0) return null;

      final open = StockQuote._num(meta['regularMarketOpen'], close);
      final high = StockQuote._num(meta['regularMarketDayHigh'], close);
      final low = StockQuote._num(meta['regularMarketDayLow'], close);
      final pcRaw = meta['previousClose'] ?? meta['chartPreviousClose'];
      final pc = pcRaw == null ? null : StockQuote._num(pcRaw);
      final pct = pc != null && pc > 0
          ? ((close - pc) / pc) * 100
          : StockQuote._num(meta['regularMarketChangePercent']);

      final ts = meta['regularMarketTime'];
      final sec = ts is num ? ts.toInt() : int.tryParse(ts?.toString() ?? '');
      final dateStr = sec != null && sec > 0
          ? _dateStr(DateTime.fromMillisecondsSinceEpoch(sec * 1000, isUtc: true))
          : '';

      return StockQuote(
        symbol: sym,
        close: close,
        open: open,
        high: high,
        low: low,
        changePercent: pct,
        isPositive: pct >= 0,
        date: dateStr,
        previousClose: pc,
      );
    } catch (e) {
      debugPrint('[Marketstack] Yahoo quote parse error for $sym: $e');
      return null;
    }
  }

  static Future<List<StockQuote>> _fetchYahooQuotes(List<String> symbols) async {
    final quotes = <StockQuote>[];
    for (final sym in symbols) {
      final q = await _fetchYahooQuote(sym);
      if (q != null) quotes.add(q);
    }
    return _dedupeQuotes(quotes);
  }

  /// Finnhub `/quote` — one symbol per call, used when Marketstack fails.
  static Future<StockQuote?> _fetchFinnhubQuote(String symbol) async {
    final sym = symbol.toUpperCase();
    final uri = Uri.parse('$_quoteBase/quote?symbol=$sym&token=$_finnhubKey');
    debugPrint('[Marketstack] GET Finnhub fallback $uri');

    final response = await http
        .get(uri, headers: {'User-Agent': 'ClarivApp/1.0'})
        .timeout(const Duration(seconds: 12));

    debugPrint('[Marketstack] Finnhub $sym HTTP ${response.statusCode}');
    debugPrint('[Marketstack] Finnhub body: ${_bodyPreview(response.body, 500)}');

    if (response.statusCode != 200) return null;

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final q = StockQuote.fromFinnhub(sym, json);
      if (q.close <= 0) return null;
      return q;
    } catch (e) {
      debugPrint('[Marketstack] Finnhub parse error for $sym: $e');
      return null;
    }
  }

  /// Fills missing symbols via Finnhub without failing the whole batch.
  static Future<List<StockQuote>> _fillMissingViaFinnhub(
    List<String> symbols,
    List<StockQuote> existing,
  ) async {
    final have = {for (final q in existing) q.symbol.toUpperCase()};
    final result = List<StockQuote>.from(existing);
    for (final sym in symbols) {
      final upper = sym.toUpperCase();
      if (have.contains(upper)) continue;
      final q = await _fetchFinnhubQuote(upper);
      if (q != null) {
        result.add(q);
        debugPrint('[Marketstack] Finnhub filled missing symbol $upper');
      }
    }
    return _dedupeQuotes(result);
  }

  // ── API calls ─────────────────────────────────────────────────────────────

  /// Fetches latest quotes for [symbols].
  ///
  /// Priority: in-memory cache → Marketstack v1 latest → Finnhub per symbol
  /// → SharedPreferences cache.
  static Future<List<StockQuote>> fetchLatest(
    List<String> symbols, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _quotesCacheValid() &&
        _cacheAt != null &&
        DateTime.now().difference(_cacheAt!) < _cacheTtl) {
      debugPrint('[Marketstack] fetchLatest: in-memory cache hit '
          '(${_cache!.length} quotes).');
      lastFetchFromCache = false;
      return _cache!;
    }

    if (forceRefresh) {
      _cache = null;
      _cacheAt = null;
    }

    Object? lastError;

    // Endpoint probe is debug-only and must not block startup (4 extra HTTP calls).
    if (kDebugMode) {
      unawaited(probeEndpointsOnce());
    }

    // 1) Marketstack v1 /eod/latest (single efficient request)
    try {
      var quotes = await _fetchMarketstackLatest(symbols);
      quotes = await _fillMissingViaFinnhub(symbols, quotes);
      quotes = _dedupeQuotes(quotes);
      if (quotes.isNotEmpty) {
        _storeQuotes(quotes, QuoteDataSource.marketstack);
        await _saveQuotesToPrefs(quotes);
        debugPrint('[Marketstack] fetchLatest: ${quotes.length} quotes from '
            'Marketstack (+ Finnhub fill if needed).');
        return quotes;
      }
    } catch (e) {
      lastError = e;
      debugPrint('[Marketstack] Marketstack latest failed: $e');
    }

    // 2) Finnhub for all symbols
    try {
      debugPrint('[Marketstack] Trying Finnhub for all symbols...');
      final finnhubQuotes = <StockQuote>[];
      for (final sym in symbols) {
        final q = await _fetchFinnhubQuote(sym);
        if (q != null) finnhubQuotes.add(q);
      }
      final quotes = _dedupeQuotes(finnhubQuotes);
      if (quotes.isNotEmpty) {
        _storeQuotes(quotes, QuoteDataSource.finnhub);
        await _saveQuotesToPrefs(quotes);
        debugPrint('[Marketstack] fetchLatest: ${quotes.length} quotes from '
            'Finnhub fallback.');
        return quotes;
      }
    } catch (e) {
      lastError = e;
      debugPrint('[Marketstack] Finnhub batch failed: $e');
    }

    // 3) Yahoo Finance for all symbols (real HTTPS data, no API key)
    try {
      debugPrint('[Marketstack] Trying Yahoo Finance for all symbols...');
      final yahooQuotes = await _fetchYahooQuotes(symbols);
      if (yahooQuotes.isNotEmpty) {
        _storeQuotes(yahooQuotes, QuoteDataSource.yahoo);
        await _saveQuotesToPrefs(yahooQuotes);
        debugPrint('[Marketstack] fetchLatest: ${yahooQuotes.length} quotes '
            'from Yahoo Finance.');
        return yahooQuotes;
      }
    } catch (e) {
      lastError = e;
      debugPrint('[Marketstack] Yahoo batch failed: $e');
    }

    // 4) SharedPreferences persistent cache
    debugPrint('[Marketstack] Trying SharedPreferences quote cache...');
    final cached = await _loadQuotesFromPrefs();
    if (cached != null && cached.isNotEmpty) {
      _cache = cached;
      _cacheAt = DateTime.now();
      _quoteCacheVersionAt = _quoteCacheVersion;
      lastFetchFromCache = true;
      lastQuoteSource = QuoteDataSource.cache;
      lastCacheDate = await _loadCacheDateFromPrefs();
      debugPrint('[Marketstack] Serving ${cached.length} cached quotes '
          '(originally saved: $lastCacheDate).');
      return cached;
    }

    debugPrint('[Marketstack] fetchLatest failed completely. lastError=$lastError');
    throw lastError ?? Exception('No market data available.');
  }

  static int _minBarCount(
    Map<String, List<EodBar>> history,
    List<String> symbols,
  ) {
    var minCount = 999999;
    for (final sym in symbols) {
      final count = closesForSymbol(history, sym).length;
      if (count < minCount) minCount = count;
    }
    return minCount == 999999 ? 0 : minCount;
  }

  static Map<String, List<EodBar>> _parseHistoryResponse(
    http.Response response,
    List<String> symbols,
  ) {
    _logJsonSummary('Marketstack history', response);

    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Could not decode history response (v1).');
    }

    if (json.containsKey('error') && json['error'] != null) {
      final err = json['error'] as Map<String, dynamic>;
      final code = err['code'] as String? ?? 'unknown_error';
      final msg = err['message'] as String? ?? 'History API error.';
      debugPrint('[Marketstack] History (v1) API error [$code]: $msg');
      throw MarketstackApiException(code, msg);
    }

    if (response.statusCode != 200) {
      throw Exception('History (v1) HTTP ${response.statusCode}');
    }

    final list = json['data'] as List<dynamic>? ?? [];
    debugPrint('[Marketstack] History (v1): ${list.length} EOD records parsed.');

    final Map<String, List<EodBar>> grouped = {};
    for (final item in list) {
      final bar = EodBar.fromJson(item as Map<String, dynamic>);
      if (bar.symbol.isEmpty || bar.close <= 0 || bar.date.isEmpty) continue;
      grouped.putIfAbsent(bar.symbol.toUpperCase(), () => []).add(bar);
    }

    final Map<String, List<EodBar>> result = {};
    for (final entry in grouped.entries) {
      final sorted = _sortedBars(entry.value);
      result[entry.key] = sorted;
      debugPrint('[Marketstack] History (v1) ${entry.key}: ${sorted.length} bars');
    }

    if (result.isEmpty) {
      throw Exception(
          'History (v1) response contained no usable close prices.');
    }

    for (final sym in symbols) {
      final count = closesForSymbol(result, sym).length;
      debugPrint('[Marketstack] History (v1) $sym count: $count');
    }

    return result;
  }

  /// Live fetch from Marketstack `/v1/eod`.
  static Future<Map<String, List<EodBar>>> _fetchHistoryLive(
    List<String> symbols,
    int daysBack,
  ) async {
    final to = DateTime.now();
    final from = to.subtract(Duration(days: daysBack));
    final uri = Uri.parse(
      '$_marketstackBase/eod'
      '?access_key=$_marketstackKey'
      '&symbols=${symbols.join(',')}'
      '&date_from=${_dateStr(from)}'
      '&date_to=${_dateStr(to)}'
      '&limit=500'
      '&sort=ASC',
    );
    debugPrint('[Marketstack] GET history (v1) $uri');

    final response = await http
        .get(uri, headers: {'User-Agent': 'ClarivApp/1.0'})
        .timeout(const Duration(seconds: 15));

    final result = _parseHistoryResponse(response, symbols);
    final totalBars =
        result.values.fold<int>(0, (sum, bars) => sum + bars.length);
    _logHistoryApiAudit(response, uri, totalBars, result, symbols);
    return result;
  }

  static Future<Map<String, List<EodBar>>> _fetchAndCacheHistory(
    List<String> symbols,
    int daysBack,
  ) async {
    var result = await _fetchHistoryLive(symbols, daysBack);

    final minBars = _minBarCount(result, symbols);
    if (minBars < 2 && daysBack < 45) {
      debugPrint('[Marketstack] Only $minBars bar(s) with $daysBack days — '
          'retrying with 45 calendar days.');
      result = await _fetchHistoryLive(symbols, 45);
      daysBack = 45;
    }

    _historyCache = result;
    _historyCacheAt = DateTime.now();
    _historyCacheVersionAt = _historyCacheVersion;
    _historyCacheDays = daysBack;
    lastHistoryFromCache = false;
    await _saveHistoryToPrefs(result, daysBack);
    return result;
  }

  /// Fetches daily EOD close prices from Marketstack `/v1/eod`.
  /// On quota/error, falls back to the best persisted history (real saved data).
  static Future<Map<String, List<EodBar>>> fetchWeeklyHistory(
    List<String> symbols, {
    int daysBack = 45,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _historyCacheValid(daysBack) &&
        _historyCacheAt != null &&
        DateTime.now().difference(_historyCacheAt!) < _historyTtl) {
      debugPrint('[Marketstack] fetchWeeklyHistory: in-memory cache hit '
          '($daysBack days, ${_historyCache!.length} symbols).');
      lastHistoryFromCache = false;
      return _historyCache!;
    }

    if (forceRefresh) {
      _historyCache = null;
      _historyCacheAt = null;
    }

    try {
      return await _fetchAndCacheHistory(symbols, daysBack);
    } catch (e) {
      final rateLimited =
          e is MarketstackApiException && e.isRateLimit;
      if (rateLimited) {
        debugPrint(
            '[Marketstack] Fallback because API returned usage_limit_reached');
      } else {
        debugPrint('[Marketstack] Live history failed: $e');
      }

      // Yahoo Finance — real daily closes when Marketstack quota/network fails.
      try {
        debugPrint('[Marketstack] Trying Yahoo Finance historical batch...');
        final yahoo = await _fetchYahooHistoryBatch(symbols, daysBack);
        _historyCache = yahoo;
        _historyCacheAt = DateTime.now();
        _historyCacheVersionAt = _historyCacheVersion;
        _historyCacheDays = daysBack;
        lastHistoryFromCache = false;
        await _saveHistoryToPrefs(yahoo, daysBack);
        for (final sym in symbols) {
          debugPrint('[Marketstack] Yahoo cached $sym count: '
              '${closesForSymbol(yahoo, sym).length}');
        }
        return yahoo;
      } catch (yahooErr) {
        debugPrint('[Marketstack] Yahoo history batch failed: $yahooErr');
      }

      debugPrint('[Marketstack] Trying best persisted history cache...');

      final cached = await _loadBestHistoryFromPrefs(
        symbols: symbols,
        preferredDays: daysBack,
      );
      if (cached != null && cached.isNotEmpty) {
        _historyCache = cached;
        _historyCacheAt = DateTime.now();
        _historyCacheVersionAt = _historyCacheVersion;
        _historyCacheDays = daysBack;
        lastHistoryFromCache = true;
        debugPrint('[Marketstack] Serving persisted history '
            '(${cached.length} symbols).');
        for (final sym in symbols) {
          debugPrint('[Marketstack] Cached $sym count: '
              '${closesForSymbol(cached, sym).length}');
        }
        return cached;
      }

      debugPrint(
          '[Marketstack] No persisted history — charts will show unavailable.');
      rethrow;
    }
  }

  /// Alias kept for backward compatibility.
  static Future<Map<String, List<EodBar>>> fetchHistoricalPrices(
    List<String> symbols, {
    int daysBack = 30,
  }) =>
      fetchWeeklyHistory(symbols, daysBack: daysBack);
}
