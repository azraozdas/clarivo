import 'package:flutter/material.dart';

import '../routes/app_routes.dart';


const Color kBackground  = Color(0xFF030D1C);
const Color kCard        = Color(0xFF071C33);
const Color kAccent      = Color(0xFF42D6B5);
const Color kPositive    = Color(0xFF42D6B5);
const Color kNegative    = Color(0xFFE66A73);
const Color kTextMain    = Color(0xFFFFFFFF);
const Color kTextSec     = Color(0xFFBCC9D6);
const Color kTextMuted   = Color(0xFFAABBC9);
const Color kBorder      = Color(0xFF2A3B4F);
const Color kNavInactive = Color(0xFF7E8998);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Handles bottom navigation taps.
  // Portfolio opens portfolio_page.dart using named routes (PDF Navigator lecture).
  // Other tabs only update the selected visual state for now.
  void _onNavTap(int index) {
    if (index == 1) {
      AppRoutes.openPortfolio(context);
      return;
    }
    if (index == 3) {
      AppRoutes.openProfile(context);
      return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030D1C),
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: (int i) => _onNavTap(i),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const _HeaderSection(),
                const SizedBox(height: 12),
                const _BalanceCard(),
                const SizedBox(height: 8),
                const _MarketSnapshotHeader(),
                const SizedBox(height: 6),
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
                          logoAsset: 'assets/tesla.png',
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
                          logoAsset: 'assets/amazon.png',
                        ),
                      ),
                      const SizedBox(height: 22),
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
        const _BellButton(),
      ],
    );
  }
}

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


class _BalanceCard extends StatelessWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0C2148),
            Color(0xFF0C2148),
            Color(0xFF1E4C8F),
          ],
          stops: [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0x66000000),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0x331E4C8F),
            blurRadius: 28,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
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
          Container(height: 1, color: kBorder),
          const SizedBox(height: 20),
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
    final Color changeColor = isPositive ? kPositive : kNegative;
    final IconData changeIcon =
        isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF0D1F2E),
            Color(0xFF0C2148),
            Color(0xFF142F69),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0x33000000),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
      decoration: BoxDecoration(
        color: const Color(0xFF0A1D3D),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: const Border(top: BorderSide(color: kBorder, width: 1)),
        boxShadow: const [
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
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                index: 0,
                selectedIndex: selectedIndex,
                onTap: onTap,
              ),
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
