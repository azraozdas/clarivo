import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../widgets/clarivo_nav_bar.dart';
import '../widgets/clarivo_page_header.dart';
import 'pro_page.dart';

// ─── ProfileScreen ─────────────────────────────────────────────────────────────
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: const ClarivoAppBar(title: 'Profile'),
      bottomNavigationBar: ClarivoBotNavBar(
        selectedIndex: 3,
        onTap: (i) {
          if (i == 0) AppRoutes.openHome(context);
          if (i == 1) AppRoutes.openPortfolio(context);
          if (i == 2) AppRoutes.openNews(context);
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: ClarivoLayout.pageTop),
                const _ProfileHeader(),
                const SizedBox(height: ClarivoLayout.afterHeader),
                const _UserInfoCard(),
                const SizedBox(height: ClarivoLayout.sectionGap),
                const _PreferencesSection(),
                const SizedBox(height: ClarivoLayout.sectionGap),
                const _PrivacySection(),
                const SizedBox(height: ClarivoLayout.sectionGap),
                const _SupportSection(),
                const SizedBox(height: ClarivoLayout.beforeLogout),
                const _LogoutButton(),
                const SizedBox(height: 12),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Text(
            'Manage your account and preferences',
            style: ClarivoPageTitle.subtitleStyle,
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder, width: 1),
          ),
          child: const Icon(Icons.settings_outlined, color: kTextSec, size: 21),
        ),
      ],
    );
  }
}

// ─── User Info Card ────────────────────────────────────────────────────────────
class _UserInfoCard extends StatelessWidget {
  const _UserInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kAccent, width: 2),
                ),
                child: const CircleAvatar(
                  backgroundColor: Color(0xFF0C2148),
                  child: Text(
                    'AZ',
                    style: TextStyle(
                      color: kAccent,
                      fontSize: 20,
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
                        color: kTextMain,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'azra.ozdas@ue-germany.de',
                      style: TextStyle(color: kTextMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 11),
                    Row(
                      children: [
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
                              color: kAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProPage(),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: kAccent,
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
                                color: kBackground,
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
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF0C2148),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kAccent, width: 1),
                ),
                child:
                    const Icon(Icons.edit_outlined, color: kAccent, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _PreferencesSection extends StatelessWidget {
  const _PreferencesSection();

  @override
  Widget build(BuildContext context) {
    return const _SettingsCard(
      title: 'Account Preferences',
      rows: [
        _MenuRow(
            icon: Icons.notifications_none_rounded,
            label: 'Notifications',
            showDivider: true),
        _MenuRow(
            icon: Icons.language_rounded,
            label: 'Language',
            showDivider: true),
        _MenuRow(
            icon: Icons.shield_outlined,
            label: 'Security',
            showDivider: false),
      ],
    );
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection();

  @override
  Widget build(BuildContext context) {
    return const _SettingsCard(
      title: 'Privacy & Security',
      rows: [
        _MenuRow(
            icon: Icons.lock_outline_rounded,
            label: 'Login Activity',
            showDivider: true),
        _MenuRow(
            icon: Icons.privacy_tip_outlined,
            label: 'Data Privacy',
            showDivider: false),
      ],
    );
  }
}

class _SupportSection extends StatelessWidget {
  const _SupportSection();

  @override
  Widget build(BuildContext context) {
    return const _SettingsCard(
      title: 'Support',
      rows: [
        _MenuRow(
            icon: Icons.help_outline_rounded,
            label: 'Help Center',
            showDivider: true),
        _MenuRow(
            icon: Icons.headset_mic_outlined,
            label: 'Contact Support',
            showDivider: true),
        _MenuRow(
            icon: Icons.description_outlined,
            label: 'Terms & Conditions',
            showDivider: false),
      ],
    );
  }
}

// ─── Settings Card ────────────────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final String title;
  final List<Widget> rows;

  const _SettingsCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClarivoSectionHeading(text: title),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: rows),
        ),
      ],
    );
  }
}

// ─── Menu Row ─────────────────────────────────────────────────────────────────
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
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(icon, color: kAccent, size: 19),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: kTextMain,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: kTextMuted,
                    size: 12,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: kBorder,
          ),
      ],
    );
  }
}

// ─── Logout Button ────────────────────────────────────────────────────────────
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
          border: Border.all(color: kNegative, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.logout_rounded, color: kNegative, size: 20),
            SizedBox(width: 8),
            Text(
              'Logout',
              style: TextStyle(
                color: kNegative,
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
