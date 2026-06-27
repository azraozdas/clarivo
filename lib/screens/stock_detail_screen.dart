import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/marketstack_service.dart';
import '../theme/app_colors.dart';
import '../widgets/clarivo_page_header.dart';
import '../widgets/clarivo_sparkline_chart.dart';

/// Stock Detail screen.
/// Shows price header, price history chart, key information table,
/// and related news links — satisfying the PDF requirements for the
/// detailed stock page (table, chart, key info, links to news).
class StockDetailScreen extends StatefulWidget {
  final StockQuote? quote;

  const StockDetailScreen({super.key, this.quote});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  List<double> _closes = [];
  bool _loadingHistory = false;
  int _selectedDays = 30;

  static const Map<String, String> _names = {
    'AAPL': 'Apple Inc.',
    'TSLA': 'Tesla',
    'AMZN': 'Amazon',
  };

  static const Map<String, String> _logos = {
    'AAPL': 'assets/images/logos/apple_logo.png',
    'TSLA': 'assets/images/logos/tesla_logo.png',
    'AMZN': 'assets/images/logos/amazon_logo.png',
  };

  static const String _clarivioUrl = 'https://clarivo.infinityfreeapp.com';

  // External finance news links per stock.
  // Uses Yahoo Finance news pages for real, relevant headlines.
  static const Map<String, List<Map<String, String>>> _newsLinks = {
    'AAPL': [
      {
        'title': 'Apple Inc. — Latest Market News & Analysis',
        'source': 'Yahoo Finance',
        'url': 'https://finance.yahoo.com/quote/AAPL/news',
      },
      {
        'title': 'Apple Stock Overview, Charts & Reports',
        'source': 'MarketWatch',
        'url': 'https://www.marketwatch.com/investing/stock/aapl',
      },
    ],
    'TSLA': [
      {
        'title': 'Tesla Inc. — Latest Market News & Analysis',
        'source': 'Yahoo Finance',
        'url': 'https://finance.yahoo.com/quote/TSLA/news',
      },
      {
        'title': 'Tesla Stock Overview, Charts & Reports',
        'source': 'MarketWatch',
        'url': 'https://www.marketwatch.com/investing/stock/tsla',
      },
    ],
    'AMZN': [
      {
        'title': 'Amazon.com — Latest Market News & Analysis',
        'source': 'Yahoo Finance',
        'url': 'https://finance.yahoo.com/quote/AMZN/news',
      },
      {
        'title': 'Amazon Stock Overview, Charts & Reports',
        'source': 'MarketWatch',
        'url': 'https://www.marketwatch.com/investing/stock/amzn',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    if (widget.quote != null) _loadHistory(30);
  }

  Future<void> _loadHistory(int rangeDays) async {
    if (widget.quote == null) return;
    // 1W uses 14 calendar days so weekends/holidays still yield enough bars.
    final daysBack = rangeDays <= 7 ? 14 : 30;
    setState(() => _loadingHistory = true);
    try {
      final hist = await MarketstackService.fetchWeeklyHistory(
        [widget.quote!.symbol],
        daysBack: daysBack,
      );
      if (!mounted) return;
      final closes = MarketstackService.chartClosesWithLatest(
        hist,
        widget.quote!.symbol,
        widget.quote,
      );
      setState(() {
        _closes = closes;
        _loadingHistory = false;
        _selectedDays = rangeDays;
      });
      MarketstackService.stockChartSeries(
        hist,
        widget.quote!.symbol,
        widget.quote,
        context: 'StockDetail',
      );
    } catch (e) {
      debugPrint('[StockDetail] history error: $e');
      if (mounted) {
        setState(() => _loadingHistory = false);
        MarketstackService.stockChartSeries(
          const {},
          widget.quote!.symbol,
          widget.quote,
          context: 'StockDetail',
        );
      }
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.quote;
    final name = q != null ? (_names[q.symbol] ?? q.symbol) : 'Stock Detail';
    final logoAsset = q != null ? _logos[q.symbol] : null;
    final newsItems = q != null ? (_newsLinks[q.symbol] ?? []) : <Map<String, String>>[];

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: const Color(0xFF030D1C),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: kTextMain,
            size: 20,
          ),
        ),
        title: const SizedBox.shrink(),
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
        child: q == null
            ? Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  ClarivoLayout.pageTop,
                  16,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ClarivoPageTitle(title: 'Stock Detail'),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'No stock data available.',
                          style: TextStyle(color: kTextMuted, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  ClarivoLayout.pageTop,
                  16,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClarivoPageTitle(
                      title: name,
                      subtitle: q.symbol,
                    ),
                    const SizedBox(height: ClarivoLayout.afterHeader),
                    // ── A. Price header ───────────────────────────────────
                    _PriceHeader(
                      quote: q,
                      logoAsset: logoAsset,
                    ),
                    const SizedBox(height: ClarivoLayout.sectionGap),

                    // ── B. Price history chart ────────────────────────────
                    const ClarivoSectionHeading(text: 'Price History'),
                    _ChartSection(
                      closes: _closes,
                      loading: _loadingHistory,
                      selectedDays: _selectedDays,
                      quote: q,
                      onRangeChanged: _loadHistory,
                    ),
                    const SizedBox(height: ClarivoLayout.sectionGap),

                    // ── C. Key information ────────────────────────────────
                    const ClarivoSectionHeading(text: 'Key Information'),
                    _KeyInfoCard(quote: q),
                    const SizedBox(height: ClarivoLayout.sectionGap),

                    // ── D. Market data table ──────────────────────────────
                    const ClarivoSectionHeading(text: 'Market Data Table'),
                    _StockDataTable(quote: q),
                    const SizedBox(height: ClarivoLayout.sectionGap),

                    // ── E. Related news links ─────────────────────────────
                    const ClarivoSectionHeading(text: 'Related News'),
                    ...newsItems.map(
                      (n) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _NewsLinkCard(
                          title: n['title'] ?? '',
                          source: n['source'] ?? '',
                          onTap: () =>
                              _openUrl(n['url'] ?? _clarivioUrl),
                        ),
                      ),
                    ),

                    // Clarivo website shortcut
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _NewsLinkCard(
                        title: 'View full charts & data on Clarivo Web',
                        source: 'clarivo.infinityfreeapp.com',
                        onTap: () => _openUrl(_clarivioUrl),
                        isWebLink: true,
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}

// ── A. Price header ───────────────────────────────────────────────────────────
class _PriceHeader extends StatelessWidget {
  final StockQuote quote;
  final String? logoAsset;

  const _PriceHeader({
    required this.quote,
    this.logoAsset,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = quote.isDailyPositive ? kPositive : kNegative;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: kCardGradientColors,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: text info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quote.priceStr,
                  style: const TextStyle(
                    color: kTextMain,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      quote.isDailyPositive
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 14,
                      color: color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      quote.changeStr,
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'today',
                      style: TextStyle(color: kTextMuted, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Right: company logo
          if (logoAsset != null)
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFF111A25),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.asset(
                  logoAsset!,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, st) => Center(
                    child: Text(
                      quote.symbol[0],
                      style: const TextStyle(
                        color: kTextMain,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── B. Price history chart section ────────────────────────────────────────────
class _ChartSection extends StatelessWidget {
  final List<double> closes;
  final bool loading;
  final int selectedDays;
  final StockQuote quote;
  final void Function(int) onRangeChanged;

  const _ChartSection({
    required this.closes,
    required this.loading,
    required this.selectedDays,
    required this.quote,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final periodLabel =
        MarketstackService.chartPeriodLabel(selectedDays <= 7 ? 14 : 30);
    final points = closes.length >= 2 ? closes : <double>[];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Range buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (periodLabel.isNotEmpty && points.length >= 2)
                Text(
                  '$periodLabel trend',
                  style: TextStyle(
                    color: kTextMuted.withValues(alpha: 0.9),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                const SizedBox.shrink(),
              Row(
                children: [
                  _RangeTab(
                    text: '1W',
                    active: selectedDays == 7,
                    onTap: () => onRangeChanged(7),
                  ),
                  const SizedBox(width: 8),
                  _RangeTab(
                    text: '1M',
                    active: selectedDays == 30,
                    onTap: () => onRangeChanged(30),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClarivoSparklineChart.main(
            values: points,
            height: 140,
            loading: loading,
          ),
        ],
      ),
    );
  }
}

class _RangeTab extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback onTap;

  const _RangeTab({
    required this.text,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active ? kAccent.withAlpha(40) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? kAccent : kTextSec,
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── C. Key information card ───────────────────────────────────────────────────
class _KeyInfoCard extends StatelessWidget {
  final StockQuote quote;
  const _KeyInfoCard({required this.quote});

  @override
  Widget build(BuildContext context) {
    final color = quote.isDailyPositive ? kPositive : kNegative;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _InfoBox(
                      label: 'Date', value: quote.dateDisplay)),
              const SizedBox(width: 8),
              Expanded(
                  child: _InfoBox(label: 'Ticker', value: quote.symbol)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _InfoBox(label: 'Open', value: '\$${quote.open.toStringAsFixed(2)}')),
              const SizedBox(width: 8),
              Expanded(child: _InfoBox(label: 'Close', value: quote.priceStr)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _InfoBox(label: 'High', value: '\$${quote.high.toStringAsFixed(2)}', valueColor: kPositive)),
              const SizedBox(width: 8),
              Expanded(child: _InfoBox(label: 'Low', value: '\$${quote.low.toStringAsFixed(2)}', valueColor: kNegative)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _InfoBox(label: 'Change %', value: quote.changeStr, valueColor: color)),
              const SizedBox(width: 8),
              Expanded(
                  child: _InfoBox(
                      label: 'Prev. Close',
                      value: quote.previousCloseDisplay)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoBox({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: kTextMuted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? kTextMain,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── D. Market data table ──────────────────────────────────────────────────────
class _StockDataTable extends StatelessWidget {
  final StockQuote quote;
  const _StockDataTable({required this.quote});

  static const _rows = [
    ('Symbol', null),
    ('Date', null),
    ('Open', null),
    ('High', 'high'),
    ('Low', 'low'),
    ('Close', null),
    ('Change %', 'change'),
    ('Volume', null),
    ('Prev. Close', null),
    ('Exchange', null),
  ];

  @override
  Widget build(BuildContext context) {
    final changeColor = quote.isDailyPositive ? kPositive : kNegative;

    String valueFor(String field) {
      switch (field) {
        case 'Symbol':
          return quote.symbol;
        case 'Date':
          return quote.dateDisplay;
        case 'Open':
          return '\$${quote.open.toStringAsFixed(2)}';
        case 'High':
          return '\$${quote.high.toStringAsFixed(2)}';
        case 'Low':
          return '\$${quote.low.toStringAsFixed(2)}';
        case 'Close':
          return quote.priceStr;
        case 'Change %':
          return quote.changeStr;
        case 'Volume':
          return quote.volumeDisplay;
        case 'Prev. Close':
          return quote.previousCloseDisplay;
        case 'Exchange':
          return '--';
        default:
          return '--';
      }
    }

    Color? colorFor(String? tone) {
      switch (tone) {
        case 'high':
          return kPositive;
        case 'low':
          return kNegative;
        case 'change':
          return changeColor;
        default:
          return null;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < _rows.length; i++) ...[
            _MarketDataRow(
              label: _rows[i].$1,
              value: valueFor(_rows[i].$1),
              valueColor: colorFor(_rows[i].$2),
            ),
            if (i < _rows.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: kBorder.withValues(alpha: 0.65),
              ),
          ],
        ],
      ),
    );
  }
}

class _MarketDataRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MarketDataRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: const TextStyle(
                color: kTextMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? kTextMain,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── E. Related news link card ─────────────────────────────────────────────────
class _NewsLinkCard extends StatelessWidget {
  final String title;
  final String source;
  final VoidCallback onTap;
  final bool isWebLink;

  const _NewsLinkCard({
    required this.title,
    required this.source,
    required this.onTap,
    this.isWebLink = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isWebLink ? kAccent.withAlpha(100) : kBorder,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              isWebLink ? Icons.language_rounded : Icons.article_outlined,
              color: kAccent,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: kTextMain,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    source,
                    style: const TextStyle(
                      color: kAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.open_in_new_rounded,
              color: kTextMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
