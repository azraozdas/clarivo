import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared bottom navigation bar used by all main app screens.
/// Pass [selectedIndex] 0-3 and an [onTap] callback.
class ClarivoBotNavBar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onTap;

  const ClarivoBotNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  static const _outline = [
    Icons.home_outlined,
    Icons.trending_up_rounded,
    Icons.article_outlined,
    Icons.person_outline,
  ];

  static const _filled = [
    Icons.home,
    Icons.trending_up_rounded,
    Icons.article,
    Icons.person,
  ];

  static const _labels = ['Home', 'Portfolio', 'News', 'Profile'];

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
            children: List.generate(4, (i) {
              final bool selected = i == selectedIndex;
              final Color color =
                  selected ? kTextMain : const Color(0xFF8A9BAD);
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected ? _filled[i] : _outline[i],
                        color: color,
                        size: selected ? 30 : 26,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _labels[i],
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
