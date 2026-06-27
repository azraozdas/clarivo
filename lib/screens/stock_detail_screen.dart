import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/marketstack_service.dart';
import '../theme/app_colors.dart';

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

  Future<void> _loadHistory(int days) async {
    if (widget.quote == null) return;
    setState(() => _loadingHistory = true);
    try {
      final hist = await MarketstackService.fetchWeeklyHistory(
        [widget.quote!.symbol],
        daysBack: days,
      );
      if (!mounted) return;
      setState(() {
        _closes =
            MarketstackService.closesForSymbol(hist, widget.quote!.symbol);
        _loadingHistory = false;
        _selectedDays = days;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingHistory = false);
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
        title: Text(
          name,
          style: const TextStyle(
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
            ? const Center(
                child: Text(
                  'No stock data available.',
                  style: TextStyle(color: kTextMuted, fontSize: 14),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── A. Price header ───────────────────────────────────
                    _PriceHeader(
                      quote: q,
                      name: name,
                      logoAsset: logoAsset,
                    ),
                    const SizedBox(height: 20),

                    // ── B. Price history chart ────────────────────────────
                    const _SectionTitle('Price History'),
                    const SizedBox(height: 10),
                    _ChartSection(
                      closes: _closes,
                      loading: _loadingHistory,
                      selectedDays: _selectedDays,
                      quote: q,
                      onRangeChanged: _loadHistory,
                    ),
                    const SizedBox(height: 20),

                    // ── C. Key information ────────────────────────────────
                    const _SectionTitle('Key Information'),
                    const SizedBox(height: 10),
                    _KeyInfoCard(quote: q),
                    const SizedBox(height: 20),

                    // ── D. Market data table ──────────────────────────────
                    const _SectionTitle('Market Data Table'),
                    const SizedBox(height: 10),
                    _StockDataTable(quote: q),
                    const SizedBox(height: 20),

                    // ── E. Related news links ─────────────────────────────
                    const _SectionTitle('Related News'),
                    const SizedBox(height: 10),
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

                    // Data source note
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorder),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: kTextMuted,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Market data from Marketstack API (/v2/eod/latest). '
                              'News links open external websites.',
                              style: TextStyle(
                                color: kTextMuted,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
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

// ── Section title helper ──────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: kTextMain,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

// ── A. Price header ───────────────────────────────────────────────────────────
class _PriceHeader extends StatelessWidget {
  final StockQuote quote;
  final String name;
  final String? logoAsset;

  const _PriceHeader({
    required this.quote,
    required this.name,
    this.logoAsset,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = quote.isPositive ? kPositive : kNegative;

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
                  name,
                  style: const TextStyle(
                    color: kTextMain,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  quote.symbol,
                  style: const TextStyle(
                    color: kTextMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
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
                      quote.isPositive
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
    // Use historical closes if available; otherwise fall back to OHLC points.
    final chartData = closes.length >= 2
        ? closes
        : [quote.open, quote.high, quote.low, quote.close];

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
            mainAxisAlignment: MainAxisAlignment.end,
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
          const SizedBox(height: 10),
          // Chart area
          SizedBox(
            height: 140,
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: kAccent,
                      strokeWidth: 2,
                    ),
                  )
                : CustomPaint(
                    painter: _DetailChartPainter(
                      closes: chartData,
                      isPositive: quote.isPositive,
                    ),
                    child: const SizedBox.expand(),
                  ),
          ),
          if (!loading && closes.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Showing open/high/low/close — historical data unavailable on free plan.',
                style: TextStyle(color: kTextMuted, fontSize: 10),
              ),
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

// Line chart painter for stock detail — uses real API close prices.
class _DetailChartPainter extends CustomPainter {
  final List<double> closes;
  final bool isPositive;

  const _DetailChartPainter({required this.closes, required this.isPositive});

  @override
  void paint(Canvas canvas, Size size) {
    if (closes.length < 2) return;

    final color = isPositive ? kPositive : kNegative;
    final minVal = closes.reduce(math.min);
    final maxVal = closes.reduce(math.max);
    final range = maxVal - minVal;
    final n = closes.length;

    // Horizontal grid lines
    final gridPaint = Paint()
      ..color = kBorder.withValues(alpha: 0.30)
      ..strokeWidth = 1;
    for (int i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Data points
    final pts = List.generate(n, (i) {
      final x = size.width * i / (n - 1);
      final norm = range > 0 ? 1.0 - (closes[i] - minVal) / range : 0.5;
      final y = size.height * (0.05 + norm * 0.90);
      return Offset(x, y);
    });

    // Smooth line path
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final mid =
          Offset((pts[i].dx + pts[i + 1].dx) / 2, (pts[i].dy + pts[i + 1].dy) / 2);
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);

    // Gradient fill
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withAlpha(60), color.withAlpha(5)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Line
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Endpoint dot
    canvas.drawCircle(pts.last, 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _DetailChartPainter old) =>
      old.closes != closes || old.isPositive != isPositive;
}

// ── C. Key information card ───────────────────────────────────────────────────
class _KeyInfoCard extends StatelessWidget {
  final StockQuote quote;
  const _KeyInfoCard({required this.quote});

  @override
  Widget build(BuildContext context) {
    final color = quote.isPositive ? kPositive : kNegative;
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
              Expanded(child: _InfoBox(label: 'Ticker', value: quote.symbol)),
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

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Symbol', quote.symbol, false),
      ('Last Price (Close)', '\$${quote.close.toStringAsFixed(2)}', false),
      ('Opening Price', '\$${quote.open.toStringAsFixed(2)}', false),
      ('Day High', '\$${quote.high.toStringAsFixed(2)}', false),
      ('Day Low', '\$${quote.low.toStringAsFixed(2)}', false),
      ('Change %', quote.changeStr, true),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          final row = rows[i];
          final bool isLast = i == rows.length - 1;
          final Color valueColor = row.$3
              ? (quote.isPositive ? kPositive : kNegative)
              : kTextMain;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(row.$1,
                        style: const TextStyle(
                          color: kTextMuted,
                          fontSize: 13,
                        )),
                    Text(row.$2,
                        style: TextStyle(
                          color: valueColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ),
              if (!isLast)
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: kBorder,
                ),
            ],
          );
        }),
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
