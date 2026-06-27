import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:clarivo/routes/app_routes.dart';
import 'package:clarivo/services/marketstack_service.dart';
import 'package:clarivo/services/portfolio_storage.dart';
import 'package:clarivo/widgets/clarivo_nav_bar.dart';
import 'package:clarivo/widgets/clarivo_page_header.dart';
import 'package:clarivo/widgets/clarivo_sparkline_chart.dart';
import 'package:clarivo/utils/market_hours.dart';

const Color kBackground = Color(0xFF030D1C);
const Color kCard = Color(0xFF071C33);
const Color kAccent = Color(0xFF42D6B5);
const Color kPositive = Color(0xFF42D6B5);
const Color kNegative = Color(0xFFE66A73);
const Color kTextMain = Color(0xFFFFFFFF);
const Color kTextSec = Color(0xFFBCC9D6);
const Color kTextMuted = Color(0xFFAABBC9);
const Color kBorder = Color(0xFF2A3B4F);

// Neutral allocation slice colours — not tied to profit/loss semantics.
const Color kAllocApple = Color(0xFF4A90D9);
const Color kAllocTesla = Color(0xFF9B59B6);
const Color kAllocAmazon = Color(0xFFE67E22);

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  final Map<String, StockQuote> _quotes = {};
  Map<String, List<EodBar>> _history = {};
  bool _loading = true;
  bool _historyLoading = false;
  String _updatedStr = '';
  int _historyDays = 45;

  // Share counts loaded from SharedPreferences; defaults match PortfolioStorage.
  Map<String, int> _shares = Map<String, int>.from(PortfolioStorage.defaults);
  bool _initStarted = false;

  static const ChartSeries _emptyChartSeries = ChartSeries(
    points: [],
    mode: ChartDataMode.unavailable,
    reason: 'not loaded',
  );
  ChartSeries _portfolioSeries = _emptyChartSeries;
  ChartSeries _aaplSeries = _emptyChartSeries;
  ChartSeries _tslaSeries = _emptyChartSeries;
  ChartSeries _amznSeries = _emptyChartSeries;

  void _enrichQuotesFromHistory() {
    final enriched =
        MarketstackService.enrichQuotesFromHistory(_quotes, _history);
    _quotes
      ..clear()
      ..addAll(enriched);
  }

  void _refreshChartSeries() {
    final period = MarketstackService.chartPeriodLabel(_historyDays);
    _portfolioSeries = MarketstackService.portfolioChartSeries(
      _history,
      _shares,
      _quotes,
      context: 'Portfolio',
      periodLabel: period,
    );
    _aaplSeries = MarketstackService.stockChartSeries(
      _history,
      'AAPL',
      _quotes['AAPL'],
      context: 'Portfolio',
      periodLabel: period,
    );
    _tslaSeries = MarketstackService.stockChartSeries(
      _history,
      'TSLA',
      _quotes['TSLA'],
      context: 'Portfolio',
      periodLabel: period,
    );
    _amznSeries = MarketstackService.stockChartSeries(
      _history,
      'AMZN',
      _quotes['AMZN'],
      context: 'Portfolio',
      periodLabel: period,
    );
  }

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  /// Loads saved share quantities first, warms cache, then fetches live prices.
  Future<void> _initAndLoad() async {
    if (_initStarted) return;
    _initStarted = true;
    final saved = await PortfolioStorage.load();
    if (mounted) {
      setState(() => _shares = saved);
      _refreshChartSeries();
    }

    final warmed = await MarketstackService.warmQuotesFromPrefs();
    if (warmed != null && mounted) {
      setState(() {
        for (final q in warmed) {
          _quotes[q.symbol] = q;
        }
        _loading = false;
      });
      _refreshChartSeries();
    }

    final warmedHist =
        await MarketstackService.warmHistoryFromPrefs(daysBack: _historyDays);
    if (warmedHist != null && mounted) {
      setState(() => _history = warmedHist);
      _refreshChartSeries();
    }

    await _loadQuotes();
  }

  /// Opens the Edit Holdings bottom sheet so the user can change share counts.
  void _showEditHoldings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditHoldingsSheet(
        currentShares: _shares,
        onSave: (aapl, tsla, amzn) async {
          final newShares = {'AAPL': aapl, 'TSLA': tsla, 'AMZN': amzn};
          await PortfolioStorage.save(newShares);
          if (!mounted) return;
          setState(() => _shares = newShares);
          _refreshChartSeries();
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _loadQuotes({bool forceRefresh = false}) async {
    if (forceRefresh) MarketstackService.invalidateSessionCache();

    setState(() => _loading = _quotes.isEmpty);

    // Step 1: load latest prices.
    try {
      final list = await MarketstackService.fetchLatest(
        ['AAPL', 'TSLA', 'AMZN'],
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      final now = DateTime.now();
      setState(() {
        for (final q in list) {
          _quotes[q.symbol] = q;
        }
        _loading = false;
        _updatedStr =
            'Last updated ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      });
      _refreshChartSeries();
      debugPrint('[PortfolioPage] _quotes.length=${_quotes.length}');
    } catch (e) {
      debugPrint('[PortfolioPage] loadQuotes error: $e');
      if (mounted) setState(() => _loading = false);
      if (_quotes.isEmpty) return;
    }

    // Step 2: load historical prices for charts — failure is non-fatal.
    await _loadHistory(_historyDays, forceRefresh: forceRefresh);
  }

  Future<void> _loadHistory(int days, {bool forceRefresh = false}) async {
    setState(() => _historyLoading = true);
    try {
      final hist = await MarketstackService.fetchWeeklyHistory(
        ['AAPL', 'TSLA', 'AMZN'],
        daysBack: days,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _history = hist;
        _historyDays = days;
        _historyLoading = false;
      });
      _enrichQuotesFromHistory();
      _refreshChartSeries();
      debugPrint('[PortfolioPage] _history.length=${_history.length}');
      MarketstackService.debugLogChartCounts(_history, _shares, _quotes,
          screen: 'Portfolio');
    } catch (e) {
      debugPrint('[PortfolioPage] history error: $e');
      final warmed =
          await MarketstackService.warmHistoryFromPrefs(daysBack: days);
      if (mounted) {
        setState(() {
          if (warmed != null) _history = warmed;
          _historyLoading = false;
        });
        _enrichQuotesFromHistory();
        _refreshChartSeries();
        MarketstackService.debugLogChartCounts(_history, _shares, _quotes,
            screen: 'Portfolio');
      }
    }
  }

  static String _fmt(double v) {
    final str = v.toStringAsFixed(2);
    final parts = str.split('.');
    final buf = StringBuffer();
    final digits = parts[0];
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    return '\$${buf.toString()}.${parts[1]}';
  }

  bool get _hasData => !_loading && _quotes.isNotEmpty;

  double get _invested {
    double inv = 0;
    for (final e in _shares.entries) {
      final q = _quotes[e.key];
      if (q != null) inv += q.open * e.value;
    }
    return inv;
  }

  ChartSeries get _portfolioChartSeries => _portfolioSeries;

  ChartSeries _chartSeriesFor(String symbol) => switch (symbol.toUpperCase()) {
        'AAPL' => _aaplSeries,
        'TSLA' => _tslaSeries,
        'AMZN' => _amznSeries,
        _ => _emptyChartSeries,
      };

  List<double> _buildChartPoints() => _portfolioSeries.points;

  List<double> _chartPointsFor(String symbol) => _chartSeriesFor(symbol).points;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 0,
      ),
      bottomNavigationBar: ClarivoBotNavBar(
        selectedIndex: 1,
        onTap: (i) {
          if (i == 0) AppRoutes.openHome(context);
          if (i == 2) AppRoutes.openNews(context);
          if (i == 3) AppRoutes.openProfile(context);
        },
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
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, ClarivoLayout.pageTop, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PortfolioHeader(),
                const SizedBox(height: ClarivoLayout.afterHeader),
                PortfolioValueCard(
                  quotes: _quotes,
                  shares: _shares,
                  loading: _loading,
                  historyLoading: _historyLoading,
                  chartPoints: _buildChartPoints(),
                  chartMode: _portfolioChartSeries.mode,
                  chartPeriodLabel: _portfolioChartSeries.displayPeriodLabel,
                  investedStr: _hasData ? _fmt(_invested) : '---',
                  updatedStr: _updatedStr.isEmpty ? 'Just now' : _updatedStr,
                  selectedRange: _historyDays <= 14 ? '1W' : '1M',
                  onRangeChanged: (range) {
                    final days = range == '1W' ? 14 : 30;
                    if (days != _historyDays) {
                      _loadHistory(days, forceRefresh: true);
                    }
                  },
                ),
                const SizedBox(height: ClarivoLayout.sectionGap),
                HoldingsHeader(onEdit: _showEditHoldings),
                const SizedBox(height: ClarivoLayout.headingBottom),
                HoldingsPanel(
                  quotes: _quotes,
                  shares: _shares,
                  loading: _loading,
                  historyLoading: _historyLoading,
                  historicalCloses: _hasData
                      ? {
                          'AAPL': _chartPointsFor('AAPL'),
                          'TSLA': _chartPointsFor('TSLA'),
                          'AMZN': _chartPointsFor('AMZN'),
                        }
                      : const {},
                  chartModes: _hasData
                      ? {
                          'AAPL': _chartSeriesFor('AAPL').mode,
                          'TSLA': _chartSeriesFor('TSLA').mode,
                          'AMZN': _chartSeriesFor('AMZN').mode,
                        }
                      : const {},
                ),
                const SizedBox(height: 14),
                SummaryCards(quotes: _quotes, shares: _shares),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PortfolioHeader extends StatelessWidget {
  const PortfolioHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return ClarivoPageHeader(
      title: 'Portfolio',
      subtitle: 'Track your investments',
      trailing: const ClarivoBellButton(),
    );
  }
}

class PortfolioValueCard extends StatelessWidget {
  final Map<String, StockQuote> quotes;
  final Map<String, int> shares;
  final bool loading;
  final bool historyLoading;
  final List<double> chartPoints;
  final ChartDataMode? chartMode;
  final String chartPeriodLabel;
  final String investedStr;
  final String updatedStr;
  final String selectedRange;
  final void Function(String) onRangeChanged;

  const PortfolioValueCard({
    super.key,
    required this.quotes,
    required this.shares,
    required this.loading,
    required this.historyLoading,
    required this.chartPoints,
    this.chartMode,
    this.chartPeriodLabel = '',
    required this.investedStr,
    required this.updatedStr,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  static String _fmt(double v) {
    final str = v.toStringAsFixed(2);
    final parts = str.split('.');
    final buf = StringBuffer();
    final digits = parts[0];
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    return '\$${buf.toString()}.${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    double total = 0;
    for (final entry in shares.entries) {
      final q = quotes[entry.key];
      if (q != null) total += q.close * entry.value;
    }

    final dailyGain =
        MarketstackService.portfolioDailyGain(quotes, shares);
    final prevTotal =
        MarketstackService.portfolioPreviousValue(quotes, shares);

    final bool hasData = !loading && quotes.isNotEmpty;
    final String totalStr = hasData ? _fmt(total) : '---';
    final String gainStr = hasData
        ? '${dailyGain >= 0 ? '+' : ''}${_fmt(dailyGain.abs())}'
        : '---';
    final bool gainPositive = !hasData || dailyGain >= 0;
    final double gainPct =
        (hasData && prevTotal > 0) ? (dailyGain / prevTotal) * 100 : 0;
    final String gainPctStr = hasData
        ? '${gainPositive ? '+' : ''}${gainPct.toStringAsFixed(1)}% daily'
        : '---';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0C2148),
            Color(0xFF0C2148),
            Color(0xFF1E4C8F),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Portfolio Value',
                style: TextStyle(
                  color: kTextSec,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              MarketStatusPill(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            totalStr,
            style: const TextStyle(
              color: kTextMain,
              fontSize: 38,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                gainPositive
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 17,
                color: gainPositive ? kPositive : kNegative,
              ),
              const SizedBox(width: 4),
              Text(
                gainPctStr,
                style: TextStyle(
                  color: gainPositive ? kPositive : kNegative,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'today',
                style: TextStyle(color: kTextMuted, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const TimeTab(text: '1D'),
              TimeTab(
                text: '1W',
                active: selectedRange == '1W',
                enabled: true,
                onTap: () => onRangeChanged('1W'),
              ),
              TimeTab(
                text: '1M',
                active: selectedRange == '1M',
                enabled: true,
                onTap: () => onRangeChanged('1M'),
              ),
              const TimeTab(text: '3M'),
              const TimeTab(text: '1Y'),
              const TimeTab(text: 'ALL'),
            ],
          ),
          const SizedBox(height: 14),
          ClarivoSparklineChart.main(
            values: chartPoints,
            height: 150,
            loading: historyLoading,
            periodLabel:
                chartPeriodLabel.isNotEmpty ? chartPeriodLabel : null,
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: kBorder),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CardStatItem(label: 'Invested', value: investedStr),
              CardStatItem(
                label: 'Daily Gain',
                value: gainStr,
                valueColor: gainPositive ? kPositive : kNegative,
              ),
              CardStatItem(label: 'Updated', value: updatedStr),
            ],
          ),
        ],
      ),
    );
  }
}

class MarketStatusPill extends StatelessWidget {
  const MarketStatusPill({super.key});

  @override
  Widget build(BuildContext context) {
    final label = MarketHours.statusLabel();
    final dotColor = MarketHours.statusDotColor();
    final textColor = MarketHours.statusTextColor();
    final open = MarketHours.isOpenNow();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: open ? const Color(0x1F42D6B5) : const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: open ? const Color(0x4042D6B5) : kBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class TimeTab extends StatelessWidget {
  final String text;
  final bool active;
  final bool enabled;
  final VoidCallback? onTap;

  const TimeTab({
    super.key,
    required this.text,
    this.active = false,
    this.enabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (enabled && onTap != null) ? onTap : null,
      child: Container(
        width: 48,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: active ? const Color(0x2242D6B5) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active
                ? kAccent
                : (enabled ? kTextSec : kTextSec.withAlpha(70)),
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class CardStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const CardStatItem({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 94,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: kTextMuted, fontSize: 13)),
          const SizedBox(height: 5),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: valueColor ?? kTextMain,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class HoldingsHeader extends StatelessWidget {
  final VoidCallback? onEdit;
  const HoldingsHeader({super.key, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return ClarivoSectionHeading(
      text: 'Your Holdings',
      trailing: GestureDetector(
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: kAccent.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kAccent.withAlpha(80)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_outlined, color: kAccent, size: 14),
              SizedBox(width: 4),
              Text(
                'Edit',
                style: TextStyle(
                  color: kAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HoldingsPanel extends StatelessWidget {
  final Map<String, StockQuote> quotes;
  final Map<String, int> shares;
  final bool loading;
  final bool historyLoading;
  final Map<String, List<double>> historicalCloses;
  final Map<String, ChartDataMode> chartModes;

  const HoldingsPanel({
    super.key,
    required this.quotes,
    required this.shares,
    required this.loading,
    required this.historyLoading,
    required this.historicalCloses,
    this.chartModes = const {},
  });

  String _holdingValue(String symbol) {
    final q = quotes[symbol];
    final n = shares[symbol] ?? 0;
    if (q == null) return '---';
    final v = q.close * n;
    return '\$${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final aapl = quotes['AAPL'];
    final tsla = quotes['TSLA'];
    final amzn = quotes['AMZN'];

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0D1F2E),
            Color(0xFF0C2148),
            Color(0xFF142F69),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          HoldingRow(
            name: 'Apple Inc.',
            ticker: 'AAPL',
            shares: '${shares['AAPL'] ?? 0} shares',
            value: _holdingValue('AAPL'),
            change: aapl?.changeStr ?? '---',
            isPositive: aapl?.isDailyPositive ?? true,
            logoAsset: 'assets/images/logos/apple_logo.png',
            fallback: 'A',
            sparklineCloses: historicalCloses['AAPL'],
            chartMode: chartModes['AAPL'],
            historyLoading: historyLoading,
            quote: aapl,
            onTap: aapl != null
                ? () => AppRoutes.openStockDetail(context, aapl)
                : null,
          ),
          const Divider(height: 1, color: kBorder),
          HoldingRow(
            name: 'Tesla',
            ticker: 'TSLA',
            shares: '${shares['TSLA'] ?? 0} shares',
            value: _holdingValue('TSLA'),
            change: tsla?.changeStr ?? '---',
            isPositive: tsla?.isDailyPositive ?? true,
            logoAsset: 'assets/images/logos/tesla_logo.png',
            fallback: 'T',
            sparklineCloses: historicalCloses['TSLA'],
            chartMode: chartModes['TSLA'],
            historyLoading: historyLoading,
            quote: tsla,
            onTap: tsla != null
                ? () => AppRoutes.openStockDetail(context, tsla)
                : null,
          ),
          const Divider(height: 1, color: kBorder),
          HoldingRow(
            name: 'Amazon',
            ticker: 'AMZN',
            shares: '${shares['AMZN'] ?? 0} shares',
            value: _holdingValue('AMZN'),
            change: amzn?.changeStr ?? '---',
            isPositive: amzn?.isDailyPositive ?? true,
            logoAsset: 'assets/images/logos/amazon_logo.png',
            fallback: 'a',
            sparklineCloses: historicalCloses['AMZN'],
            chartMode: chartModes['AMZN'],
            historyLoading: historyLoading,
            quote: amzn,
            onTap: amzn != null
                ? () => AppRoutes.openStockDetail(context, amzn)
                : null,
          ),
        ],
      ),
    );
  }
}

class HoldingRow extends StatelessWidget {
  final String name;
  final String ticker;
  final String shares;
  final String value;
  final String change;
  final bool isPositive;
  final String logoAsset;
  final String fallback;
  final List<double>? sparklineCloses;
  final ChartDataMode? chartMode;
  final bool historyLoading;
  final StockQuote? quote;
  final VoidCallback? onTap;

  const HoldingRow({
    super.key,
    required this.name,
    required this.ticker,
    required this.shares,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.logoAsset,
    required this.fallback,
    this.sparklineCloses,
    this.chartMode,
    this.historyLoading = false,
    this.quote,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color changeColor = isPositive ? kPositive : kNegative;

    return InkWell(
      onTap: onTap,
      splashColor: kAccent.withAlpha(20),
      highlightColor: kAccent.withAlpha(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            StockLogo(asset: logoAsset, fallback: fallback),
          const SizedBox(width: 12),
          SizedBox(
            width: 92,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kTextMain,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(ticker,
                    style:
                        const TextStyle(color: kTextMuted, fontSize: 13)),
                Text(shares,
                    style:
                        const TextStyle(color: kTextMuted, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: ClarivoSparklineChart.mini(
              values: sparklineCloses ?? const [],
              height: 46,
              loading: historyLoading,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 88,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: kTextMain,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      isPositive
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 13,
                      color: changeColor,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      change,
                      style: TextStyle(
                        color: changeColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class StockLogo extends StatelessWidget {
  final String asset;
  final String fallback;

  const StockLogo({
    super.key,
    required this.asset,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF111A25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Text(
                fallback,
                style: const TextStyle(
                  color: kTextMain,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class SummaryCards extends StatelessWidget {
  final Map<String, StockQuote> quotes;
  final Map<String, int> shares;

  const SummaryCards({
    super.key,
    required this.quotes,
    required this.shares,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: AllocationCard(quotes: quotes, shares: shares)),
        const SizedBox(width: 10),
        Expanded(child: PortfolioSummaryCard(quotes: quotes, shares: shares)),
      ],
    );
  }
}

class AllocationCard extends StatelessWidget {
  final Map<String, StockQuote> quotes;
  final Map<String, int> shares;

  const AllocationCard({
    super.key,
    required this.quotes,
    required this.shares,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate allocation from real API close prices × share count.
    final aaplVal =
        (quotes['AAPL']?.close ?? 0) * (shares['AAPL'] ?? 0).toDouble();
    final tslaVal =
        (quotes['TSLA']?.close ?? 0) * (shares['TSLA'] ?? 0).toDouble();
    final amznVal =
        (quotes['AMZN']?.close ?? 0) * (shares['AMZN'] ?? 0).toDouble();
    final total = aaplVal + tslaVal + amznVal;

    // Fall back to equal split when data is not yet loaded.
    final aaplPct = total > 0 ? aaplVal / total : 0.333;
    final tslaPct = total > 0 ? tslaVal / total : 0.333;
    final amznPct = total > 0 ? amznVal / total : 0.334;

    final aaplStr = '${(aaplPct * 100).toStringAsFixed(0)}%';
    final tslaStr = '${(tslaPct * 100).toStringAsFixed(0)}%';
    final amznStr = '${(amznPct * 100).toStringAsFixed(0)}%';

    return Container(
      height: 165,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Portfolio Allocation',
            style: TextStyle(
              color: kTextMain,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: CustomPaint(
                    painter: DonutPainter(
                      aaplPct: aaplPct,
                      tslaPct: tslaPct,
                      amznPct: amznPct,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: AllocationLegend(
                    aaplStr: aaplStr,
                    tslaStr: tslaStr,
                    amznStr: amznStr,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AllocationLegend extends StatelessWidget {
  final String aaplStr;
  final String tslaStr;
  final String amznStr;

  const AllocationLegend({
    super.key,
    required this.aaplStr,
    required this.tslaStr,
    required this.amznStr,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LegendRow(color: kAllocApple, label: 'Apple', percent: aaplStr),
        const SizedBox(height: 12),
        LegendRow(color: kAllocTesla, label: 'Tesla', percent: tslaStr),
        const SizedBox(height: 12),
        LegendRow(color: kAllocAmazon, label: 'Amazon', percent: amznStr),
      ],
    );
  }
}

class LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String percent;

  const LegendRow({
    super.key,
    required this.color,
    required this.label,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: kTextSec, fontSize: 12),
          ),
        ),
        Text(
          percent,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// RecentActivityCard, ActivityRow, ActivityDivider removed.
// Replaced by PortfolioSummaryCard which shows calculated stats from live API data.

// Donut chart painter — accepts dynamic allocation values calculated from
// real API prices so the chart always reflects live portfolio data.
class DonutPainter extends CustomPainter {
  final double aaplPct;
  final double tslaPct;
  final double amznPct;

  const DonutPainter({
    this.aaplPct = 0.333,
    this.tslaPct = 0.333,
    this.amznPct = 0.334,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.50, size.height * 0.50);
    final radius = size.shortestSide * 0.30;
    const strokeWidth = 15.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paints = [
      Paint()
        ..color = kAllocApple
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
      Paint()
        ..color = kAllocTesla
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
      Paint()
        ..color = kAllocAmazon
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    ];

    // Order: Apple, Tesla, Amazon (matches legend)
    double start = -math.pi / 2;
    final values = [aaplPct, tslaPct, amznPct];
    for (int i = 0; i < values.length; i++) {
      final sweep = values[i] * 2 * math.pi;
      canvas.drawArc(rect, start, sweep, false, paints[i]);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant DonutPainter old) =>
      old.aaplPct != aaplPct ||
      old.tslaPct != tslaPct ||
      old.amznPct != amznPct;
}

// ── Portfolio Summary card (replaces fake Recent Activity) ────────────────────
// Shows calculated stats from live API data: no fake transactions.
class PortfolioSummaryCard extends StatelessWidget {
  final Map<String, StockQuote> quotes;
  final Map<String, int> shares;

  const PortfolioSummaryCard({
    super.key,
    required this.quotes,
    required this.shares,
  });

  String _largestHolding() {
    String best = '--';
    double bestVal = 0;
    quotes.forEach((sym, q) {
      final val = q.close * (shares[sym] ?? 0);
      if (val > bestVal) {
        bestVal = val;
        best = sym;
      }
    });
    return best;
  }

  String _bestPerformer() {
    String best = '--';
    double bestPct = double.negativeInfinity;
    quotes.forEach((sym, q) {
      if (q.changePercent > bestPct) {
        bestPct = q.changePercent;
        best = sym;
      }
    });
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final largest = _largestHolding();
    final best = _bestPerformer();
    final bestQ = quotes[best];
    final Color bestColor =
        bestQ?.isPositive == true ? kPositive : kNegative;

    return Container(
      height: 165,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Holdings Summary',
            style: TextStyle(
              color: kTextMain,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Tracked',
            value: '${quotes.isEmpty ? '--' : shares.length} stocks',
          ),
          const SizedBox(height: 6),
          _SummaryRow(
            label: 'Largest',
            value: largest,
          ),
          const SizedBox(height: 6),
          _SummaryRow(
            label: 'Best Today',
            value: bestQ != null ? '$best ${bestQ.changeStr}' : '--',
            valueColor: bestQ != null ? bestColor : null,
          ),
          const SizedBox(height: 6),
          _SummaryRow(
            label: 'Data source',
            value: 'Marketstack',
            valueColor: kTextMuted,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: kTextMuted, fontSize: 11),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? kTextMain,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class PortfolioBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onTap;

  const PortfolioBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A1D3D),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(top: BorderSide(color: kBorder, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              PortfolioNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                index: 0,
                selectedIndex: selectedIndex,
                onTap: onTap,
              ),
              PortfolioNavItem(
                icon: Icons.trending_up_rounded,
                activeIcon: Icons.trending_up_rounded,
                label: 'Portfolio',
                index: 1,
                selectedIndex: selectedIndex,
                onTap: onTap,
              ),
              PortfolioNavItem(
                icon: Icons.article_outlined,
                activeIcon: Icons.article,
                label: 'News',
                index: 2,
                selectedIndex: selectedIndex,
                onTap: onTap,
              ),
              PortfolioNavItem(
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

class PortfolioNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int selectedIndex;
  final void Function(int) onTap;

  const PortfolioNavItem({
    super.key,
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
    final Color itemColor = isSelected ? kAccent : const Color(0xFF8A9BAD);

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
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Edit Holdings bottom sheet ────────────────────────────────────────────────

/// Bottom sheet that lets the user change share counts for each holding.
/// On save the new values are persisted via [PortfolioStorage] (SharedPreferences).
class _EditHoldingsSheet extends StatefulWidget {
  final Map<String, int> currentShares;
  final Future<void> Function(int aapl, int tsla, int amzn) onSave;

  const _EditHoldingsSheet({
    required this.currentShares,
    required this.onSave,
  });

  @override
  State<_EditHoldingsSheet> createState() => _EditHoldingsSheetState();
}

class _EditHoldingsSheetState extends State<_EditHoldingsSheet> {
  late final TextEditingController _aaplCtrl;
  late final TextEditingController _tslaCtrl;
  late final TextEditingController _amznCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _aaplCtrl =
        TextEditingController(text: widget.currentShares['AAPL'].toString());
    _tslaCtrl =
        TextEditingController(text: widget.currentShares['TSLA'].toString());
    _amznCtrl =
        TextEditingController(text: widget.currentShares['AMZN'].toString());
  }

  @override
  void dispose() {
    _aaplCtrl.dispose();
    _tslaCtrl.dispose();
    _amznCtrl.dispose();
    super.dispose();
  }

  int _parseShares(TextEditingController ctrl) {
    final v = int.tryParse(ctrl.text.trim()) ?? 0;
    return v < 0 ? 0 : v;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Push bottom sheet up when keyboard appears.
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Edit Holdings',
              style: TextStyle(
                color: kTextMain,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Share counts are saved on your device.',
              style: TextStyle(color: kTextMuted, fontSize: 12),
            ),
            const SizedBox(height: 20),
            _ShareField(
              label: 'Apple (AAPL)',
              controller: _aaplCtrl,
              logo: 'assets/images/logos/apple_logo.png',
            ),
            const SizedBox(height: 12),
            _ShareField(
              label: 'Tesla (TSLA)',
              controller: _tslaCtrl,
              logo: 'assets/images/logos/tesla_logo.png',
            ),
            const SizedBox(height: 12),
            _ShareField(
              label: 'Amazon (AMZN)',
              controller: _amznCtrl,
              logo: 'assets/images/logos/amazon_logo.png',
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorder),
                      ),
                      child: const Center(
                        child: Text(
                          'Cancel',
                          style:
                              TextStyle(color: kTextMuted, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _saving
                        ? null
                        : () async {
                            setState(() => _saving = true);
                            await widget.onSave(
                              _parseShares(_aaplCtrl),
                              _parseShares(_tslaCtrl),
                              _parseShares(_amznCtrl),
                            );
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: kAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: _saving
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  color: kBackground,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save',
                                style: TextStyle(
                                  color: kBackground,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A single row inside [_EditHoldingsSheet] showing the stock logo,
/// its name, and a number text field for entering share count.
class _ShareField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String logo;

  const _ShareField({
    required this.label,
    required this.controller,
    required this.logo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Stock logo
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF111A25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kBorder),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.asset(
              logo,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Label
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: kTextMain, fontSize: 14),
          ),
        ),
        // Number input
        SizedBox(
          width: 72,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(color: kTextMain, fontSize: 14),
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              filled: true,
              fillColor: kBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: kAccent),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'shares',
          style: TextStyle(color: kTextMuted, fontSize: 12),
        ),
      ],
    );
  }
}
