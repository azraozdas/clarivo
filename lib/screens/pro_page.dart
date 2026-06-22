import 'package:flutter/material.dart';

// ─── Pro Page Colors ──────────────────────────────────────────────────────────
const Color _kBg       = Color(0xFF030D1C);
const Color _kAccent   = Color(0xFF42D6B5);
const Color _kBorder   = Color(0xFF2A3B4F);
const Color _kTextMain = Color(0xFFFFFFFF);
const Color _kTextSec  = Color(0xFFBCC9D6);
const Color _kMuted    = Color(0xFF5A6A7A);

// ─── ProPage ──────────────────────────────────────────────────────────────────
// Pricing/plans page — opened from the Profile page Upgrade button.
// Cards are compact so users can scan all 3 plans with minimal scrolling.
class ProPage extends StatelessWidget {
  const ProPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF071C33),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _kTextMain,
            size: 20,
          ),
        ),
        title: const Text(
          'Clarivo Plans',
          style: TextStyle(
            color: _kTextMain,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page heading ────────────────────────────────────────────────
            const Text(
              'Choose the plan that fits\nyour investing journey.',
              style: TextStyle(
                color: _kTextMain,
                fontSize: 19,
                fontWeight: FontWeight.bold,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Start simple, upgrade when you need deeper insights.',
              style: TextStyle(
                color: _kTextSec,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // ── Free ────────────────────────────────────────────────────────
            const _PlanCard(
              planName: 'Free',
              price: '€0',
              period: '/ month',
              isRecommended: false,
              buttonLabel: 'Start Free',
              features: [
                _Feature('Basic market overview',        available: true),
                _Feature('Limited stock snapshot',       available: true),
                _Feature('Standard news access',         available: true),
                _Feature('Portfolio analytics',          available: false),
                _Feature('Priority market alerts',       available: false),
                _Feature('Ad-free experience',           available: false),
              ],
            ),
            const SizedBox(height: 12),

            // ── Clarivo Pro (recommended) ────────────────────────────────
            const _PlanCard(
              planName: 'Clarivo Pro',
              price: '€4.99',
              period: '/ month',
              isRecommended: true,
              buttonLabel: 'Upgrade to Pro',
              features: [
                _Feature('Advanced market insights',     available: true),
                _Feature('Portfolio analytics',          available: true),
                _Feature('Personalized market summary',  available: true),
                _Feature('Ad-free experience',           available: true),
                _Feature('Priority market alerts',       available: true),
                _Feature('Early access features',        available: false),
              ],
            ),
            const SizedBox(height: 12),

            // ── Clarivo Premium ──────────────────────────────────────────
            const _PlanCard(
              planName: 'Clarivo Premium',
              price: '€9.99',
              period: '/ month',
              isRecommended: false,
              buttonLabel: 'Go Premium',
              features: [
                _Feature('Everything in Pro',            available: true),
                _Feature('Extended analytics',           available: true),
                _Feature('More portfolio tools',         available: true),
                _Feature('Advanced alerts',              available: true),
                _Feature('Early access features',        available: true),
                _Feature('Dedicated support',            available: true),
              ],
            ),
            const SizedBox(height: 20),

            // ── Footer ──────────────────────────────────────────────────
            const Center(
              child: Text(
                'No real payment. UI demonstration only.',
                style: TextStyle(color: _kMuted, fontSize: 11),
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
// Compact pricing card. The recommended Pro card gets an accent border,
// stronger gradient, and an inline "Recommended" badge in the header row.
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
          color: isRecommended ? _kAccent : _kBorder,
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
          // ── Header: plan name + Recommended badge + price ──────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                planName,
                style: const TextStyle(
                  color: _kTextMain,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
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
                    color: _kAccent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Recommended',
                    style: TextStyle(
                      color: Color(0xFF030D1C),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              // Price
              Text(
                price,
                style: TextStyle(
                  color: isRecommended ? _kAccent : _kTextMain,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 3),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  period,
                  style: const TextStyle(
                    color: _kTextSec,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Divider
          Container(height: 1, color: _kBorder),
          const SizedBox(height: 10),
          // ── Feature list ────────────────────────────────────────────────
          ...features.map((f) => _FeatureRow(feature: f)),
          const SizedBox(height: 12),
          // ── Action button ────────────────────────────────────────────────
          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: isRecommended ? _kAccent : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                border: isRecommended
                    ? null
                    : Border.all(color: _kBorder, width: 1),
              ),
              child: Center(
                child: Text(
                  buttonLabel,
                  style: TextStyle(
                    color: isRecommended
                        ? const Color(0xFF030D1C)
                        : _kTextSec,
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
// Compact single line: checkmark/dash + label text.
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
              color: feature.available ? _kAccent : _kMuted,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feature.label,
              style: TextStyle(
                color: feature.available ? _kTextSec : _kMuted,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
