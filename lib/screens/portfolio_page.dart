import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../services/marketstack_service.dart';

const Color kBackground = Color(0xFF030D1C);
const Color kCard = Color(0xFF071C33);
const Color kAccent = Color(0xFF42D6B5);
const Color kPositive = Color(0xFF42D6B5);
const Color kNegative = Color(0xFFE66A73);
const Color kTextMain = Color(0xFFFFFFFF);
const Color kTextSec = Color(0xFFBCC9D6);
const Color kTextMuted = Color(0xFFAABBC9);
const Color kBorder = Color(0xFF2A3B4F);

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  final Map<String, StockQuote> _quotes = {};
  bool _loading = true;

  static const Map<String, int> _shares = {'AAPL': 10, 'TSLA': 5, 'AMZN': 8};

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    try {
      final list = await MarketstackService.fetchLatest(['AAPL', 'TSLA', 'AMZN']);
      if (!mounted) return;
      setState(() {
        for (final q in list) { _quotes[q.symbol] = q; }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<double> _buildChartPoints() {
    if (_quotes.isEmpty) return [];
    const steps = 10;
    return List.generate(steps, (i) {
      final t = i / (steps - 1);
      double total = 0;
      for (final e in _shares.entries) {
        final q = _quotes[e.key];
        if (q != null) total += (q.open + (q.close - q.open) * t) * e.value;
      }
      return total;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      bottomNavigationBar: PortfolioBottomNavBar(
        selectedIndex: 1,
        onTap: (i) {
          if (i == 0) {
            AppRoutes.openHome(context);
          } else if (i == 3) {
            AppRoutes.openProfile(context);
          }
        },
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF030D1C),
              Color(0xFF0A2240),
              Color(0xFF06101D),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PortfolioHeader(),
                const SizedBox(height: 18),
                PortfolioValueCard(
                  quotes: _quotes,
                  shares: _shares,
                  loading: _loading,
                  chartPoints: _buildChartPoints(),
                ),
                const SizedBox(height: 18),
                const HoldingsHeader(),
                const SizedBox(height: 8),
                HoldingsPanel(quotes: _quotes, shares: _shares, loading: _loading),
                const SizedBox(height: 14),
                const SummaryCards(),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PortfolioHeader extends StatelessWidget {
  const PortfolioHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Portfolio',
              style: TextStyle(
                color: kTextMain,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Track your investments',
              style: TextStyle(color: kTextMuted, fontSize: 14),
            ),
          ],
        ),
        Row(
          children: [
            SearchButton(),
            SizedBox(width: 10),
            BellButton(),
          ],
        ),
      ],
    );
  }
}

class BellButton extends StatelessWidget {
  const BellButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const HeaderIconBox(icon: Icons.notifications_none_rounded),
        Positioned(
          top: -3,
          right: -3,
          child: Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: kAccent,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class SearchButton extends StatelessWidget {
  const SearchButton({super.key});

  @override
  Widget build(BuildContext context) {
    return const HeaderIconBox(icon: Icons.search_rounded);
  }
}

class HeaderIconBox extends StatelessWidget {
  final IconData icon;

  const HeaderIconBox({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Icon(icon, color: kTextSec, size: 25),
    );
  }
}

class PortfolioValueCard extends StatelessWidget {
  final Map<String, StockQuote> quotes;
  final Map<String, int> shares;
  final bool loading;
  final List<double> chartPoints;

  const PortfolioValueCard({
    super.key,
    required this.quotes,
    required this.shares,
    required this.loading,
    required this.chartPoints,
  });

  static String _fmt(double v) {
    final str = v.toStringAsFixed(2);
    final parts = str.split('.');
    final buf = StringBuffer();
    final digits = parts[0];
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    return '\$${buf.toString()}.${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    double total = 0;
    double dailyGain = 0;
    for (final entry in shares.entries) {
      final q = quotes[entry.key];
      if (q != null) {
        total += q.close * entry.value;
        dailyGain += (q.close - q.open) * entry.value;
      }
    }

    final bool hasData = !loading && quotes.isNotEmpty;
    final String totalStr = hasData ? _fmt(total) : '---';
    final String gainStr = hasData
        ? '${dailyGain >= 0 ? '+' : ''}${_fmt(dailyGain.abs())}'
        : '---';
    final bool gainPositive = !hasData || dailyGain >= 0;
    final double gainPct = (hasData && total > 0) ? (dailyGain / total) * 100 : 0;
    final String gainPctStr = hasData
        ? '${gainPositive ? '+' : ''}${gainPct.toStringAsFixed(1)}%'
        : '---';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0C2148),
            Color(0xFF0C2148),
            Color(0xFF1E4C8F),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Portfolio Value',
                style: TextStyle(
                  color: kTextSec,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              MarketStatusPill(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            totalStr,
            style: const TextStyle(
              color: kTextMain,
              fontSize: 38,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                gainPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 17,
                color: gainPositive ? kPositive : kNegative,
              ),
              const SizedBox(width: 4),
              Text(
                gainPctStr,
                style: TextStyle(
                  color: gainPositive ? kPositive : kNegative,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'today',
                style: TextStyle(color: kTextMuted, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TimeTab(text: '1D'),
              TimeTab(text: '1W', active: true),
              TimeTab(text: '1M'),
              TimeTab(text: '3M'),
              TimeTab(text: '1Y'),
              TimeTab(text: 'ALL'),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            width: double.infinity,
            child: CustomPaint(
              painter: MainChartPainter(dataPoints: chartPoints.isEmpty ? null : chartPoints),
            ),
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: kBorder),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CardStatItem(label: 'Invested', value: '\$10,200.00'),
              CardStatItem(
                label: 'Daily Gain',
                value: gainStr,
                valueColor: gainPositive ? kPositive : kNegative,
              ),
              const CardStatItem(label: 'Updated', value: 'Just now'),
            ],
          ),
        ],
      ),
    );
  }
}

class MarketStatusPill extends StatelessWidget {
  const MarketStatusPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x1F42D6B5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x4042D6B5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: kAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Market is Open',
            style: TextStyle(
              color: kAccent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class TimeTab extends StatelessWidget {
  final String text;
  final bool active;

  const TimeTab({super.key, required this.text, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: active ? const Color(0x2242D6B5) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: active ? kAccent : kTextSec,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class CardStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const CardStatItem({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 94,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: kTextMuted, fontSize: 13)),
          const SizedBox(height: 5),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: valueColor ?? kTextMain,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class HoldingsHeader extends StatelessWidget {
  const HoldingsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text(
          'Your Holdings',
          style: TextStyle(
            color: kTextMain,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'View All >',
          style: TextStyle(
            color: kAccent,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class HoldingsPanel extends StatelessWidget {
  final Map<String, StockQuote> quotes;
  final Map<String, int> shares;
  final bool loading;

  const HoldingsPanel({super.key, required this.quotes, required this.shares, required this.loading});

  String _holdingValue(String symbol) {
    final q = quotes[symbol];
    final n = shares[symbol] ?? 0;
    if (q == null) return '---';
    final v = q.close * n;
    return '\$${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final aapl = quotes['AAPL'];
    final tsla = quotes['TSLA'];
    final amzn = quotes['AMZN'];

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0D1F2E),
            Color(0xFF0C2148),
            Color(0xFF142F69),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          HoldingRow(
            name: 'Apple Inc.',
            ticker: 'AAPL',
            shares: '10 shares',
            value: _holdingValue('AAPL'),
            change: aapl?.changeStr ?? '---',
            isPositive: aapl?.isPositive ?? true,
            logoAsset: 'assets/apple.png',
            fallback: 'A',
          ),
          const Divider(height: 1, color: kBorder),
          HoldingRow(
            name: 'Tesla',
            ticker: 'TSLA',
            shares: '5 shares',
            value: _holdingValue('TSLA'),
            change: tsla?.changeStr ?? '---',
            isPositive: tsla?.isPositive ?? true,
            logoAsset: 'assets/tesla.png',
            fallback: 'T',
          ),
          const Divider(height: 1, color: kBorder),
          HoldingRow(
            name: 'Amazon',
            ticker: 'AMZN',
            shares: '8 shares',
            value: _holdingValue('AMZN'),
            change: amzn?.changeStr ?? '---',
            isPositive: amzn?.isPositive ?? true,
            logoAsset: 'assets/amazon.png',
            fallback: 'a',
          ),
        ],
      ),
    );
  }
}

class HoldingRow extends StatelessWidget {
  final String name;
  final String ticker;
  final String shares;
  final String value;
  final String change;
  final bool isPositive;
  final String logoAsset;
  final String fallback;

  const HoldingRow({
    super.key,
    required this.name,
    required this.ticker,
    required this.shares,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.logoAsset,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final Color changeColor = isPositive ? kPositive : kNegative;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          StockLogo(asset: logoAsset, fallback: fallback),
          const SizedBox(width: 12),
          SizedBox(
            width: 92,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kTextMain,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(ticker,
                    style: const TextStyle(color: kTextMuted, fontSize: 13)),
                Text(shares,
                    style: const TextStyle(color: kTextMuted, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 38,
              child: CustomPaint(
                painter: MiniWavePainter(isPositive: isPositive),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 88,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: kTextMain,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      isPositive
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 13,
                      color: changeColor,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      change,
                      style: TextStyle(
                        color: changeColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StockLogo extends StatelessWidget {
  final String asset;
  final String fallback;

  const StockLogo({
    super.key,
    required this.asset,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF111A25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Text(
                fallback,
                style: const TextStyle(
                  color: kTextMain,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class SummaryCards extends StatelessWidget {
  const SummaryCards({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: AllocationCard()),
        SizedBox(width: 10),
        Expanded(child: RecentActivityCard()),
      ],
    );
  }
}

class AllocationCard extends StatelessWidget {
  const AllocationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 165,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Portfolio Allocation',
            style: TextStyle(
              color: kTextMain,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: CustomPaint(
                    painter: DonutPainter(),
                    child: SizedBox.expand(),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: AllocationLegend(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AllocationLegend extends StatelessWidget {
  const AllocationLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LegendRow(color: kPositive, label: 'Apple', percent: '45%'),
        SizedBox(height: 12),
        LegendRow(color: kNegative, label: 'Tesla', percent: '25%'),
        SizedBox(height: 12),
        LegendRow(color: Colors.blueAccent, label: 'Amazon', percent: '30%'),
      ],
    );
  }
}

class LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String percent;

  const LegendRow({
    super.key,
    required this.color,
    required this.label,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: kTextSec, fontSize: 12),
          ),
        ),
        Text(
          percent,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 165,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: TextStyle(
              color: kTextMain,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          ActivityRow(
            title: 'Bought Apple Shares',
            subtitle: 'today • €1.200',
            isPositive: true,
          ),
          ActivityDivider(),
          ActivityRow(
            title: 'Sold Tesla Shares',
            subtitle: 'yesterday • €850',
            isPositive: false,
          ),
          ActivityDivider(),
          ActivityRow(
            title: 'Bought Amazon Shares',
            subtitle: 'may 18 • €950',
            isPositive: true,
          ),
        ],
      ),
    );
  }
}

class ActivityRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isPositive;

  const ActivityRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? kPositive : kNegative;

    return Expanded(
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(
              isPositive
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kTextMain,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6F7D8C),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: kTextMain,
            size: 24,
          ),
        ],
      ),
    );
  }
}

class ActivityDivider extends StatelessWidget {
  const ActivityDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, margin: const EdgeInsets.only(left: 42), color: kBorder);
  }
}

class MainChartPainter extends CustomPainter {
  final List<double>? dataPoints;

  const MainChartPainter({this.dataPoints});

  @override
  void paint(Canvas canvas, Size size) {
    final chartHeight = size.height - 24;
    final chartWidth = size.width - 44;

    final gridPaint = Paint()
      ..color = kBorder.withValues(alpha: 0.35)
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      final y = chartHeight * i / 4;
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    final List<Offset> points;

    if (dataPoints != null && dataPoints!.length >= 2) {
      final minVal = dataPoints!.reduce(math.min);
      final maxVal = dataPoints!.reduce(math.max);
      final range = maxVal - minVal;
      final n = dataPoints!.length;
      points = List.generate(n, (i) {
        final x = chartWidth * i / (n - 1);
        final norm = range > 0 ? 1.0 - (dataPoints![i] - minVal) / range : 0.5;
        final y = chartHeight * (0.05 + norm * 0.90);
        return Offset(x, y);
      });
    } else {
      points = [
        Offset(0, chartHeight * 0.85),
        Offset(chartWidth * 0.10, chartHeight * 0.72),
        Offset(chartWidth * 0.18, chartHeight * 0.67),
        Offset(chartWidth * 0.26, chartHeight * 0.48),
        Offset(chartWidth * 0.34, chartHeight * 0.55),
        Offset(chartWidth * 0.42, chartHeight * 0.40),
        Offset(chartWidth * 0.52, chartHeight * 0.50),
        Offset(chartWidth * 0.62, chartHeight * 0.30),
        Offset(chartWidth * 0.72, chartHeight * 0.38),
        Offset(chartWidth * 0.84, chartHeight * 0.25),
        Offset(chartWidth * 0.92, chartHeight * 0.18),
        Offset(chartWidth, chartHeight * 0.05),
      ];
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      path.quadraticBezierTo(p1.dx, p1.dy, mid.dx, mid.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(chartWidth, chartHeight)
      ..lineTo(0, chartHeight)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          kPositive.withValues(alpha: 0.38),
          kPositive.withValues(alpha: 0.03),
        ],
      ).createShader(Rect.fromLTWH(0, 0, chartWidth, chartHeight));

    final linePaint = Paint()
      ..color = kPositive
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
    canvas.drawCircle(points.last, 5, Paint()..color = kPositive);
  }

  @override
  bool shouldRepaint(covariant MainChartPainter old) =>
      old.dataPoints != dataPoints;
}

class MiniWavePainter extends CustomPainter {
  final bool isPositive;

  const MiniWavePainter({required this.isPositive});

  @override
  void paint(Canvas canvas, Size size) {
    final color = isPositive ? kPositive : kNegative;

    final path = Path()
      ..moveTo(0, size.height * 0.65)
      ..quadraticBezierTo(
        size.width * 0.18,
        isPositive ? size.height * 0.25 : size.height * 0.70,
        size.width * 0.35,
        size.height * 0.42,
      )
      ..quadraticBezierTo(
        size.width * 0.55,
        isPositive ? size.height * 0.70 : size.height * 0.35,
        size.width * 0.72,
        size.height * 0.34,
      )
      ..quadraticBezierTo(
        size.width * 0.86,
        size.height * 0.30,
        size.width,
        isPositive ? size.height * 0.16 : size.height * 0.62,
      );

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DonutPainter extends CustomPainter {
  const DonutPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.50, size.height * 0.50);
    final radius = size.shortestSide * 0.30;
    const strokeWidth = 15.0;

    final rect = Rect.fromCircle(center: center, radius: radius);

    final paints = [
      Paint()
        ..color = kPositive
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
      Paint()
        ..color = Colors.blueAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
      Paint()
        ..color = kNegative
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    ];

    double start = -1.57;
    final values = [0.45, 0.30, 0.25];

    for (int i = 0; i < values.length; i++) {
      canvas.drawArc(rect, start, values[i] * 6.28, false, paints[i]);
      start += values[i] * 6.28;
    }

    final tp = TextPainter(textDirection: TextDirection.ltr);
    final labels = [
      ('45%', Offset(center.dx + 10, center.dy - 4)),
      ('30%', Offset(center.dx - 44, center.dy - 28)),
      ('25%', Offset(center.dx - 17, center.dy + 38)),
    ];

    for (final item in labels) {
      tp.text = TextSpan(
        text: item.$1,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      );
      tp.layout();
      tp.paint(canvas, item.$2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PortfolioBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onTap;

  const PortfolioBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A1D3D),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(top: BorderSide(color: kBorder, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              PortfolioNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                index: 0,
                selectedIndex: selectedIndex,
                onTap: onTap,
              ),
              PortfolioNavItem(
                icon: Icons.trending_up_rounded,
                activeIcon: Icons.trending_up_rounded,
                label: 'Portfolio',
                index: 1,
                selectedIndex: selectedIndex,
                onTap: onTap,
              ),
              PortfolioNavItem(
                icon: Icons.article_outlined,
                activeIcon: Icons.article,
                label: 'News',
                index: 2,
                selectedIndex: selectedIndex,
                onTap: onTap,
              ),
              PortfolioNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                index: 3,
                selectedIndex: selectedIndex,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PortfolioNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int selectedIndex;
  final void Function(int) onTap;

  const PortfolioNavItem({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = index == selectedIndex;
    final Color itemColor = isSelected ? kAccent : const Color(0xFF8A9BAD);

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: itemColor,
              size: isSelected ? 30 : 26,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: itemColor,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}