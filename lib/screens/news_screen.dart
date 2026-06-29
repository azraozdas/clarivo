import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../routes/app_routes.dart';
import '../services/news_api_service.dart';
import '../services/twelve_data_service.dart';
import '../theme/app_colors.dart';
import '../widgets/clarivo_nav_bar.dart';
import '../widgets/clarivo_page_header.dart';

/// News screen — live Market Snapshot + NewsAPI headlines.
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final Map<String, StockQuote> _quotes = {};
  bool _loadingQuotes = true;
  List<NewsArticle> _articles = [];
  bool _loadingNews = true;
  bool _initStarted = false;

  /// Spinner only when there is nothing to show yet.
  bool get _showNewsLoading => _loadingNews && _articles.isEmpty;
  bool get _showQuotesLoading => _loadingQuotes && _quotes.isEmpty;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    if (_initStarted) return;
    _initStarted = true;

    final warmQuotes = await TwelveDataService.warmSessionFromPrefs();
    final warmNews = await NewsApiService.warmNewsFromPrefs();
    if (mounted) {
      setState(() {
        if (warmQuotes.quotes != null) {
          for (final q in warmQuotes.quotes!) {
            _quotes[q.symbol] = q;
          }
          _loadingQuotes = false;
        }
        if (warmNews.isNotEmpty) {
          _articles = warmNews;
          _loadingNews = false;
        }
      });
    }

    await Future.wait([
      _loadQuotes(forceRefresh: false),
      _loadNews(forceRefresh: false),
    ]);
  }

  Future<void> _loadQuotes({bool forceRefresh = false}) async {
    if (!forceRefresh && _quotes.isNotEmpty) {
      if (mounted) setState(() => _loadingQuotes = false);
      return;
    }
    try {
      final data = await TwelveDataService.bootstrapMarketData(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        for (final q in data.quotes) {
          _quotes[q.symbol] = q;
        }
        _loadingQuotes = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingQuotes = false);
    }
  }

  Future<void> _loadNews({bool forceRefresh = false}) async {
    if (_loadingNews && _articles.isNotEmpty && !forceRefresh) {
      return;
    }

    try {
      final articles = await NewsApiService.fetchNews(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        if (articles.isNotEmpty) {
          _articles = articles;
        }
        _loadingNews = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingNews = false);
    }
  }

  void _openStockDetail(String symbol) {
    final q = _quotes[symbol];
    if (q == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock data is still loading — please try again.'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    AppRoutes.openStockDetail(context, q);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link.')),
      );
    }
  }

  void _onArticleTap(NewsArticle article) {
    if (article.url.isNotEmpty) {
      _openUrl(article.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final featured = _articles.isNotEmpty ? _articles.first : null;

    return Scaffold(
      backgroundColor: kBackground,
      appBar: const ClarivoAppBar(title: 'Market News'),
      bottomNavigationBar: ClarivoBotNavBar(
        selectedIndex: 2,
        onTap: (i) {
          if (i == 0) AppRoutes.openHome(context);
          if (i == 1) AppRoutes.openPortfolio(context);
          if (i == 3) AppRoutes.openProfile(context);
        },
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: kBgGradientColors,
            stops: kBgGradientStops,
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    ClarivoLayout.pageTop,
                    16,
                    0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Expanded(
                        child: Text(
                          'Live stock market headlines from NewsAPI',
                          style: ClarivoPageTitle.subtitleStyle,
                        ),
                      ),
                      ClarivoBellButton(),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    ClarivoLayout.afterHeader,
                    16,
                    0,
                  ),
                  child: _FeaturedNewsCard(
                    article: featured,
                    loading: _showNewsLoading,
                    onTap: featured != null
                        ? () => _onArticleTap(featured)
                        : () {},
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: ClarivoSectionLabel(
                  label: 'Market Snapshot',
                  padding: EdgeInsets.fromLTRB(16, 18, 16, 10),
                ),
              ),
              SliverToBoxAdapter(
                child: _MarketSnapshot(
                  quotes: _quotes,
                  loading: _showQuotesLoading,
                  onStockTap: _openStockDetail,
                ),
              ),
              const SliverToBoxAdapter(
                child: ClarivoSectionLabel(
                  label: 'Latest News',
                  padding: EdgeInsets.fromLTRB(16, 18, 16, 10),
                ),
              ),
              if (_showNewsLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: kAccent,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                )
              else if (_articles.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: Text(
                      'Live headlines are temporarily unavailable.',
                      style: TextStyle(color: kTextMuted, fontSize: 12),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  sliver: SliverList.separated(
                    itemCount: _articles.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final article = _articles[i];
                      return _NewsRow(
                        article: article,
                        onTap: () => _onArticleTap(article),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketSnapshot extends StatelessWidget {
  final Map<String, StockQuote> quotes;
  final bool loading;
  final void Function(String) onStockTap;

  const _MarketSnapshot({
    required this.quotes,
    required this.loading,
    required this.onStockTap,
  });

  static const List<(String, String, String, String)> _stocks = [
    ('AAPL', 'Apple', 'assets/images/logos/apple_logo.png', 'A'),
    ('TSLA', 'Tesla', 'assets/images/logos/tesla_logo.png', 'T'),
    ('AMZN', 'Amazon', 'assets/images/logos/amazon_logo.png', 'a'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live prices',
                style: TextStyle(
                  color: kTextMuted.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    color: kAccent,
                    strokeWidth: 2,
                  ),
                )
              else
                const Text(
                  'Live',
                  style: TextStyle(
                    color: kPositive,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: _stocks.map(((String, String, String, String) s) {
              final (symbol, name, logo, fallback) = s;
              final q = quotes[symbol];
              return Expanded(
                child: _MiniStockCard(
                  symbol: symbol,
                  name: name,
                  logoAsset: logo,
                  fallback: fallback,
                  priceStr: q?.priceStr ?? '--',
                  changeStr: q?.changeStr ?? '--',
                  isPositive: q?.isDailyPositive ?? true,
                  onTap: () => onStockTap(symbol),
                ),
              );
            }).toList(),
          ),
          if (!loading && quotes.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Could not load prices. Check your connection.',
                style: TextStyle(color: kTextMuted, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniStockCard extends StatelessWidget {
  final String symbol;
  final String name;
  final String logoAsset;
  final String fallback;
  final String priceStr;
  final String changeStr;
  final bool isPositive;
  final VoidCallback onTap;

  const _MiniStockCard({
    required this.symbol,
    required this.name,
    required this.logoAsset,
    required this.fallback,
    required this.priceStr,
    required this.changeStr,
    required this.isPositive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? kPositive : kNegative;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: kBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  logoAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, st) => Center(
                    child: Text(
                      fallback,
                      style: const TextStyle(
                        color: kTextMain,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              symbol,
              style: const TextStyle(
                color: kTextSec,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              priceStr,
              style: const TextStyle(
                color: kTextMain,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPositive
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: color,
                  size: 9,
                ),
                const SizedBox(width: 1),
                Text(
                  changeStr,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedNewsCard extends StatelessWidget {
  final NewsArticle? article;
  final bool loading;
  final VoidCallback onTap;

  const _FeaturedNewsCard({
    required this.article,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final item = article;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 185,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kBorder.withValues(alpha: 0.8)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item?.imageUrl != null)
              Image.network(
                item!.imageUrl!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) => _gradientBackground(),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _gradientBackground();
                },
              )
            else
              _gradientBackground(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ClarivoSectionLabel(
                    label: 'Featured',
                    padding: EdgeInsets.zero,
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loading
                                ? 'Loading headlines...'
                                : (item?.title ??
                                    'Live headlines are temporarily unavailable.'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: kTextMain,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            loading
                                ? 'Latest headlines'
                                : (item != null
                                    ? '${item.source} • ${item.time}'
                                    : 'No news available right now.'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: kTextSec.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
                          if (item != null || loading) ...[
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: kAccent.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: kAccent.withValues(alpha: 0.45),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Read More',
                                        style: TextStyle(
                                          color: kAccent,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: kAccent,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0C2148),
                Color(0xFF123A6B),
                Color(0xFF071C33),
              ],
            ),
          ),
        ),
        Positioned(
          right: -20,
          top: -10,
          child: Icon(
            Icons.show_chart_rounded,
            size: 140,
            color: kAccent.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }
}

class _NewsRow extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback onTap;

  const _NewsRow({required this.article, required this.onTap});

  static const Map<String, Color> _tagColors = {
    'AAPL': Color(0xFF4A90D9),
    'TSLA': Color(0xFF9B59B6),
    'AMZN': Color(0xFFE67E22),
    'MACRO': Color(0xFF42D6B5),
    'MARKET': Color(0xFF5B8DEF),
    'TECH': Color(0xFF7B68EE),
  };

  @override
  Widget build(BuildContext context) {
    final accent = _tagColors[article.tag] ?? kAccent;
    final summary = article.summary.trim();
    final subtitle = summary.isNotEmpty
        ? '${article.source} • ${article.time}\n$summary'
        : '${article.source} • ${article.time}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: kCard.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorder.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: [
              _ArticleThumb(
                imageUrl: article.imageUrl,
                accent: accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kTextMain,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: summary.isNotEmpty ? 3 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: kTextMuted.withValues(alpha: 0.95),
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: kTextMuted.withValues(alpha: 0.7),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArticleThumb extends StatefulWidget {
  final String? imageUrl;
  final Color accent;

  const _ArticleThumb({
    required this.imageUrl,
    required this.accent,
  });

  @override
  State<_ArticleThumb> createState() => _ArticleThumbState();
}

class _ArticleThumbState extends State<_ArticleThumb> {
  bool _useFallback = false;

  @override
  Widget build(BuildContext context) {
    final showImage =
        !_useFallback && widget.imageUrl != null && widget.imageUrl!.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 56,
        height: 56,
        child: showImage
            ? Image.network(
                widget.imageUrl!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _newsThumbFallback(widget.accent);
                },
                errorBuilder: (context, error, stackTrace) {
                  if (!_useFallback) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _useFallback = true);
                    });
                  }
                  return _newsThumbFallback(widget.accent);
                },
              )
            : _newsThumbFallback(widget.accent),
      ),
    );
  }
}

Widget _newsThumbFallback(Color accent) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accent.withValues(alpha: 0.35),
          kBackground,
        ],
      ),
      border: Border.all(color: kBorder.withValues(alpha: 0.5)),
    ),
    child: Icon(
      Icons.article_outlined,
      color: accent.withValues(alpha: 0.85),
      size: 26,
    ),
  );
}
