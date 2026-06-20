import 'package:flutter/material.dart';
import 'portfolio_page.dart';

const Color kBackground = Color(0xFF030D1C);
const Color kCard = Color(0xFF071C33);
const Color kAccent = Color(0xFF42D6B5);
const Color kPositive = Color(0xFF42D6B5);
const Color kNegative = Color(0xFFE66A73);
const Color kTextMain = Color(0xFFFFFFFF);
const Color kTextSec = Color(0xFFBCC9D6);
const Color kTextMuted = Color(0xFFAABBC9);
const Color kBorder = Color(0xFF2A3B4F);

class PortfolioPage extends StatelessWidget {
  const PortfolioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      bottomNavigationBar: PortfolioBottomNavBar(
        selectedIndex: 1,
        onTap: (i) {
          if (i == 0) Navigator.pop(context);
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
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SizedBox(height: 12),
                PortfolioHeader(),
                SizedBox(height: 14),
                PortfolioValueCard(),
                SizedBox(height: 14),
                PerformanceCard(),
                SizedBox(height: 14),
                PortfolioSectionTitle(),
                SizedBox(height: 8),
                HoldingCard(
                  name: 'Apple Inc.',
                  ticker: 'AAPL',
                  shares: '10 shares',
                  value: '€1,924.50',
                  change: '+1.8%',
                  isPositive: true,
                  logoAsset: 'assets/apple.png',
                  iconColor: Color(0xFF1A1A1A),
                  iconBorder: Color(0xFF3A3A3A),
                ),
                SizedBox(height: 10),
                HoldingCard(
                  name: 'Tesla',
                  ticker: 'TSLA',
                  shares: '5 shares',
                  value: '€1,241.00',
                  change: '-0.9%',
                  isPositive: false,
                  logoAsset: 'assets/tesla.png',
                  iconColor: Color(0xFF2A0A0A),
                  iconBorder: Color(0xFF4A1A1A),
                ),
                SizedBox(height: 10),
                HoldingCard(
                  name: 'Amazon',
                  ticker: 'AMZN',
                  shares: '8 shares',
                  value: '€1,452.80',
                  change: '+2.1%',
                  isPositive: true,
                  logoAsset: 'assets/amazon.png',
                  iconColor: Color(0xFF1A1200),
                  iconBorder: Color(0xFF3A2800),
                ),
                SizedBox(height: 14),
                SummaryCards(),
                SizedBox(height: 24),
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
              'Hello, Azra',
              style: TextStyle(
                color: kTextMain,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Track your investments',
              style: TextStyle(
                color: kTextMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
        BellButton(),
      ],
    );
  }
}

class BellButton extends StatelessWidget {
  const BellButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder, width: 1),
      ),
      child: const Icon(
        Icons.notifications_none_rounded,
        color: kTextSec,
        size: 22,
      ),
    );
  }
}

