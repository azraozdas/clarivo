import 'package:flutter/material.dart';

// ─── App Colors ───────────────────────────────────────────────────────────────
const Color kBackground = Color(0xFF07111F);
const Color kCard       = Color(0xFF0F1E2E);
const Color kCardAlt    = Color(0xFF132A3D);
const Color kAccent     = Color(0xFF00E096);
const Color kPositive   = Color(0xFF00C896);
const Color kNegative   = Color(0xFFFF4D5A);
const Color kTextMain   = Color(0xFFFFFFFF);
const Color kTextSec    = Color(0xFFA8B3C7);
const Color kTextMuted  = Color(0xFF6F7D91);
const Color kBorder     = Color(0xFF1E3448);

// ─── HomeScreen ───────────────────────────────────────────────────────────────
// StatefulWidget is used only for the BottomNavigationBar selected index,
// which is the simplest setState use case from the course PDF.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: (int i) => setState(() => _selectedIndex = i),
      ),
      // No scroll widget — everything is sized with Expanded + flex
      // so the layout always fits the screen exactly.
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 14),
              // Fixed-height header (naturally sized by its children).
              const _HeaderSection(),
              const SizedBox(height: 10),
              // Expanded claims all remaining vertical space and distributes
              // it proportionally to the balance card and stock section.
              // Balance card has a natural (content-driven) height now that
              // the chart is a fixed-height block and the time filter is gone.
              const _BalanceCard(),
              const SizedBox(height: 12),
              const _MarketSnapshotHeader(),
              const SizedBox(height: 8),
              // Expanded children fill all remaining space evenly — no dead
              // zone at the bottom. Because the balance card is now taller,
              // each stock card naturally receives less height than before.
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _StockCard(
                        name: 'Apple Inc.',
                        ticker: 'AAPL',
                        price: '€192.45',
                        change: '+1.8%',
                        isPositive: true,
                        initial: 'A',
                        iconColor: const Color(0xFF1A1A1A),
                        iconBorder: const Color(0xFF3A3A3A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _StockCard(
                        name: 'Tesla',
                        ticker: 'TSLA',
                        price: '€248.20',
                        change: '-0.9%',
                        isPositive: false,
                        initial: 'T',
                        iconColor: const Color(0xFF2A0A0A),
                        iconBorder: const Color(0xFF4A1A1A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _StockCard(
                        name: 'Amazon',
                        ticker: 'AMZN',
                        price: '€181.60',
                        change: '+2.1%',
                        isPositive: true,
                        initial: 'a',
                        iconColor: const Color(0xFF1A1200),
                        iconBorder: const Color(0xFF3A2800),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header Section ───────────────────────────────────────────────────────────
class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Greeting text on the left
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, Azra 👋',
              style: TextStyle(
                color: kTextMain,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Track your market today',
              style: TextStyle(color: kTextMuted, fontSize: 12),
            ),
          ],
        ),
        // Search icon button on the right
        _SearchButton(),
      ],
    );
  }
}

// ─── Search Button ────────────────────────────────────────────────────────────
class _SearchButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder, width: 1),
      ),
      child: const Icon(Icons.search, color: kTextSec, size: 20),
    );
  }
}

// ─── Balance Card ─────────────────────────────────────────────────────────────
// Clean financial summary card — no chart (real data will come from API later).
// Content-driven height: naturally sized by its children via mainAxisSize.min.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 26),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: "Total Balance" label  +  "Market is Open" status pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Balance',
                style: TextStyle(color: kTextMuted, fontSize: 12),
              ),
              _MarketStatusPill(),
            ],
          ),
          const SizedBox(height: 16),
          // Row 2: large balance number
          Text(
            '€12,450.00',
            style: TextStyle(
              color: kTextMain,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          // Row 3: daily percentage change
          Row(
            children: [
              const Icon(Icons.arrow_upward_rounded, size: 14, color: kPositive),
              const SizedBox(width: 3),
              Text(
                '+2.4% today',
                style: TextStyle(
                  color: kPositive,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Thin separator line
          Container(height: 1, color: kBorder),
          const SizedBox(height: 22),
          // Bottom stats row: three quick-read financial figures
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _CardStatItem(label: 'Invested', value: '€10,200.00'),
              _CardStatItem(
                label: 'Daily Gain',
                value: '+€250.00',
                valueColor: kPositive,
              ),
              _CardStatItem(label: 'Updated', value: 'Just now'),
            ],
          ),
        ],
      ),
    );
  }
}

// Small two-line stat used inside the balance card bottom row
class _CardStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _CardStatItem({
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
          style: const TextStyle(color: kTextMuted, fontSize: 10),
        ),
        const SizedBox(height: 3),
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

// ─── Market Status Pill ───────────────────────────────────────────────────────
class _MarketStatusPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x1F00E096),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x4000E096), width: 1),
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
          const SizedBox(width: 4),
          Text(
            'Market is Open',
            style: TextStyle(
              color: kAccent,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Market Snapshot Header ───────────────────────────────────────────────────
class _MarketSnapshotHeader extends StatelessWidget {
  const _MarketSnapshotHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Market Snapshot',
          style: TextStyle(
            color: kTextMain,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'View All >',
          style: TextStyle(
            color: kAccent,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Stock Card ───────────────────────────────────────────────────────────────
// Single stock row. Height is controlled by the parent Expanded so the
// three cards share the available space evenly without overflow.
class _StockCard extends StatelessWidget {
  final String name;
  final String ticker;
  final String price;
  final String change;
  final bool isPositive;
  final String initial;
  final Color iconColor;
  final Color iconBorder;

  const _StockCard({
    required this.name,
    required this.ticker,
    required this.price,
    required this.change,
    required this.isPositive,
    required this.initial,
    required this.iconColor,
    required this.iconBorder,
  });

  @override
  Widget build(BuildContext context) {
    final Color changeColor = isPositive ? kPositive : kNegative;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Company logo placeholder (rounded square with initial letter)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconBorder, width: 1),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: kTextMain,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Company name and ticker symbol
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
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
                  style: const TextStyle(color: kTextMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          // Price and percentage change
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                price,
                style: const TextStyle(
                  color: kTextMain,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                change,
                style: TextStyle(
                  color: changeColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Navigation Bar ────────────────────────────────────────────────────
class _BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onTap;

  const _BottomNavBar({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 6),
      decoration: const BoxDecoration(
        color: kCard,
        border: Border(top: BorderSide(color: kBorder, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onTap,
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kAccent,
        unselectedItemColor: kTextMuted,
        iconSize: 30,
        selectedFontSize: 12.5,
        unselectedFontSize: 12,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Portfolio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'News',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
