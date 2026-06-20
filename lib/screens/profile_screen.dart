import 'package:flutter/material.dart';

import '../routes/app_routes.dart';

// ─── Profile Colors ────────────────────────────────────────────────────────────
// These match the Clarivo design system exactly (same values as home_screen.dart).
// Defined as local constants so this file is self-contained.
const Color _kBackground  = Color(0xFF030D1C);
const Color _kCard        = Color(0xFF071C33);
const Color _kAccent      = Color(0xFF42D6B5);
const Color _kNegative    = Color(0xFFE66A73);
const Color _kTextMain    = Color(0xFFFFFFFF);
const Color _kTextSec     = Color(0xFFBCC9D6);
const Color _kTextMuted   = Color(0xFFAABBC9);
const Color _kBorder      = Color(0xFF2A3B4F);
const Color _kNavInactive = Color(0xFF7E8998);

// ─── ProfileScreen ─────────────────────────────────────────────────────────────
// StatefulWidget so the bottom navigation can track the selected tab.
// PDF StatefulWidget + setState pattern — index = 3 (Profile is the active tab).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final int _selectedIndex = 3;

  void _onNavTap(int index) {
    if (index == 0) {
      AppRoutes.openHome(context);
    } else if (index == 1) {
      AppRoutes.openPortfolio(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      bottomNavigationBar: _ProfileBottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onNavTap,
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),
                const _ProfileHeader(),
                const SizedBox(height: 14),
                // User info card — natural height, slightly more padding.
                const _UserInfoCard(),
                const SizedBox(height: 14),
                // Pro card uses Flexible so it expands to fill leftover space.
                // flex: 1 means it absorbs all unclaimed vertical space, making
                // the bottom gap disappear without forcing any fixed height.
                const Flexible(
                  child: _ProCard(),
                ),
                const SizedBox(height: 14),
                // Support section — natural height.
                const _SupportSection(),
                const SizedBox(height: 16),
                const _LogoutButton(),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Profile Header ────────────────────────────────────────────────────────────
// Page title on the left, settings button on the right.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Profile',
              style: TextStyle(
                color: _kTextMain,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Manage your account and preferences',
              style: TextStyle(
                color: _kTextMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder, width: 1),
          ),
          child: const Icon(
            Icons.settings_outlined,
            color: _kTextSec,
            size: 20,
          ),
        ),
      ],
    );
  }
}

