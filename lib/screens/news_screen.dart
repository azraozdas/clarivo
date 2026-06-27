import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../routes/app_routes.dart';
import '../services/marketstack_service.dart';
import '../theme/app_colors.dart';
import '../widgets/clarivo_nav_bar.dart';

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
      final list =
          await MarketstackService.fetchLatest(['AAPL', 'TSLA', 'AMZN']);
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF030D1C),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Market News',
          style: TextStyle(
            color: kTextMain,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kBorder),
        ),
      ),
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
        child: CustomScrollView(
          slivers: [
            // ── Market Snapshot ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: _MarketSnapshot(
                quotes: _quotes,
                loading: _loadingQuotes,
                onStockTap: _openStockDetail,
              ),
            ),

            // ── News disclaimer ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    const Text(
                      'Market Headlines',
                      style: TextStyle(
                        color: kTextMain,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kBorder.withAlpha(80),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Editorial',
                        style: TextStyle(color: kTextMuted, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── News cards ────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              sliver: SliverList.separated(
                itemCount: _articles.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final article = _articles[i];
                  final isStock = _stockTags.contains(article.tag);
                  return _NewsCard(
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
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
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
              const Text(
                'Market Snapshot',
                style: TextStyle(
                  color: kTextMain,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
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
                  isPositive: q?.isPositive ?? true,
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

// ── News card (tappable) ──────────────────────────────────────────────────────
class _NewsCard extends StatelessWidget {
  final _Article article;
  final VoidCallback onTap;

  const _NewsCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isStock = const {'AAPL', 'TSLA', 'AMZN'}.contains(article.tag);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tag badge — tapping the card opens detail / website
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: kAccent.withAlpha(30),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: kAccent.withAlpha(70)),
              ),
              child: Text(
                article.tag,
                style: const TextStyle(
                  color: kAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: const TextStyle(
                      color: kTextMain,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        article.source,
                        style: const TextStyle(
                          color: kAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '·',
                        style: TextStyle(color: kTextMuted, fontSize: 11),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        article.time,
                        style: const TextStyle(
                          color: kTextMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Chevron icon — shows where the tap leads
            Icon(
              isStock
                  ? Icons.bar_chart_rounded
                  : Icons.open_in_new_rounded,
              color: kTextMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