class PortfolioValueCard extends StatelessWidget {
  const PortfolioValueCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
            blurRadius: 24,
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
                style: TextStyle(color: kTextMuted, fontSize: 13),
              ),
              MarketStatusPill(),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '€12,450.00',
            style: TextStyle(
              color: kTextMain,
              fontSize: 38,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.arrow_upward_rounded, size: 15, color: kPositive),
              SizedBox(width: 4),
              Text(
                '+2.4% this month',
                style: TextStyle(
                  color: kPositive,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            width: double.infinity,
            child: CustomPaint(
              painter: WaveChartPainter(isPositive: true),
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: kBorder),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CardStatItem(label: 'Invested', value: '€10,200.00'),
              CardStatItem(
                label: 'Daily Gain',
                value: '+€250.00',
                valueColor: kPositive,
              ),
              CardStatItem(
                label: 'Return',
                value: '+€2,250.00',
                valueColor: kPositive,
              ),
            ],
          ),
        ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kTextMuted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? kTextSec,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
        border: Border.all(color: const Color(0x4042D6B5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: kAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'Live',
            style: TextStyle(
              color: kAccent,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class PerformanceCard extends StatelessWidget {
  const PerformanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance',
            style: TextStyle(
              color: kTextMain,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TimeTab(text: '1D'),
              TimeTab(text: '1W', active: true),
              TimeTab(text: '1M'),
              TimeTab(text: '3M'),
              TimeTab(text: '1Y'),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 120,
            child: CustomPaint(
              painter: WaveChartPainter(isPositive: true),
              child: SizedBox.expand(),
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

  const TimeTab({
    super.key,
    required this.text,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0x2242D6B5) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? kAccent : kTextSec,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class PortfolioSectionTitle extends StatelessWidget {
  const PortfolioSectionTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text(
          'Your Holdings',
          style: TextStyle(
            color: kTextMain,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'View All >',
          style: TextStyle(
            color: kAccent,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class HoldingCard extends StatelessWidget {
  final String name;
  final String ticker;
  final String shares;
  final String value;
  final String change;
  final bool isPositive;
  final String logoAsset;
  final Color iconColor;
  final Color iconBorder;

  const HoldingCard({
    super.key,
    required this.name,
    required this.ticker,
    required this.shares,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.logoAsset,
    required this.iconColor,
    required this.iconBorder,
  });

  @override
  Widget build(BuildContext context) {
    final Color changeColor = isPositive ? kPositive : kNegative;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF0D1F2E),
            Color(0xFF0C2148),
            Color(0xFF142F69),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.asset(
                logoAsset,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      ticker[0],
                      style: const TextStyle(
                        color: kTextMain,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                Text(
                  ticker,
                  style: const TextStyle(
                    color: kTextMuted,
                    fontSize: 13,
                  ),
                ),
                Text(
                  shares,
                  style: const TextStyle(
                    color: kTextMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 62,
            height: 38,
            child: CustomPaint(
              painter: MiniWavePainter(isPositive: isPositive),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: kTextMain,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Icon(
                    isPositive
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 13,
                    color: changeColor,
                  ),
                  Text(
                    change,
                    style: TextStyle(
                      color: changeColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}

class SummaryCards extends StatelessWidget {
  const SummaryCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
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
      height: 145,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Allocation',
            style: TextStyle(
              color: kTextMain,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: CustomPaint(
              painter: DonutPainter(),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 145,
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
          ActivityRow(text: 'Bought Apple'),
          ActivityRow(text: 'Sold Tesla', negative: true),
          ActivityRow(text: 'Bought Amazon'),
        ],
      ),
    );
  }
}

class ActivityRow extends StatelessWidget {
  final String text;
  final bool negative;

  const ActivityRow({
    super.key,
    required this.text,
    this.negative = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(
            negative
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            color: negative ? kNegative : kPositive,
            size: 18,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: kTextSec,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
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
        boxShadow: [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
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
    final Color itemColor = isSelected ? kTextMain : const Color(0xFF8A9BAD);

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
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class WaveChartPainter extends CustomPainter {
  final bool isPositive;

  const WaveChartPainter({required this.isPositive});

  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      Offset(0, size.height * 0.75),
      Offset(size.width * 0.12, size.height * 0.55),
      Offset(size.width * 0.25, size.height * 0.68),
      Offset(size.width * 0.38, size.height * 0.35),
      Offset(size.width * 0.50, size.height * 0.62),
      Offset(size.width * 0.65, size.height * 0.28),
      Offset(size.width * 0.78, size.height * 0.50),
      Offset(size.width * 0.90, size.height * 0.40),
      Offset(size.width, size.height * 0.18),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      path.quadraticBezierTo(p1.dx, p1.dy, mid.dx, mid.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          kPositive.withOpacity(0.35),
          kPositive.withOpacity(0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final linePaint = Paint()
      ..color = isPositive ? kPositive : kNegative
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
        size.width * 0.15,
        size.height * 0.25,
        size.width * 0.3,
        size.height * 0.45,
      )
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.7,
        size.width * 0.6,
        size.height * 0.35,
      )
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.55,
        size.width,
        isPositive ? size.height * 0.18 : size.height * 0.75,
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
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final radius = size.shortestSide * 0.32;
    const strokeWidth = 14.0;

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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}