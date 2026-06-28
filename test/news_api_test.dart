import 'package:clarivo/services/news_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NewsApiService article mapping', () {
    test('maps NewsAPI article fields into NewsArticle', () {
      final article = NewsApiService.mapArticleForTest({
        'title': 'Apple unveils new product',
        'description': 'Brief summary here.',
        'url': 'https://www.reuters.com/markets/story',
        'urlToImage': 'https://www.reuters.com/image.jpg',
        'source': {'name': 'Reuters'},
        'publishedAt': '2026-06-27T10:00:00Z',
      });

      expect(article, isNotNull);
      expect(article!.title, 'Apple unveils new product');
      expect(article.summary, 'Brief summary here.');
      expect(article.url, 'https://www.reuters.com/markets/story');
      expect(article.source, 'Reuters');
      expect(article.tag, 'AAPL');
      expect(article.imageUrl, 'https://www.reuters.com/image.jpg');
      expect(article.time, isNotEmpty);
    });

    test('drops articles without title or url', () {
      expect(
        NewsApiService.mapArticleForTest({
          'title': '',
          'url': 'https://www.reuters.com/story',
        }),
        isNull,
      );
      expect(
        NewsApiService.mapArticleForTest({
          'title': 'Title only',
          'url': '',
        }),
        isNull,
      );
    });

    test('rejects example.com urls and invalid images', () {
      expect(
        NewsApiService.mapArticleForTest({
          'title': 'Fake link',
          'url': 'https://example.com/story',
        }),
        isNull,
      );

      final article = NewsApiService.mapArticleForTest({
        'title': 'Headline',
        'url': 'https://www.bbc.com/news/story',
        'urlToImage': 'not-a-url',
        'publishedAt': '2026-06-27T10:00:00Z',
      });

      expect(article, isNotNull);
      expect(article!.imageUrl, isNull);
    });
  });
}
