import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class StockQuote {
  final String symbol;
  final double close;
  final double open;
  final double changePercent;
  final bool isPositive;

  const StockQuote({
    required this.symbol,
    required this.close,
    required this.open,
    required this.changePercent,
    required this.isPositive,
  });

  factory StockQuote.fromJson(Map<String, dynamic> json) {
    final close = (json['close'] as num).toDouble();
    final open = (json['open'] as num).toDouble();
    final pct = open != 0 ? ((close - open) / open) * 100 : 0.0;
    return StockQuote(
      symbol: json['symbol'] as String,
      close: close,
      open: open,
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

class MarketstackService {
  static const String _apiKey = '8fbd57ac60ec1d5ad58e3b33e753234e';
  static const String _directBase = 'http://api.marketstack.com/v2';
  static const String _proxyBase = 'http://localhost:8089';

  static String get _base => kIsWeb ? _proxyBase : _directBase;

  // In-memory cache — avoids redundant API calls when navigating between screens
  static List<StockQuote>? _cache;
  static DateTime? _cacheAt;
  static const Duration _cacheTtl = Duration(minutes: 5);

  static Future<List<StockQuote>> fetchLatest(List<String> symbols) async {
    if (_cache != null &&
        _cacheAt != null &&
        DateTime.now().difference(_cacheAt!) < _cacheTtl) {
      return _cache!;
    }

    final String path =
        '/eod/latest?access_key=$_apiKey&symbols=${symbols.join(',')}';
    final uri = Uri.parse('$_base$path');
    final response = await http
        .get(uri, headers: {'User-Agent': 'ClarivApp/1.0'})
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('Marketstack error ${response.statusCode}: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['data'] as List<dynamic>;
    final quotes = list
        .map((e) => StockQuote.fromJson(e as Map<String, dynamic>))
        .toList();

    _cache = quotes;
    _cacheAt = DateTime.now();
    return quotes;
  }
}
