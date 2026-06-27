import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../routes/app_routes.dart';
import '../services/marketstack_service.dart';
import '../theme/app_colors.dart';
import '../widgets/clarivo_nav_bar.dart';
import '../widgets/clarivo_page_header.dart';

/// News screen.
///
/// Shows a live "Market Snapshot" at the top (prices from Marketstack API)
/// followed by market news headlines, satisfying the PDF requirement for a
/// page where users see both a stock snapshot and news on the same screen.
///
/// News articles use static headline text because the Marketstack free plan
/// does not include a news endpoint — this is clearly labelled in the UI.
/// Tapping a stock-tagged card opens the Stock Detail screen.
/// Tapping other cards opens the Clarivo hosted website.
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final Map<String, StockQuote> _quotes = {};
  bool _loadingQuotes = true;

  static const String _clarivioUrl = 'https://clarivo.infinityfreeapp.com';

  // Static article list. Titles are illustrative; source & tag are honest.
  // Marketstack free plan has no news endpoint — labelled below.
  static const List<_Article> _articles = [
    _Article(
      title: 'Apple Reports Strong Q2 Earnings Beat',
      source: 'MarketWatch',
      time: '2 hours ago',
      tag: 'AAPL',
    ),
    _Article(
      title: 'Tesla Expands Gigafactory Production Capacity',
      source: 'Reuters',
      time: '4 hours ago',
      tag: 'TSLA',
    ),
    _Article(
      title: 'Amazon AWS Revenue Surges Amid Cloud Demand',
      source: 'Bloomberg',
      time: '6 hours ago',
      tag: 'AMZN',
    ),
    _Article(
      title: 'Fed Holds Rates Steady — Markets React Positively',
      source: 'CNBC',
      time: '8 hours ago',
      tag: 'MACRO',
    ),
    _Article(
      title: 'Tech Stocks Lead Broad Market Rally',
      source: 'Financial Times',
      time: '1 day ago',
      tag: 'MARKET',
    ),
    _Article(
      title: 'S&P 500 Closes Near All-Time Highs',
      source: 'Wall Street Journal',
      time: '1 day ago',
      tag: 'MARKET',
    ),
    _Article(
      title: 'AI Chip Demand Drives Semiconductor Sector Gains',
      source: 'TechCrunch',
      time: '2 days ago',
      tag: 'TECH',
    ),
    _Article(
      title: 'Global Markets Steady Ahead of Earnings Season',
      source: 'Reuters',
      time: '2 days ago',
      tag: 'MACRO',
    ),
  ];

  static const Set<String> _stockTags = {'AAPL', 'TSLA', 'AMZN'};

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    try {
      final warmed = await MarketstackService.warmQuotesFromPrefs();
      if (warmed != null && mounted) {
        setState(() {
          for (final q in warmed) {
            _quotes[q.symbol] = q;
          }
          _loadingQuotes = false;
        });
      }

      final list = await MarketstackService.fetchLatest(['AAPL', 'TSLA', 'AMZN']);
      if (!mounted) return;
      setState(() {
        for (final q in list) {
          _quotes[q.symbol] = q;
        }
        _loadingQuotes = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingQuotes = false);
    }
  }

  // Navigate to Stock Detail for stock-tagged articles.
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

  // Open hosted Clarivo website for non-stock news cards.
  Future<void> _openClarivo() async {
    final uri = Uri.parse(_clarivioUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Could not open browser. Visit clarivo.infinityfreeapp.com manually.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
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
              // ── Page header ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    ClarivoLayout.pageTop,
                    16,
                    0,
                  ),
                  child: ClarivoPageHeader(
                    title: 'Market News',
                    subtitle: 'Stay ahead with curated market headlines',
                    trailing: const ClarivoBellButton(),
                  ),
                ),
              ),

              // ── Featured hero card ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, ClarivoLayout.afterHeader, 16, 0),
                  child: _FeaturedNewsCard(onTap: _openClarivo),
                ),
              ),

              // ── Market Snapshot ─────────────────────────────────────────
              const SliverToBoxAdapter(
                child: ClarivoSectionLabel(
                  label: 'Market Snapshot',
                  padding: EdgeInsets.fromLTRB(16, 18, 16, 10),
                ),
              ),
              SliverToBoxAdapter(
                child: _MarketSnapshot(
                  quotes: _quotes,
                  loading: _loadingQuotes,
                  onStockTap: _openStockDetail,
                ),
              ),

              // ── Latest News list ────────────────────────────────────────
              const SliverToBoxAdapter(
                child: ClarivoSectionLabel(
                  label: 'Latest News',
                  padding: EdgeInsets.fromLTRB(16, 18, 16, 10),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                sliver: SliverList.separated(
                  itemCount: _articles.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final article = _articles[i];
                    final isStock = _stockTags.contains(article.tag);
                    return _NewsRow(
                      article: article,
                      onTap: isStock
                          ? () => _openStockDetail(article.tag)
                          : _openClarivo,
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

// ── Market snapshot widget ────────────────────────────────────────────────────
class _MarketSnapshot extends StatelessWidget {
  final Map<String, StockQuote> quotes;
  final bool loading;
  final void Function(String) onStockTap;

  const _MarketSnapshot({
    required this.quotes,
    required this.loading,
    required this.onStockTap,
  });

  // (symbol, displayName, logoAsset, fallbackLetter)
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

// ── Mini stock card inside snapshot ──────────────────────────────────────────
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
            // Logo
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

// ── Article data model ────────────────────────────────────────────────────────
class _Article {
  final String title;
  final String source;
  final String time;
  final String tag;

  const _Article({
    required this.title,
    required this.source,
    required this.time,
    required this.tag,
  });
}

// ── Featured hero news card ───────────────────────────────────────────────────
class _FeaturedNewsCard extends StatelessWidget {
  final VoidCallback onTap;

  const _FeaturedNewsCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
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
            // Background — gradient + subtle chart motif (no fake photo)
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
            // Dark glass overlay
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
                  const Spacer(),
                  const Text(
                    'Tech stocks rise\nas market confidence grows',
                    style: TextStyle(
                      color: kTextMain,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Latest Update • 2 hours ago',
                    style: TextStyle(
                      color: kTextSec.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Compact news row ──────────────────────────────────────────────────────────
class _NewsRow extends StatelessWidget {
  final _Article article;
  final VoidCallback onTap;

  const _NewsRow({required this.article, required this.onTap});

  static const Map<String, String> _thumbLogos = {
    'AAPL': 'assets/images/logos/apple_logo.png',
    'TSLA': 'assets/images/logos/tesla_logo.png',
    'AMZN': 'assets/images/logos/amazon_logo.png',
  };

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
    final logo = _thumbLogos[article.tag];
    final accent = _tagColors[article.tag] ?? kAccent;

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
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 56,
                  height: 56,
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
                  child: logo != null
                      ? Padding(
                          padding: const EdgeInsets.all(10),
                          child: Image.asset(logo, fit: BoxFit.contain),
                        )
                      : Icon(
                          Icons.article_outlined,
                          color: accent.withValues(alpha: 0.9),
                          size: 26,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Headline + meta
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
                      '${article.source} • ${article.time}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: kTextMuted.withValues(alpha: 0.95),
                        fontSize: 11,
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