// ─── User Info Card ────────────────────────────────────────────────────────────
// Avatar + name + email + plan badge on the left, edit button on the right.
// Padding increased to 16 (was 14) for a slightly taller, more balanced card.
class _UserInfoCard extends StatelessWidget {
  const _UserInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _kAccent, width: 2),
            ),
            child: const CircleAvatar(
              backgroundColor: Color(0xFF0C2148),
              child: Text(
                'AZ',
                style: TextStyle(
                  color: _kAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Azra Özdaş',
                  style: TextStyle(
                    color: _kTextMain,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'azra.ozdas@ue-germany.de',
                  style: TextStyle(
                    color: _kTextMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 9),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x1F42D6B5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0x4042D6B5),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'Free Plan',
                    style: TextStyle(
                      color: _kAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF0C2148),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kAccent, width: 1),
            ),
            child: const Icon(
              Icons.edit_outlined,
              color: _kAccent,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Clarivo Pro Card ──────────────────────────────────────────────────────────
// Premium upgrade card — wrapped in Flexible in the parent so it absorbs
// the leftover vertical space without having a fixed height.
// Content is compact and sequential — no Spacer, no spaceBetween.
// The card stays content-driven; Flexible just lets it grow to fill the gap.
class _ProCard extends StatelessWidget {
  const _ProCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity, // fills the Flexible constraint
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x8042D6B5), width: 1),
        boxShadow: [
          const BoxShadow(
            color: Color(0x66000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0x221E4C8F),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // Column with mainAxisAlignment.spaceBetween distributes the three
      // content groups evenly across the available card height — top content,
      // upgrade button, and features — so the space is always proportional,
      // never bunched or overly stretched.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Top: title + price + description ─────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0x2242D6B5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0x5542D6B5),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: _kAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Clarivo Pro',
                        style: TextStyle(
                          color: _kTextMain,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '€4.99 / month',
                        style: TextStyle(
                          color: _kAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Unlock advanced insights and portfolio analytics',
                style: TextStyle(
                  color: _kTextSec,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
          // ── Middle: upgrade button ────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: _kAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Upgrade',
                style: TextStyle(
                  color: Color(0xFF030D1C),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // ── Bottom: divider + feature icons ──────────────────────────────────
          Column(
            children: [
              Container(height: 1, color: const Color(0xFF2A3B4F)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _ProFeature(
                    icon: Icons.insights_rounded,
                    label: 'Advanced\nInsights',
                  ),
                  _ProFeature(
                    icon: Icons.bar_chart_rounded,
                    label: 'Portfolio\nAnalytics',
                  ),
                  _ProFeature(
                    icon: Icons.block_rounded,
                    label: 'Ad-Free\nExperience',
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

// ─── Pro Feature ──────────────────────────────────────────────────────────────
// Small icon + two-line label used inside the Pro card feature row.
class _ProFeature extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProFeature({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: _kAccent, size: 20),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _kTextMuted,
            fontSize: 11,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

// ─── Support Section ──────────────────────────────────────────────────────────
// Section title + rounded card with three tappable rows.
// Row vertical padding increased to 16 (was 14) for better touch targets.
class _SupportSection extends StatelessWidget {
  const _SupportSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Support',
          style: TextStyle(
            color: _kTextMain,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _kBorder, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _SupportRow(
                icon: Icons.help_outline_rounded,
                label: 'Help Center',
                showDivider: true,
              ),
              _SupportRow(
                icon: Icons.headset_mic_outlined,
                label: 'Contact Support',
                showDivider: true,
              ),
              _SupportRow(
                icon: Icons.description_outlined,
                label: 'Terms & Conditions',
                showDivider: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Support Row ──────────────────────────────────────────────────────────────
// One tappable row: icon → label → arrow.
// Vertical padding 16 gives each row a comfortable touch target.
class _SupportRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool showDivider;

  const _SupportRow({
    required this.icon,
    required this.label,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: _kAccent, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _kTextMain,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: _kTextMuted,
                size: 13,
              ),
            ],
          ),
        ),
        if (showDivider)
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: _kBorder,
          ),
      ],
    );
  }
}

// ─── Logout Button ────────────────────────────────────────────────────────────
// Full-width outlined button with red border and red label.
// Tapping Logout clears the stack and returns to the Login screen.
class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AppRoutes.openLoginAndClearStack(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kNegative, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.logout_rounded, color: _kNegative, size: 20),
            SizedBox(width: 8),
            Text(
              'Logout',
              style: TextStyle(
                color: _kNegative,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Profile Bottom Nav Bar ───────────────────────────────────────────────────
// Matches the Home and Portfolio nav bar exactly — same styling, same icons.
class _ProfileBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onTap;

  const _ProfileBottomNavBar({
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
        border: const Border(top: BorderSide(color: _kBorder, width: 1)),
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
              _ProfileNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                index: 0,
                selectedIndex: selectedIndex,
                onTap: onTap,
              ),
              _ProfileNavItem(
                icon: Icons.trending_up_rounded,
                activeIcon: Icons.trending_up_rounded,
                label: 'Portfolio',
                index: 1,
                selectedIndex: selectedIndex,
                onTap: onTap,
              ),
              _ProfileNavItem(
                icon: Icons.article_outlined,
                activeIcon: Icons.article,
                label: 'News',
                index: 2,
                selectedIndex: selectedIndex,
                onTap: onTap,
              ),
              _ProfileNavItem(
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

// ─── Profile Nav Item ─────────────────────────────────────────────────────────
// One navigation tab — identical structure to _NavItem in home_screen.dart.
class _ProfileNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int selectedIndex;
  final void Function(int) onTap;

  const _ProfileNavItem({
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
    final Color itemColor = isSelected ? Colors.white : _kNavInactive;

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
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: itemColor,
                fontSize: 12,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
