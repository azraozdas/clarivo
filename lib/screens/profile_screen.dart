import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import 'pro_page.dart';

// ─── Profile Colors ────────────────────────────────────────────────────────────
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
// StatefulWidget — index = 3, Profile is the active tab.
// No scrolling — layout is sized to fit a standard mobile screen (375 × 812).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final int _selectedIndex = 3;

  void _onNavTap(int index) {
    if (index == 0) AppRoutes.openHome(context);
    if (index == 1) AppRoutes.openPortfolio(context);
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
              children: const [
                SizedBox(height: 12),
                _ProfileHeader(),
                SizedBox(height: 12),
                _UserInfoCard(),
                SizedBox(height: 9),
                _PreferencesSection(),
                SizedBox(height: 9),
                _PrivacySection(),
                SizedBox(height: 9),
                _SupportSection(),
                SizedBox(height: 9),
                _LogoutButton(),
                SizedBox(height: 9),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Profile Header ────────────────────────────────────────────────────────────
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
                fontSize: 25,
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
            size: 21,
          ),
        ),
      ],
    );
  }
}

// ─── User Info Card ────────────────────────────────────────────────────────────
// The main account card — intentionally larger than the settings cards below.
// Avatar + name + email + Free Plan badge + prominent Upgrade button + edit icon.
class _UserInfoCard extends StatelessWidget {
  const _UserInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar — slightly larger to dominate the card
          Container(
            width: 64,
            height: 64,
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
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Name / email / plan + upgrade
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Azra Özdaş',
                  style: TextStyle(
                    color: _kTextMain,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'azra.ozdas@ue-germany.de',
                  style: TextStyle(
                    color: _kTextMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 11),
                // Free Plan badge (secondary) + Upgrade button (primary CTA)
                Row(
                  children: [
                    // Free Plan — subtle outline badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0x1442D6B5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0x3842D6B5),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'Free Plan',
                        style: TextStyle(
                          color: _kAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    // Upgrade — solid accent, glow shadow, clearly dominant
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProPage(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: _kAccent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x6642D6B5),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Upgrade',
                          style: TextStyle(
                            color: Color(0xFF030D1C),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Edit icon
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

// ─── Account Preferences Section ──────────────────────────────────────────────
class _PreferencesSection extends StatelessWidget {
  const _PreferencesSection();

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: 'Account Preferences',
      rows: const [
        _MenuRow(
          icon: Icons.notifications_none_rounded,
          label: 'Notifications',
          showDivider: true,
        ),
        _MenuRow(
          icon: Icons.language_rounded,
          label: 'Language',
          showDivider: true,
        ),
        _MenuRow(
          icon: Icons.shield_outlined,
          label: 'Security',
          showDivider: false,
        ),
      ],
    );
  }
}

// ─── Privacy & Security Section ───────────────────────────────────────────────
// Compact 2-row section that adds content weight between Preferences and Support.
class _PrivacySection extends StatelessWidget {
  const _PrivacySection();

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: 'Privacy & Security',
      rows: const [
        _MenuRow(
          icon: Icons.lock_outline_rounded,
          label: 'Login Activity',
          showDivider: true,
        ),
        _MenuRow(
          icon: Icons.privacy_tip_outlined,
          label: 'Data Privacy',
          showDivider: false,
        ),
      ],
    );
  }
}

// ─── Support Section ──────────────────────────────────────────────────────────
class _SupportSection extends StatelessWidget {
  const _SupportSection();

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: 'Support',
      rows: const [
        _MenuRow(
          icon: Icons.help_outline_rounded,
          label: 'Help Center',
          showDivider: true,
        ),
        _MenuRow(
          icon: Icons.headset_mic_outlined,
          label: 'Contact Support',
          showDivider: true,
        ),
        _MenuRow(
          icon: Icons.description_outlined,
          label: 'Terms & Conditions',
          showDivider: false,
        ),
      ],
    );
  }
}

// ─── Settings Card ────────────────────────────────────────────────────────────
// Reusable titled card wrapper used by all three settings sections.
// Keeping this as a shared widget avoids duplicating the decoration code.
class _SettingsCard extends StatelessWidget {
  final String title;
  final List<Widget> rows;

  const _SettingsCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _kTextMain,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kBorder, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: rows,
          ),
        ),
      ],
    );
  }
}

// ─── Menu Row ─────────────────────────────────────────────────────────────────
// Shared row: icon → label → arrow. Vertical padding 10 px — compact but airy.
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool showDivider;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: _kAccent, size: 19),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _kTextMain,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: _kTextMuted,
                size: 12,
              ),
            ],
          ),
        ),
        if (showDivider)
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: _kBorder,
          ),
      ],
    );
  }
}

// ─── Logout Button ────────────────────────────────────────────────────────────
// Full-width outlined red button — tapping clears the stack and goes to Login.
class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AppRoutes.openLoginAndClearStack(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
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
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
