import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:clarivo/routes/app_routes.dart';
import 'package:clarivo/services/location_service.dart';
import 'package:clarivo/services/marketstack_service.dart';
import 'package:clarivo/widgets/clarivo_nav_bar.dart';

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
  final Map<String, StockQuote> _quotes = {};
  Map<String, List<EodBar>> _history = {};
  bool _loading = true;
  bool _hasError = false;
  String _errorMessage = 'Could not load market data.';
  String _errorHint = 'Check your connection and tap Retry.';
  bool _isStaleData = false;
  DateTime? _staleDate;
  String _updatedStr = '';
  String? _marketRegion; // set by Geolocator on startup

  static const Map<String, int> _shares = {'AAPL': 10, 'TSLA': 5, 'AMZN': 8};

  @override
  void initState() {
    super.initState();
    _loadQuotes();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final region = await LocationService.getMarketRegion();
    if (mounted) setState(() => _marketRegion = region);
  }

  Future<void> _loadQuotes() async {
    setState(() {
      _loading = true;
      _hasError = false;
      _isStaleData = false;
    });

    // Step 1: load latest prices — required for all card values.
    try {
      final list =
          await MarketstackService.fetchLatest(['AAPL', 'TSLA', 'AMZN']);
      if (!mounted) return;
      final now = DateTime.now();
      setState(() {
        for (final q in list) {
          _quotes[q.symbol] = q;
        }
        _loading = false;
        _isStaleData = MarketstackService.lastFetchFromCache;
        _staleDate = MarketstackService.lastCacheDate;
        _updatedStr =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      });
    } catch (e) {
      debugPrint('[HomeScreen] loadQuotes error: $e');
      String msg = 'Could not load market data.';
      String hint = 'Check your connection and tap Retry.';
      if (e is MarketstackApiException) {
        if (e.isRateLimit) {
          msg = 'Monthly API limit reached.';
          hint = 'Get a free key at marketstack.com or wait for next billing cycle.';
        } else if (e.isHttpsRestricted) {
          msg = 'HTTPS not supported on free plan.';
          hint = 'Using HTTP — check AndroidManifest cleartext setting.';
        } else {
          msg = 'API error: ${e.code}';
          hint = e.message;
        }
      }
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = msg;
          _errorHint = hint;
        });
      }
      return;
    }

    // Step 2: load historical prices for charts — failure is non-fatal.
    try {
      final hist = await MarketstackService.fetchWeeklyHistory(
          ['AAPL', 'TSLA', 'AMZN']);
      if (!mounted) return;
      setState(() => _history = hist);
    } catch (e) {
      debugPrint('[HomeScreen] history error (non-fatal): $e');
    }
  }

  static String _fmt(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final buf = StringBuffer();
    final digits = parts[0];
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    return '\$${buf.toString()}.${parts[1]}';
  }

  double get _totalBalance {
    double t = 0;
    for (final e in _shares.entries) {
      final q = _quotes[e.key];
      if (q != null) t += q.close * e.value;
    }
    return t;
  }

  double get _dailyGain {
    double g = 0;
    for (final e in _shares.entries) {
      final q = _quotes[e.key];
      if (q != null) g += (q.close - q.open) * e.value;
    }
    return g;
  }

  double get _invested {
    double inv = 0;
    for (final e in _shares.entries) {
      final q = _quotes[e.key];
      if (q != null) inv += q.open * e.value;
    }
    return inv;
  }

  List<double> get _balanceChartPoints {
    if (_history.isNotEmpty) {
      final totals =
          MarketstackService.portfolioTotalsByDate(_history, _shares);
      if (totals.length >= 2) return totals;
    }

    if (_quotes.isEmpty) return [];
    double pOpen = 0, pHigh = 0, pLow = 0, pClose = 0;
    for (final e in _shares.entries) {
      final q = _quotes[e.key];
      if (q != null) {
        pOpen += q.open * e.value;
        pHigh += q.high * e.value;
        pLow += q.low * e.value;
        pClose += q.close * e.value;
      }
    }
    return [pOpen, pHigh, pLow, pClose];
  }

  List<double> _historicalCloses(String symbol) {
    return MarketstackService.closesForSymbol(_history, symbol);
  }

  bool get _hasData => !_loading && _quotes.isNotEmpty;

  void _onNavTap(int index) {
    if (index == 1) {
      AppRoutes.openPortfolio(context);
      return;
    }
    if (index == 2) {
      AppRoutes.openNews(context);
      return;
    }
    if (index == 3) {
      AppRoutes.openProfile(context);
      return;
    }
    setState(() => _selectedIndex = index);
  }

  void _openDetail(String symbol) {
    final q = _quotes[symbol];
    if (q == null) return;
    AppRoutes.openStockDetail(context, q);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030D1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF030D1C),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Clarivo',
          style: TextStyle(
            color: kTextMain,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      bottomNavigationBar: ClarivoBotNavBar(
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const _HeaderSection(),
                if (_marketRegion != null) ...[
                  const SizedBox(height: 6),
                  _MarketContextChip(region: _marketRegion!),
                ],
                if (_isStaleData) ...[
                  const SizedBox(height: 6),
                  _StaleBanner(staleDate: _staleDate),
                ],
                const SizedBox(height: 10),
                if (_loading)
                  const _LoadingBalanceCard()
                else if (_hasError)
                  _ErrorCard(
                    onRetry: _loadQuotes,
                    message: _errorMessage,
                    hint: _errorHint,
                  )
                else
                  _BalanceCard(
                    totalStr: _fmt(_totalBalance),
                    dailyGainStr:
                        '${_dailyGain >= 0 ? '+' : ''}${_fmt(_dailyGain.abs())}',
                    dailyGainPctStr:
                        '${_dailyGain >= 0 ? '+' : ''}${(_totalBalance > 0 ? _dailyGain / _totalBalance * 100 : 0).toStringAsFixed(1)}% today',
                    isPositive: _dailyGain >= 0,
                    investedStr: _fmt(_invested),
                    updatedStr: _updatedStr.isEmpty ? 'Just now' : _updatedStr,
                    chartPoints: _balanceChartPoints,
                  ),
                const SizedBox(height: 8),
                const _MarketSnapshotHeader(),
                const SizedBox(height: 6),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _openDetail('AAPL'),
                          child: _StockCard(
                            name: 'Apple Inc.',
                            ticker: 'AAPL',
                            price: _hasData
                                ? (_quotes['AAPL']?.priceStr ?? '---')
                                : (_loading ? '...' : '---'),
                            change: _quotes['AAPL']?.changeStr ?? '---',
                            isPositive: _quotes['AAPL']?.isPositive ?? true,
                            initial: 'A',
                            iconColor: const Color(0xFF1A1A1A),
                            iconBorder: const Color(0xFF3A3A3A),
                            logoAsset: 'assets/images/logos/apple_logo.png',
                            historicalCloses:
                                _hasData ? _historicalCloses('AAPL') : null,
                            quote: _quotes['AAPL'],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _openDetail('TSLA'),
                          child: _StockCard(
                            name: 'Tesla',
                            ticker: 'TSLA',
                            price: _hasData
                                ? (_quotes['TSLA']?.priceStr ?? '---')
                                : (_loading ? '...' : '---'),
                            change: _quotes['TSLA']?.changeStr ?? '---',
                            isPositive: _quotes['TSLA']?.isPositive ?? true,
                            initial: 'T',
                            iconColor: const Color(0xFF1A1A1A),
                            iconBorder: const Color(0xFF3A3A3A),
                            logoAsset: 'assets/images/logos/tesla_logo.png',
                            historicalCloses:
                                _hasData ? _historicalCloses('TSLA') : null,
                            quote: _quotes['TSLA'],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _openDetail('AMZN'),
                          child: _StockCard(
                            name: 'Amazon',
                            ticker: 'AMZN',
                            price: _hasData
                                ? (_quotes['AMZN']?.priceStr ?? '---')
                                : (_loading ? '...' : '---'),
                            change: _quotes['AMZN']?.changeStr ?? '---',
                            isPositive: _quotes['AMZN']?.isPositive ?? true,
                            initial: 'a',
                            iconColor: const Color(0xFF1A1200),
                            iconBorder: const Color(0xFF3A2800),
                            logoAsset: 'assets/images/logos/amazon_logo.png',
                            logoImageScale: 0.87,
                            historicalCloses:
                                _hasData ? _historicalCloses('AMZN') : null,
                            quote: _quotes['AMZN'],
                          ),
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

/// Small chip shown below the greeting when Geolocator resolves a region.
/// Satisfies the PDF Geolocator / location requirement at student level.
class _MarketContextChip extends StatelessWidget {
  final String region;
  const _MarketContextChip({required this.region});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: kAccent.withAlpha(22),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kAccent.withAlpha(70)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: kAccent,
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                '$region — US market demo',
                style: const TextStyle(
                  color: kAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
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
          children: const [
            Text(
              'Hello, Azra',
              style: TextStyle(
                color: kTextMain,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 3),
            Text(
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

class _LoadingBalanceCard extends StatelessWidget {
  const _LoadingBalanceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 40),
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(kAccent),
            ),
            SizedBox(height: 14),
            Text(
              'Loading market data...',
              style: TextStyle(
                color: kTextMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small orange banner shown when data is served from persistent cache
/// (e.g. API rate limit was reached but a previous response was saved).
class _StaleBanner extends StatelessWidget {
  final DateTime? staleDate;
  const _StaleBanner({this.staleDate});

  @override
  Widget build(BuildContext context) {
    final dateStr = staleDate != null
        ? '${staleDate!.day}/${staleDate!.month} '
            '${staleDate!.hour.toString().padLeft(2, '0')}:'
            '${staleDate!.minute.toString().padLeft(2, '0')}'
        : 'a previous session';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1A00),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF6B4400)),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_rounded,
              color: Color(0xFFFFB347), size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Showing saved data from $dateStr — API monthly limit reached.',
              style: const TextStyle(
                color: Color(0xFFFFB347),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final VoidCallback onRetry;
  final String message;
  final String hint;

  const _ErrorCard({
    required this.onRetry,
    this.message = 'Could not load market data.',
    this.hint = 'Check your connection and tap Retry.',
  });

  @override
  Widget build(BuildContext context) {
    final bool isRateLimit = message.contains('limit') ||
        message.contains('API error') ||
        message.contains('HTTPS');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRateLimit
                ? Icons.cloud_off_rounded
                : Icons.wifi_off_rounded,
            color: kNegative,
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kTextMain,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kTextMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: kAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: kBackground,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String totalStr;
  final String dailyGainStr;
  final String dailyGainPctStr;
  final bool isPositive;
  final String investedStr;
  final String updatedStr;
  final List<double> chartPoints;

  const _BalanceCard({
    required this.totalStr,
    required this.dailyGainStr,
    required this.dailyGainPctStr,
    required this.isPositive,
    required this.investedStr,
    required this.updatedStr,
    required this.chartPoints,
  });

  @override
  Widget build(BuildContext context) {
    final Color changeColor = isPositive ? kPositive : kNegative;
    final IconData changeIcon =
        isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Color(0x331E4C8F),
            blurRadius: 28,
            offset: Offset(0, 4),
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
          const SizedBox(height: 14),
          Text(
            totalStr,
            style: const TextStyle(
              color: kTextMain,
              fontSize: 40,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(changeIcon, size: 15, color: changeColor),
              const SizedBox(width: 4),
              Text(
                dailyGainPctStr,
                style: TextStyle(
                  color: changeColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 62,
            width: double.infinity,
            child: chartPoints.length >= 2
                ? CustomPaint(
                    painter: _BalanceChartPainter(
                      dataPoints: chartPoints,
                      isPositive: isPositive,
                    ),
                  )
                : const Center(
                    child: Text(
                      'No chart data',
                      style: TextStyle(color: kTextMuted, fontSize: 11),
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: kBorder),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CardStatItem(label: 'Invested', value: investedStr),
              _CardStatItem(
                label: 'Daily Gain',
                value: dailyGainStr,
                valueColor: changeColor,
              ),
              _CardStatItem(label: 'Updated', value: updatedStr),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final bool isPositive;

  const _BalanceChartPainter({
    required this.dataPoints,
    required this.isPositive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.length < 2) return;

    final color = isPositive ? kPositive : kNegative;
    final minVal = dataPoints.reduce(math.min);
    final maxVal = dataPoints.reduce(math.max);
    final range = maxVal - minVal;
    final n = dataPoints.length;

    final points = List.generate(n, (i) {
      final x = size.width * i / (n - 1);
      final norm = range > 0 ? 1.0 - (dataPoints[i] - minVal) / range : 0.5;
      final y = size.height * (0.05 + norm * 0.88);
      return Offset(x, y);
    });

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      path.quadraticBezierTo(p1.dx, p1.dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withAlpha(60),
          color.withAlpha(8),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
    canvas.drawCircle(points.last, 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _BalanceChartPainter old) =>
      old.dataPoints != dataPoints || old.isPositive != isPositive;
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
        color: const Color(0x1F42D6B5),
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
  final double logoImageScale;
  final List<double>? historicalCloses;
  final StockQuote? quote;

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
    this.logoImageScale = 1.0,
    this.historicalCloses,
    this.quote,
  });

  static const double _logoSize = 48;
  static const double _chartHeight = 51;

  @override
  Widget build(BuildContext context) {
    final Color changeColor = isPositive ? kPositive : kNegative;
    final IconData changeIcon =
        isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    final bool hasHistory =
        historicalCloses != null && historicalCloses!.length >= 2;
    final double imageSize = _logoSize * logoImageScale;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
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
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: kBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: _logoSize,
            height: _logoSize,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: iconBorder, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Center(
                child: Image.asset(
                  logoAsset,
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Text(
                      initial,
                      style: const TextStyle(
                        color: kTextMain,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          SizedBox(
            width: 97,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kTextMain,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
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
          Expanded(
            child: SizedBox(
              height: _chartHeight,
              child: hasHistory
                  ? CustomPaint(
                      painter: _StockSparklinePainter(
                        closes: historicalCloses!,
                        isPositive: isPositive,
                      ),
                    )
                  : quote != null
                      ? CustomPaint(
                          painter: _DayRangeSparklinePainter(
                            open: quote!.open,
                            high: quote!.high,
                            low: quote!.low,
                            close: quote!.close,
                            isPositive: isPositive,
                          ),
                        )
                      : const SizedBox.shrink(),
            ),
          ),
          const SizedBox(width: 11),
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
              const SizedBox(height: 5),
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

class _StockSparklinePainter extends CustomPainter {
  final List<double> closes;
  final bool isPositive;

  const _StockSparklinePainter({
    required this.closes,
    required this.isPositive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (closes.length < 2) return;

    final color = isPositive ? kPositive : kNegative;
    final minVal = closes.reduce(math.min);
    final maxVal = closes.reduce(math.max);
    final range = maxVal - minVal;
    final n = closes.length;

    final points = List.generate(n, (i) {
      final x = size.width * i / (n - 1);
      final norm = range > 0 ? 1.0 - (closes[i] - minVal) / range : 0.5;
      final y = size.height * (0.05 + norm * 0.88);
      return Offset(x, y);
    });

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      path.quadraticBezierTo(p1.dx, p1.dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withAlpha(55), color.withAlpha(5)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _StockSparklinePainter old) =>
      old.closes != closes || old.isPositive != isPositive;
}

/// Draws a compact 4-point sparkline using open, high, low, close from the
/// latest EOD. This is the honest fallback when multi-day history is not
/// available. Each stock traces its own shape because their OHLC ratios differ.
class _DayRangeSparklinePainter extends CustomPainter {
  final double open;
  final double high;
  final double low;
  final double close;
  final bool isPositive;

  const _DayRangeSparklinePainter({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.isPositive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final color = isPositive ? kPositive : kNegative;
    final values = [open, high, low, close];
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = maxV - minV;

    Offset ptAt(int i) {
      final x = size.width * i / 3;
      final norm = range > 0 ? 1.0 - (values[i] - minV) / range : 0.5;
      return Offset(x, size.height * (0.05 + norm * 0.88));
    }

    final pts = List.generate(4, ptAt);

    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      path.quadraticBezierTo(p1.dx, p1.dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withAlpha(55), color.withAlpha(5)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _DayRangeSparklinePainter old) =>
      old.open != open ||
      old.high != high ||
      old.low != low ||
      old.close != close ||
      old.isPositive != isPositive;
}

// ignore: unused_element
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
