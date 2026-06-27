import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Consistent vertical rhythm across Clarivo screens.
class ClarivoLayout {
  ClarivoLayout._();

  /// Top inset below [SafeArea] — compact but clear of status bar.
  static const double pageTop = 4;

  /// Gap between page header (title + subtitle) and first content block.
  static const double afterHeader = 12;

  /// Gap between major sections (cards, lists).
  static const double sectionGap = 10;

  /// Space below a section heading before its content.
  static const double headingBottom = 8;

  /// Extra space before the logout / destructive action.
  static const double beforeLogout = 14;
}

/// Shared typography for in-page section headings
/// (Your Holdings, Account Preferences, Price History, etc.).
class ClarivoSectionHeading extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const ClarivoSectionHeading({
    super.key,
    required this.text,
    this.trailing,
  });

  static const TextStyle style = TextStyle(
    color: kTextMain,
    fontSize: 15,
    fontWeight: FontWeight.bold,
  );

  @override
  Widget build(BuildContext context) {
    if (trailing == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: ClarivoLayout.headingBottom),
        child: Text(text, style: style),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: ClarivoLayout.headingBottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(text, style: style),
          trailing!,
        ],
      ),
    );
  }
}

/// Primary page title — 35px bold, consistent across Clarivo screens.
class ClarivoPageTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const ClarivoPageTitle({
    super.key,
    required this.title,
    this.subtitle,
  });

  static const TextStyle titleStyle = TextStyle(
    color: kTextMain,
    fontSize: 35,
    fontWeight: FontWeight.bold,
    height: 1.12,
    letterSpacing: -0.3,
  );

  static const TextStyle subtitleStyle = TextStyle(
    color: kTextMuted,
    fontSize: 14,
    height: 1.35,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: titleStyle),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: subtitleStyle),
        ],
      ],
    );
  }
}

/// Page title row with optional trailing actions (e.g. notification bell).
class ClarivoPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const ClarivoPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClarivoPageTitle(title: title, subtitle: subtitle),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

/// Small uppercase section label for grouped content blocks.
class ClarivoSectionLabel extends StatelessWidget {
  final String label;
  final EdgeInsetsGeometry padding;

  const ClarivoSectionLabel({
    super.key,
    required this.label,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 10),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: kTextMuted.withValues(alpha: 0.85),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

/// Notification bell — matches Home screen style.
class ClarivoBellButton extends StatelessWidget {
  const ClarivoBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
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
        ),
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
