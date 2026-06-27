import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/clarivo_page_header.dart';

// ─── ProPage ──────────────────────────────────────────────────────────────────
class ProPage extends StatelessWidget {
  const ProPage({super.key});

  static const TextStyle _pageTitleStyle = TextStyle(
    color: kTextMain,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.12,
    letterSpacing: -0.3,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: kTextMain,
            size: 20,
          ),
        ),
        title: const SizedBox.shrink(),
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
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, ClarivoLayout.pageTop, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Clarivo Plans', style: _pageTitleStyle),
                const SizedBox(height: 4),
                Text(
                  'Upgrade when you need deeper insights.',
                  style: ClarivoPageTitle.subtitleStyle.copyWith(
                    color: kTextMuted,
                  ),
                ),
                const SizedBox(height: ClarivoLayout.headingBottom),
                const Expanded(
                  flex: 9,
                  child: _PlanCard(
                    planName: 'Free',
                    price: '€0',
                    period: '/ mo',
                    isRecommended: false,
                    buttonLabel: 'Start Free',
                    features: [
                      _Feature('Basic market overview', available: true),
                      _Feature('Stock snapshot', available: true),
                      _Feature('Market news', available: true),
                      _Feature('Portfolio tools', available: false),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Expanded(
                  flex: 11,
                  child: _PlanCard(
                    planName: 'Clarivo Pro',
                    price: '€4.99',
                    period: '/ mo',
                    isRecommended: true,
                    buttonLabel: 'Upgrade to Pro',
                    features: [
                      _Feature('Advanced insights', available: true),
                      _Feature('Portfolio overview', available: true),
                      _Feature('Ad-free experience', available: true),
                      _Feature('Priority alerts', available: true),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Expanded(
                  flex: 9,
                  child: _PlanCard(
                    planName: 'Clarivo Premium',
                    price: '€9.99',
                    period: '/ mo',
                    isRecommended: false,
                    buttonLabel: 'Go Premium',
                    features: [
                      _Feature('Everything in Pro', available: true),
                      _Feature('Extended analytics', available: true),
                      _Feature('More portfolio tools', available: true),
                      _Feature('Dedicated support', available: true),
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

class _Feature {
  final String label;
  final bool available;
  const _Feature(this.label, {required this.available});
}

class _PlanCard extends StatelessWidget {
  final String planName;
  final String price;
  final String period;
  final bool isRecommended;
  final String buttonLabel;
  final List<_Feature> features;

  const _PlanCard({
    required this.planName,
    required this.price,
    required this.period,
    required this.isRecommended,
    required this.buttonLabel,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    final double planNameSize = isRecommended ? 18 : 16;
    final double priceSize = isRecommended ? 26 : 22;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isRecommended
              ? const [Color(0xFF0C2148), Color(0xFF0F2D5A), Color(0xFF1E4C8F)]
              : const [Color(0xFF071C33), Color(0xFF0B2240)],
          stops: isRecommended
              ? const [0.0, 0.5, 1.0]
              : const [0.0, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecommended ? kAccent : kBorder,
          width: isRecommended ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isRecommended
                ? const Color(0x4042D6B5)
                : const Color(0x22000000),
            blurRadius: isRecommended ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(14, isRecommended ? 12 : 10, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            planName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: kTextMain,
                              fontSize: planNameSize,
                              fontWeight: FontWeight.bold,
                              height: 1.15,
                            ),
                          ),
                        ),
                        if (isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: kAccent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Best value',
                              style: TextStyle(
                                color: kBackground,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (isRecommended) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Most popular',
                        style: TextStyle(
                          color: kAccent.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: TextStyle(
                      color: isRecommended ? kAccent : kTextMain,
                      fontSize: priceSize,
                      fontWeight: FontWeight.bold,
                      height: 1,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    period,
                    style: const TextStyle(
                      color: kTextSec,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: isRecommended ? 8 : 6),
          Container(height: 1, color: kBorder),
          const SizedBox(height: 6),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: features
                    .map((f) => _FeatureRow(
                          feature: f,
                          emphasized: isRecommended,
                        ))
                    .toList(growable: false),
              ),
            ),
          ),
          SizedBox(height: isRecommended ? 4 : 6),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: isRecommended ? 11 : 9,
              ),
              decoration: BoxDecoration(
                color: isRecommended ? kAccent : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isRecommended
                    ? null
                    : Border.all(color: kBorder, width: 1),
                boxShadow: isRecommended
                    ? [
                        BoxShadow(
                          color: kAccent.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  buttonLabel,
                  style: TextStyle(
                    color: isRecommended ? kBackground : kTextMain,
                    fontSize: isRecommended ? 14 : 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: isRecommended ? 0.2 : 0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final _Feature feature;
  final bool emphasized;

  const _FeatureRow({
    required this.feature,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final double iconSize = emphasized ? 14 : 13;
    final double fontSize = emphasized ? 13 : 12;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              feature.available
                  ? Icons.check_rounded
                  : Icons.remove_rounded,
              size: iconSize + 2,
              color: feature.available ? kAccent : kTextMuted,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feature.label,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: TextStyle(
                color: feature.available ? kTextSec : kTextMuted,
                fontSize: fontSize,
                height: 1.35,
                fontWeight: emphasized && feature.available
                    ? FontWeight.w500
                    : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
