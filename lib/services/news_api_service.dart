import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ignore: constant_identifier_names
const String NEWS_API_KEY = '1f2e4deceab248e88951e6584d5fce5b';

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

class NewsApiService {
  static const String _base = 'https://newsapi.org/v2';
  static const String _prefsNewsKey = 'newsapi_articles_v1';
  static const String _prefsNewsDateKey = 'newsapi_articles_date_v1';
  static const Duration _cacheTtl = Duration(minutes: 60);
  static const Duration _requestTimeout = Duration(seconds: 12);

  static List<NewsArticle>? _cache;
  static DateTime? _cacheAt;
  static Future<List<NewsArticle>>? _fetchFuture;

  static String? _validImageUrl(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return trimmed;
  }

  static String? _validArticleUrl(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    if (uri.host.contains('example.com')) return null;
    return trimmed;
  }

  static String _tagFromText(String title, String description) {
    final text = '${title.toUpperCase()} ${description.toUpperCase()}';
    if (text.contains('APPLE') || text.contains('AAPL')) return 'AAPL';
    if (text.contains('TESLA') || text.contains('TSLA')) return 'TSLA';
    if (text.contains('AMAZON') || text.contains('AMZN')) return 'AMZN';
    return 'MARKET';
  }

  static String _formatPublishedAt(String? raw) {
    if (raw == null || raw.isEmpty) return 'Recently';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return 'Recently';
    }
  }

  static NewsArticle? _mapArticle(Map<String, dynamic> item) {
    final title = (item['title'] as String? ?? '').trim();
    final url = _validArticleUrl(item['url'] as String?);
    if (title.isEmpty || url == null) return null;

    final description = (item['description'] as String? ?? '').trim();
    final sourceMap = item['source'];
    final sourceName = sourceMap is Map<String, dynamic>
        ? (sourceMap['name'] as String? ?? 'News').trim()
        : 'News';

    return NewsArticle(
      title: title,
      source: sourceName.isEmpty ? 'News' : sourceName,
      time: _formatPublishedAt(item['publishedAt'] as String?),
      tag: _tagFromText(title, description),
      summary: description,
      url: url,
      imageUrl: _validImageUrl(item['urlToImage'] as String?),
    );
  }

  static List<NewsArticle> _parseArticles(List<dynamic> list) {
    final out = <NewsArticle>[];
    for (final item in list) {
      if (item is! Map<String, dynamic>) continue;
      final article = _mapArticle(item);
      if (article != null) out.add(article);
    }
    return out;
  }

  static bool _cacheFresh() {
    if (_cache == null || _cache!.isEmpty || _cacheAt == null) return false;
    return DateTime.now().difference(_cacheAt!) < _cacheTtl;
  }

  static void _storeCache(List<NewsArticle> articles) {
    _cache = articles;
    _cacheAt = DateTime.now();
  }

  static Future<List<NewsArticle>?> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_prefsNewsKey);
      if (str == null) return null;
      final list = jsonDecode(str) as List<dynamic>;
      final articles = list
          .map((e) {
            final m = e as Map<String, dynamic>;
            final url = _validArticleUrl(m['url'] as String?);
            if (url == null) return null;
            return NewsArticle(
              title: m['title'] as String? ?? '',
              source: m['source'] as String? ?? '',
              time: m['time'] as String? ?? '',
              tag: m['tag'] as String? ?? 'MARKET',
              summary: m['summary'] as String? ?? '',
              url: url,
              imageUrl: _validImageUrl(m['imageUrl'] as String?),
            );
          })
          .whereType<NewsArticle>()
          .where((a) => a.title.isNotEmpty)
          .toList();
      return articles.isEmpty ? null : articles;
    } catch (e) {
      debugPrint('[NewsAPI] Failed to load prefs cache: $e');
      return null;
    }
  }

  static Future<void> _saveToPrefs(List<NewsArticle> articles) async {
    if (articles.isEmpty) return;
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
      debugPrint('[NewsAPI] Failed to save prefs cache: $e');
    }
  }

  static Future<List<NewsArticle>> warmNewsFromPrefs() async {
    if (_cacheFresh()) return _cache!;

    final cached = await _loadFromPrefs();
    if (cached != null && cached.isNotEmpty) {
      _storeCache(cached);
      debugPrint('[NewsAPI] warmNewsFromPrefs: ${cached.length} articles');
      return cached;
    }
    return const [];
  }

  static Future<List<NewsArticle>> fetchNews({
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cacheFresh()) {
      return _cache!.take(limit).toList();
    }

    if (!forceRefresh && _fetchFuture != null) {
      final articles = await _fetchFuture!;
      return articles.take(limit).toList();
    }

    if (!forceRefresh) {
      final warmed = await warmNewsFromPrefs();
      if (warmed.isNotEmpty) {
        return warmed.take(limit).toList();
      }
    }

    final future = _fetchFromNetwork(limit: limit);
    if (!forceRefresh) _fetchFuture = future;
    try {
      return await future;
    } finally {
      if (identical(_fetchFuture, future)) _fetchFuture = null;
    }
  }

  static Future<List<NewsArticle>> _fetchFromNetwork({required int limit}) async {
    final uri = Uri.parse(
      '$_base/everything?q=stock%20market&language=en&sortBy=publishedAt&pageSize=$limit&apiKey=$NEWS_API_KEY',
    );
    debugPrint('[NewsAPI] GET ${uri.replace(queryParameters: {...uri.queryParameters, 'apiKey': '***'})}');

    try {
      final response = await http
          .get(uri, headers: {'User-Agent': 'ClarivoApp/1.0'})
          .timeout(_requestTimeout);

      if (response.statusCode != 200) {
        debugPrint('[NewsAPI] HTTP ${response.statusCode} ${response.body}');
        return _fallbackCached();
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['status']?.toString() != 'ok') {
        debugPrint('[NewsAPI] API error: ${json['message']}');
        return _fallbackCached();
      }

      final articles = _parseArticles(json['articles'] as List<dynamic>? ?? []);
      if (articles.isEmpty) {
        return _fallbackCached();
      }

      _storeCache(articles);
      await _saveToPrefs(articles);
      debugPrint('[NewsAPI] fetched ${articles.length} articles');
      return articles.take(limit).toList();
    } catch (e) {
      debugPrint('[NewsAPI] fetch failed: $e');
      return _fallbackCached();
    }
  }

  static Future<List<NewsArticle>> _fallbackCached() async {
    if (_cache != null && _cache!.isNotEmpty) return _cache!;
    final prefs = await _loadFromPrefs();
    if (prefs != null && prefs.isNotEmpty) {
      _storeCache(prefs);
      return prefs;
    }
    return const [];
  }

  static Future<List<NewsArticle>> fetchNewsForSymbol(
    String symbol, {
    int limit = 5,
  }) async {
    final sym = symbol.toUpperCase();
    final all = await fetchNews(limit: 30, forceRefresh: false);
    final filtered = all.where((a) {
      if (a.tag == sym) return true;
      final text = '${a.title} ${a.summary}'.toUpperCase();
      return text.contains(sym);
    }).toList();
    if (filtered.isNotEmpty) return filtered.take(limit).toList();
    return all.take(limit).toList();
  }

  @visibleForTesting
  static NewsArticle? mapArticleForTest(Map<String, dynamic> item) =>
      _mapArticle(item);
}
