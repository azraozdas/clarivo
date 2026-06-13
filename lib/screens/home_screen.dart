import 'package:flutter/material.dart';

// ─── App Colors ───────────────────────────────────────────────────────────────
// Compile-time constants following the PDF "Final vs Const" lecture.
// Every widget that references a constant picks up changes made here.
const Color kBackground  = Color(0xFF030D1C); // deepest navy — darkest background tone
const Color kCard        = Color(0xFF101C2B); // bell button + nav bar
const Color kAccent      = Color(0xFF42D6B5); // teal-green brand accent
const Color kPositive    = Color(0xFF42D6B5); // financial gain
const Color kNegative    = Color(0xFFE66A73); // financial loss — soft red
const Color kTextMain    = Color(0xFFFFFFFF);
const Color kTextSec     = Color(0xFFBCC9D6); // stat values, secondary data
const Color kTextMuted   = Color(0xFFAABBC9); // labels, tickers, subtitles
const Color kBorder      = Color(0xFF2A3B4F);
const Color kNavInactive = Color(0xFF7E8998);

// ─── HomeScreen ───────────────────────────────────────────────────────────────
// StatefulWidget tracks the selected navigation tab.
// _selectedIndex stores state; setState triggers a rebuild on each tap.
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
      // Darkest background tone — area behind the nav bar blends in seamlessly.
      backgroundColor: const Color(0xFF030D1C),
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: (int i) => setState(() => _selectedIndex = i),
      ),
      // Container + LinearGradient give the page a premium dark gradient background.
      // The brighter center creates depth behind the cards — no packages needed.
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF030D1C), // top — very deep dark navy
              Color(0xFF0A2240), // middle — brighter blue, creates depth
              Color(0xFF06101D), // bottom — deep dark navy
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const _HeaderSection(),
                const SizedBox(height: 12),
                // Balance card grows to exactly fit its content.
                // The Expanded section below gets whatever space remains.
                const _BalanceCard(),
                const SizedBox(height: 12),
                const _MarketSnapshotHeader(),
                const SizedBox(height: 10),
                // Expanded distributes remaining height among the three stock
                // cards equally — core PDF layout pattern.
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
                          logoAsset: 'assets/apple.png',
                        ),
                      ),
                      const SizedBox(height: 14), // breathing room between cards
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
                          logoAsset: 'assets/tesla.png',
                        ),
                      ),
                      const SizedBox(height: 14), // breathing room between cards
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
                          logoAsset: 'assets/amazon.png',
                        ),
                      ),
                      // Clear breathing room between the last card and the nav bar.
                      // Prevents the Market Snapshot section from feeling cramped
                      // against the bottom of the screen.
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Header Section ───────────────────────────────────────────────────────────
// Greeting + subtitle on the left, notification bell on the right.
// Extracted StatelessWidget — PDF Extract Widget / Refactoring pattern.
class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hello, Azra',
              style: TextStyle(
                color: kTextMain,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Track your market today',
              style: TextStyle(
                color: kTextMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
        // Bell icon replaces search — same rounded-square style, same dark card.
        const _BellButton(),
      ],
    );
  }
}

