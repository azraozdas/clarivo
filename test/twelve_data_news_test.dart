import 'package:clarivo/services/twelve_data_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TwelveDataService article mapping', () {
    test('maps editorial article fields into NewsArticle', () {
      final article = TwelveDataService.mapArticleForTest(
        {
          'headline': 'Apple unveils new product',
          'summary': 'Brief summary here.',
          'url': 'https://example.com/story',
          'image': 'https://example.com/image.jpg',
          'source': 'Reuters',
          'datetime': 1719000000,
          'related': 'AAPL,MSFT',
        },
        fallbackSymbol: 'AAPL',
      );

      expect(article, isNotNull);
      expect(article!.title, 'Apple unveils new product');
      expect(article.summary, 'Brief summary here.');
      expect(article.url, 'https://example.com/story');
      expect(article.source, 'Reuters');
      expect(article.tag, 'AAPL');
      expect(article.imageUrl, 'https://example.com/image.jpg');
      expect(article.time, isNotEmpty);
    });

    test('drops articles without headline or url', () {
      expect(
        TwelveDataService.mapArticleForTest(
          {'headline': '', 'url': 'https://example.com'},
          fallbackSymbol: 'TSLA',
        ),
        isNull,
      );
      expect(
        TwelveDataService.mapArticleForTest(
          {'headline': 'Title only', 'url': ''},
          fallbackSymbol: 'TSLA',
        ),
        isNull,
      );
    });

    test('rejects invalid image urls', () {
      final article = TwelveDataService.mapArticleForTest(
        {
          'headline': 'Headline',
          'url': 'https://example.com/story',
          'image': 'not-a-url',
          'datetime': 1719000000,
        },
        fallbackSymbol: 'AMZN',
      );

      expect(article, isNotNull);
      expect(article!.imageUrl, isNull);
    });
  });
}
