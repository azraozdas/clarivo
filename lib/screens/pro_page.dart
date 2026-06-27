import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

// ─── ProPage ──────────────────────────────────────────────────────────────────
class ProPage extends StatelessWidget {
  const ProPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: const Color(0xFF071C33),
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
        title: const Text(
          'Clarivo Plans',
          style: TextStyle(
            color: kTextMain,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kBorder),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose your plan',
                style: TextStyle(
                  color: kTextMain,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Upgrade when you need deeper insights.',
                style: TextStyle(
                  color: kTextSec.withValues(alpha: 0.95),
                  fontSize: 11,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),
              const Expanded(
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
              const SizedBox(height: 8),
              const Expanded(
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
              const SizedBox(height: 8),
              const Expanded(
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
                ? const Color(0x3342D6B5)
                : const Color(0x22000000),
            blurRadius: isRecommended ? 14 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  planName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kTextMain,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isRecommended) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: kAccent,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    'Best',
                    style: TextStyle(
                      color: kBackground,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                price,
                style: TextStyle(
                  color: isRecommended ? kAccent : kTextMain,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                period,
                style: const TextStyle(color: kTextSec, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(height: 1, color: kBorder),
          const SizedBox(height: 6),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: features
                  .map((f) => _FeatureRow(feature: f))
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isRecommended ? kAccent : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: isRecommended
                    ? null
                    : Border.all(color: kBorder, width: 1),
              ),
              child: Center(
                child: Text(
                  buttonLabel,
                  style: TextStyle(
                    color: isRecommended ? kBackground : kTextSec,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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
  const _FeatureRow({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            feature.available ? '✓' : '–',
            style: TextStyle(
              color: feature.available ? kAccent : kTextMuted,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              feature.label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: feature.available ? kTextSec : kTextMuted,
                fontSize: 11,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