// ─── Bell Button ─────────────────────────────────────────────────────────────
// Notification bell — top-right mobile convention.
// No functionality yet; only the icon changes in this phase.
// const constructor: no mutable state (PDF Final vs Const lecture).
class _BellButton extends StatelessWidget {
  const _BellButton();

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

// ─── Balance Card ─────────────────────────────────────────────────────────────
// Primary hero card — the most important element on the Home Page.
//
// Visual dominance comes from:
//   • Generous internal padding (30 top, 26 bottom)
//   • Largest text on the screen (fontSize 40)
//   • Premium gradient: #0C2148 (main) → #1E4C8F (shiny blue corner)
//   • Two layered shadows: dark depth + blue glow — exclusive to this card
//
// Stock cards use only a single dark shadow — no blue glow — so the hierarchy
// is always clear: balance card glows, stock cards do not.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 26),
      decoration: BoxDecoration(
        // Three-stop gradient: main color (#0C2148) dominates most of the card,
        // only the bottom-right corner brightens to a shiny blue (#1E4C8F).
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0C2148), // main color — top-left base
            Color(0xFF0C2148), // main color held across 60% of the card
            Color(0xFF1E4C8F), // shiny blue — luminous highlight corner
          ],
          stops: [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kBorder, width: 1),
        // Two shadows — exclusive to the balance card for maximum hierarchy.
        // Stock cards only get one dark shadow; the blue glow belongs here only.
        boxShadow: [
          BoxShadow(
            color: const Color(0x66000000), // dark — grounds the card
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0x331E4C8F), // blue glow at ~20% — subtle shine
            blurRadius: 28,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: section label left, live market badge right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Total Balance',
                style: TextStyle(
                  color: kTextMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              _MarketStatusPill(),
            ],
          ),
          const SizedBox(height: 22),
          // Hero balance — the single largest text on the screen.
          const Text(
            '€12,450.00',
            style: TextStyle(
              color: kTextMain,
              fontSize: 40,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          // Daily change — arrow provides a direction cue beyond color alone.
          Row(
            children: const [
              Icon(Icons.arrow_upward_rounded, size: 15, color: kPositive),
              SizedBox(width: 4),
              Text(
                '+2.4% today',
                style: TextStyle(
                  color: kPositive,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          // Thin separator — divides the hero zone from the supporting stats.
          Container(height: 1, color: kBorder),
          const SizedBox(height: 20),
          // Three supporting statistics — context for the hero number.
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

// ─── Card Stat Item ───────────────────────────────────────────────────────────
// Reusable two-line label + value — PDF Extract Widget pattern.
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
          style: const TextStyle(
            color: kTextMuted,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? kTextSec,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Market Status Pill ───────────────────────────────────────────────────────
// Static "Market is Open" badge — API + Geolocator will drive this later.
class _MarketStatusPill extends StatelessWidget {
  const _MarketStatusPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x1F42D6B5), // accent at ~12% opacity
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
            'Market is Open',
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

// ─── Market Snapshot Header ───────────────────────────────────────────────────
// Section title row with accent "View All >" link on the right.
class _MarketSnapshotHeader extends StatelessWidget {
  const _MarketSnapshotHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text(
          'Market Snapshot',
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

// ─── Stock Card ───────────────────────────────────────────────────────────────
// Secondary information tier — clearly below the balance card in hierarchy.
//
// Design-system relationship with the balance card:
//   • Same gradient direction (topLeft → bottomRight) — same design language
//   • Same border treatment (kBorder, width 1) — same system
//   • Same shadow philosophy — but softer, single shadow only (no blue glow)
//   • More visible gradient (#0E2236 → #1C3E63) — clearly blue, clearly distinct
//     from the balance card's darker #0C2148 base
//
// All three cards share Expanded space equally — PDF layout pattern.
// logoAsset: Image.asset with errorBuilder — falls back to letter initial.
class _StockCard extends StatelessWidget {
  final String name;
  final String ticker;
  final String price;
  final String change;
  final bool isPositive;
  final String initial;
  final Color iconColor;
  final Color iconBorder;
  final String logoAsset;

  const _StockCard({
    required this.name,
    required this.ticker,
    required this.price,
    required this.change,
    required this.isPositive,
    required this.initial,
    required this.iconColor,
    required this.iconBorder,
    required this.logoAsset,
  });

  @override
  Widget build(BuildContext context) {
    // Dual encoding: color (green/red) + icon shape (arrow up/down).
    // Improves accessibility for colorblind users.
    final Color changeColor = isPositive ? kPositive : kNegative;
    final IconData changeIcon =
        isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      decoration: BoxDecoration(
        // Horizontal gradient positioned to the right side of the card.
        // The dark base (#0E2236) is held across the left half (logo + name +
        // ticker), then transitions smoothly to the brighter blue (#102B61) on
        // the right, guiding the eye toward the price/percentage values.
        // Same colors as before — only the position changes.
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF0D1F45), // dark base — left edge (logo area)
            Color(0xFF0D1F45), // dark base held through the company name area
            Color(0xFF183B87), // brighter blue — right side (price/percentage)
          ],
          stops: [0.0, 0.5, 1.0], // gradient only starts after the midpoint
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0x33000000), // black at ~20% — gentle depth only
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Logo area ────────────────────────────────────────────────────────
          // 44×44 rounded square reserves space for future Image.asset logos.
          // ClipRRect clips the loaded image to the rounded corner shape.
          // errorBuilder shows the letter initial when the file is missing.
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconBorder, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.asset(
                logoAsset,
                width: 44,
                height: 44,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      initial,
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
          // ── Company name + ticker ────────────────────────────────────────────
          // Expanded fills the middle zone — name above, ticker below.
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
                const SizedBox(height: 3),
                Text(
                  ticker,
                  style: const TextStyle(
                    color: kTextMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // ── Price + directional change ───────────────────────────────────────
          // Right-aligned so numbers line up across all three cards.
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
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(changeIcon, size: 12, color: changeColor),
                  const SizedBox(width: 2),
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
        ],
      ),
    );
  }
}

// ─── Bottom Navigation Bar ────────────────────────────────────────────────────
// Custom nav bar — Row + Expanded + _NavItem widgets.
// PDF-taught widgets only: Container, Row, Expanded, Column, IconButton.
//
// Interaction: IconButton.onPressed → onTap(index) → setState in HomeScreen.
// Active: bright white icon (28px) + white label.
// Inactive: muted gray icon (25px) + gray label.
// No dot — selection shown through color and icon size only.
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
      decoration: const BoxDecoration(
        color: kCard,
        border: Border(top: BorderSide(color: kBorder, width: 1)),
      ),
      // SafeArea(top: false) pads the bottom only — handles iOS home indicator.
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                index: 0,
                selectedIndex: selectedIndex,
                onTap: onTap,
              ),
              // Portfolio: trending_up icon communicates growth and market movement.
              _NavItem(
                icon: Icons.trending_up_rounded,
                activeIcon: Icons.trending_up_rounded,
                label: 'Portfolio',
                index: 1,
                selectedIndex: selectedIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.article_outlined,
                activeIcon: Icons.article,
                label: 'News',
                index: 2,
                selectedIndex: selectedIndex,
                onTap: onTap,
              ),
              _NavItem(
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

// ─── Nav Item ─────────────────────────────────────────────────────────────────
// One navigation tab — extracted StatelessWidget (PDF Refactoring lecture).
//
// Structure (top → bottom):
//   IconButton  — tap detection; filled/larger when active, outlined/smaller inactive
//   Text        — label; white when active, muted gray when inactive
//
// Selected state: white icon (28px) + white bold label.
// Unselected state: gray icon (25px) + gray label.
// No dot indicator — clean, calm, professional selection feedback.
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int selectedIndex;
  final void Function(int) onTap;

  const _NavItem({
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
    // Active = kTextMain (white). Inactive = kNavInactive (muted gray).
    final Color itemColor = isSelected ? kTextMain : kNavInactive;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Active icon is 28px (larger presence), inactive is 25px.
          // Size difference reinforces selection state alongside color.
          IconButton(
            onPressed: () => onTap(index),
            iconSize: isSelected ? 28 : 25,
            icon: Icon(
              isSelected ? activeIcon : icon,
              color: itemColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: itemColor,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              letterSpacing: isSelected ? 0.2 : 0.0,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
