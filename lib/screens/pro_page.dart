import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

// ─── ProPage ──────────────────────────────────────────────────────────────────
// Pricing/plans page — opened from the Profile page Upgrade button.
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose the plan that fits\nyour investing journey.',
              style: TextStyle(
                color: kTextMain,
                fontSize: 19,
                fontWeight: FontWeight.bold,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Start simple, upgrade when you need deeper insights.',
              style: TextStyle(color: kTextSec, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 20),

            const _PlanCard(
              planName: 'Free',
              price: '€0',
              period: '/ month',
              isRecommended: false,
              buttonLabel: 'Start Free',
              features: [
                _Feature('Basic market overview', available: true),
                _Feature('Limited stock snapshot', available: true),
                _Feature('Market news access', available: true),
                _Feature('Portfolio overview', available: false),
                _Feature('Priority market alerts', available: false),
                _Feature('Ad-free experience', available: false),
              ],
            ),
            const SizedBox(height: 12),

            const _PlanCard(
              planName: 'Clarivo Pro',
              price: '€4.99',
              period: '/ month',
              isRecommended: true,
              buttonLabel: 'Upgrade to Pro',
              features: [
                _Feature('Advanced market insights', available: true),
                _Feature('Portfolio overview and insights', available: true),
                _Feature('Personalized market summary', available: true),
                _Feature('Ad-free experience', available: true),
                _Feature('Priority market alerts', available: true),
                _Feature('Early access features', available: false),
              ],
            ),
            const SizedBox(height: 12),

            const _PlanCard(
              planName: 'Clarivo Premium',
              price: '€9.99',
              period: '/ month',
              isRecommended: false,
              buttonLabel: 'Go Premium',
              features: [
                _Feature('Everything in Pro', available: true),
                _Feature('Extended analytics', available: true),
                _Feature('More portfolio tools', available: true),
                _Feature('Advanced alerts', available: true),
                _Feature('Early access features', available: true),
                _Feature('Dedicated support', available: true),
              ],
            ),
            const SizedBox(height: 20),

            const Center(
              child: Text(
                'Plans are for UI demonstration purposes.',
                style: TextStyle(color: kTextMuted, fontSize: 11),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── _Feature data class ──────────────────────────────────────────────────────
class _Feature {
  final String label;
  final bool available;
  const _Feature(this.label, {required this.available});
}

// ─── Plan Card ────────────────────────────────────────────────────────────────
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isRecommended ? kAccent : kBorder,
          width: isRecommended ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isRecommended
                ? const Color(0x3342D6B5)
                : const Color(0x22000000),
            blurRadius: isRecommended ? 18 : 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                planName,
                style: const TextStyle(
                  color: kTextMain,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isRecommended) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kAccent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Recommended',
                    style: TextStyle(
                      color: kBackground,
                      fontSize: 10,
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
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 3),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  period,
                  style: const TextStyle(color: kTextSec, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: kBorder),
          const SizedBox(height: 10),
          ...features.map((f) => _FeatureRow(feature: f)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: isRecommended ? kAccent : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                border: isRecommended
                    ? null
                    : Border.all(color: kBorder, width: 1),
              ),
              child: Center(
                child: Text(
                  buttonLabel,
                  style: TextStyle(
                    color: isRecommended ? kBackground : kTextSec,
                    fontSize: 13,
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

// ─── Feature Row ──────────────────────────────────────────────────────────────
class _FeatureRow extends StatelessWidget {
  final _Feature feature;
  const _FeatureRow({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            feature.available ? '✓' : '–',
            style: TextStyle(
              color: feature.available ? kAccent : kTextMuted,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feature.label,
              style: TextStyle(
                color: feature.available ? kTextSec : kTextMuted,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
