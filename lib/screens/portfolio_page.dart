import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:clarivo/routes/app_routes.dart';
import 'package:clarivo/services/twelve_data_service.dart';
import 'package:clarivo/services/portfolio_storage.dart';
import 'package:clarivo/widgets/clarivo_nav_bar.dart';
import 'package:clarivo/widgets/clarivo_page_header.dart';
import 'package:clarivo/widgets/clarivo_sparkline_chart.dart';
import 'package:clarivo/theme/app_colors.dart';
import 'package:clarivo/utils/market_hours.dart';

// Allocation slice colours — not tied to profit/loss chart semantics.
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
  int _historyDays = 30;

  // Share counts loaded from SharedPreferences; defaults match PortfolioStorage.
  Map<String, int> _shares = Map<String, int>.from(PortfolioStorage.defaults);
  bool _initStarted = false;

  bool get _hasChartHistory {
    for (final sym in ['AAPL', 'TSLA', 'AMZN']) {
      if (TwelveDataService.closesForSymbol(_history, sym).length < 2) {
        return false;
      }
    }
    return true;
  }

  bool get _hasAnyChartHistory {
    for (final sym in ['AAPL', 'TSLA', 'AMZN']) {
      if (TwelveDataService.closesForSymbol(_history, sym).length >= 2) {
        return true;
      }
    }
    return false;
  }

  bool get _hasPortfolioChart =>
      _portfolioSeries.points.length >= TwelveDataService.minChartPoints;

  bool get _showHistoryLoading => _historyLoading && !_hasPortfolioChart;

  void _applyHistoryQuotes() {
    if (_quotes.isNotEmpty) {
      _enrichQuotesFromHistory();
      return;
    }
    for (final q in TwelveDataService.deriveQuotesFromHistory(
      _history,
      ['AAPL', 'TSLA', 'AMZN'],
    )) {
      _quotes[q.symbol] = q;
    }
    _enrichQuotesFromHistory();
  }

  void _commitMarketUi(VoidCallback apply) {
    apply();
    _refreshChartSeries();
    if (mounted) setState(() {});
  }

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
        TwelveDataService.enrichQuotesFromHistory(_quotes, _history);
    _quotes
      ..clear()
      ..addAll(enriched);
  }

  void _refreshChartSeries() {
    final period = TwelveDataService.chartPeriodLabel(_historyDays);
    _portfolioSeries = TwelveDataService.portfolioChartSeries(
      _history,
      _shares,
      _quotes,
      context: 'Portfolio',
      periodLabel: period,
    );
    _aaplSeries = TwelveDataService.stockChartSeries(
      _history,
      'AAPL',
      _quotes['AAPL'],
      context: 'Portfolio',
      periodLabel: period,
    );
    _tslaSeries = TwelveDataService.stockChartSeries(
      _history,
      'TSLA',
      _quotes['TSLA'],
      context: 'Portfolio',
      periodLabel: period,
    );
    _amznSeries = TwelveDataService.stockChartSeries(
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

  /// Loads saved share quantities first, warms cache, then refreshes in background.
  Future<void> _initAndLoad() async {
    if (_initStarted) return;
    _initStarted = true;
    final saved = await PortfolioStorage.loadShares();
    if (mounted) {
      setState(() => _shares = saved);
    }

    final warm = await TwelveDataService.warmSessionFromPrefs(
      daysBack: _historyDays,
    );
    if (mounted) {
      _commitMarketUi(() {
        if (warm.quotes != null) {
          for (final q in warm.quotes!) {
            _quotes[q.symbol] = q;
          }
          _loading = false;
        }
        if (warm.history != null) {
          _history = warm.history!;
        }
        if (_hasAnyChartHistory || warm.quotes != null) {
          _applyHistoryQuotes();
          _loading = false;
        }
      });
    }

    await _loadQuotes(forceRefresh: false);
  }

  /// Loads saved share quantities from SharedPreferences.
  Future<void> _loadPortfolioShares() async {
    final saved = await PortfolioStorage.loadShares();
    if (!mounted) return;
    setState(() => _shares = saved);
    _refreshChartSeries();
  }

  /// Opens stock detail and refreshes holdings when the user returns.
  Future<void> _openStockDetail(StockQuote quote) async {
    await AppRoutes.openStockDetail(context, quote);
    if (!mounted) return;
    await _loadPortfolioShares();
  }

  Future<void> _loadQuotes({bool forceRefresh = false}) async {
    final hadCachedHistory = _hasAnyChartHistory;

    if (mounted) {
      setState(() {
        _loading = _quotes.isEmpty && !_hasAnyChartHistory;
        _historyLoading = forceRefresh || !_hasPortfolioChart;
      });
    }

    try {
      final data = await TwelveDataService.bootstrapMarketData(
        daysBack: _historyDays,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      final now = DateTime.now();
      _commitMarketUi(() {
        if (data.history.isNotEmpty) _history = data.history;
        for (final q in data.quotes) {
          _quotes[q.symbol] = q;
        }
        _applyHistoryQuotes();
        _historyLoading = false;
        _loading = false;
        if (!data.fromCache && !TwelveDataService.lastFetchFromCache) {
          _updatedStr =
              'Last updated ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        } else if (_updatedStr.isEmpty) {
          _updatedStr = 'Cached data';
        }
      });
      debugPrint(
        '[PortfolioPage] bootstrap quotes=${_quotes.length} '
        'apiCalls=${TwelveDataService.apiRequestCount}',
      );
    } catch (e) {
      debugPrint('[PortfolioPage] bootstrap error: $e');
      if (!hadCachedHistory) {
        final warmed =
            await TwelveDataService.warmHistoryFromPrefs(daysBack: _historyDays);
        if (mounted && warmed != null) {
          _commitMarketUi(() {
            _history = warmed;
            _historyLoading = false;
            _applyHistoryQuotes();
            if (_hasAnyChartHistory) _loading = false;
          });
        } else if (mounted) {
          setState(() {
            _historyLoading = false;
            _loading = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _historyLoading = false;
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadHistory(int days, {bool forceRefresh = false}) async {
    final hadCachedHistory = _hasChartHistory;
    if (mounted) {
      setState(() {
        _historyDays = days;
        _historyLoading = forceRefresh || !hadCachedHistory;
      });
    }
    try {
      final hist = await TwelveDataService.fetchWeeklyHistory(
        ['AAPL', 'TSLA', 'AMZN'],
        daysBack: days,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      _commitMarketUi(() {
        _history = hist;
        _historyLoading = false;
      });
      _enrichQuotesFromHistory();
      debugPrint('[PortfolioPage] _history.length=${_history.length}');
      TwelveDataService.debugLogChartCounts(_history, _shares, _quotes,
          screen: 'Portfolio');
    } catch (e) {
      debugPrint('[PortfolioPage] history error: $e');
      final warmed =
          await TwelveDataService.warmHistoryFromPrefs(daysBack: days);
      if (mounted) {
        _commitMarketUi(() {
          if (warmed != null) _history = warmed;
          _historyLoading = false;
        });
        _enrichQuotesFromHistory();
        TwelveDataService.debugLogChartCounts(_history, _shares, _quotes,
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

  bool get _hasAnyShares => _shares.values.any((n) => n > 0);

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
      appBar: const ClarivoAppBar(title: 'Portfolio'),
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
          child: RefreshIndicator(
            color: kAccent,
            onRefresh: () => _loadQuotes(forceRefresh: true),
            child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                  historyLoading: _showHistoryLoading,
                  chartPoints: _buildChartPoints(),
                  chartMode: _portfolioChartSeries.mode,
                  chartPeriodLabel: _portfolioChartSeries.displayPeriodLabel,
                  investedStr: _hasData ? _fmt(_invested) : '---',
                  updatedStr: _updatedStr.isEmpty ? 'Just now' : _updatedStr,
                  selectedRange: _historyDays <= 14
                      ? '1W'
                      : (_historyDays <= 30 ? '1M' : '2M'),
                  onRangeChanged: (range) {
                    final days = range == '1W' ? 14 : 30;
                    if (days != _historyDays) {
                      _loadHistory(days, forceRefresh: false);
                    }
                  },
                ),
                const SizedBox(height: ClarivoLayout.sectionGap),
                const HoldingsHeader(),
                const SizedBox(height: ClarivoLayout.headingBottom),
                HoldingsPanel(
                  quotes: _quotes,
                  shares: _shares,
                  loading: _loading,
                  historyLoading: _showHistoryLoading,
                  chartPeriodLabel: _portfolioChartSeries.displayPeriodLabel,
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
                  onStockTap: _openStockDetail,
                ),
                if (!_hasAnyShares && _hasData)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'No holdings yet. Open a stock detail page and tap Buy to start your portfolio.',
                      style: TextStyle(color: kTextMuted, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 14),
                SummaryCards(quotes: _quotes, shares: _shares),
                const SizedBox(height: 18),
              ],
            ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Expanded(
          child: Text(
            'Track your investments',
            style: ClarivoPageTitle.subtitleStyle,
          ),
        ),
        ClarivoBellButton(),
      ],
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
        TwelveDataService.portfolioDailyGain(quotes, shares);

    final bool hasData = !loading && quotes.isNotEmpty;
    final String totalStr = hasData ? _fmt(total) : '---';
    final String gainStr = hasData
        ? '${dailyGain >= 0 ? '+' : ''}${_fmt(dailyGain.abs())}'
        : '---';
    final bool dailyGainPositive = !hasData || dailyGain >= 0;
    final trend = ClarivoSparklineChart.trendOf(chartPoints);
    final String gainPctStr = hasData ? trend.formattedPercent : '---';

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Expanded(
                child: Text(
                  'Total Portfolio Value',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: kTextSec,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 8),
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
              if (trend.arrowIcon != null) ...[
                Icon(
                  trend.arrowIcon,
                  size: 17,
                  color: trend.color,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                gainPctStr,
                style: TextStyle(
                  color: trend.color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: TimeTab(text: '1D')),
              Expanded(
                child: TimeTab(
                  text: '1W',
                  active: selectedRange == '1W',
                  enabled: true,
                  onTap: () => onRangeChanged('1W'),
                ),
              ),
              Expanded(
                child: TimeTab(
                  text: '1M',
                  active: selectedRange == '1M',
                  enabled: true,
                  onTap: () => onRangeChanged('1M'),
                ),
              ),
              const Expanded(child: TimeTab(text: '3M')),
              const Expanded(child: TimeTab(text: '1Y')),
              const Expanded(child: TimeTab(text: 'ALL')),
            ],
          ),
          const SizedBox(height: 14),
          ClarivoSparklineChart.main(
            values: chartPoints,
            height: 150,
            loading: historyLoading,
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
                valueColor: dailyGainPositive ? kPositive : kNegative,
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
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        decoration: BoxDecoration(
          color: active ? const Color(0x2242D6B5) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
  const HoldingsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const ClarivoSectionHeading(text: 'Your Holdings');
  }
}

class HoldingsPanel extends StatelessWidget {
  final Map<String, StockQuote> quotes;
  final Map<String, int> shares;
  final bool loading;
  final bool historyLoading;
  final Map<String, List<double>> historicalCloses;
  final Map<String, ChartDataMode> chartModes;
  final String chartPeriodLabel;
  final Future<void> Function(StockQuote)? onStockTap;

  const HoldingsPanel({
    super.key,
    required this.quotes,
    required this.shares,
    required this.loading,
    required this.historyLoading,
    required this.historicalCloses,
    this.chartModes = const {},
    this.chartPeriodLabel = '',
    this.onStockTap,
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
            logoAsset: 'assets/images/logos/apple_logo.png',
            fallback: 'A',
            sparklineCloses: historicalCloses['AAPL'],
            chartMode: chartModes['AAPL'],
            chartPeriodLabel: chartPeriodLabel,
            historyLoading: historyLoading,
            quote: aapl,
            onTap: aapl != null && onStockTap != null
                ? () => onStockTap!(aapl)
                : null,
          ),
          const Divider(height: 1, color: kBorder),
          HoldingRow(
            name: 'Tesla',
            ticker: 'TSLA',
            shares: '${shares['TSLA'] ?? 0} shares',
            value: _holdingValue('TSLA'),
            logoAsset: 'assets/images/logos/tesla_logo.png',
            fallback: 'T',
            sparklineCloses: historicalCloses['TSLA'],
            chartMode: chartModes['TSLA'],
            chartPeriodLabel: chartPeriodLabel,
            historyLoading: historyLoading,
            quote: tsla,
            onTap: tsla != null && onStockTap != null
                ? () => onStockTap!(tsla)
                : null,
          ),
          const Divider(height: 1, color: kBorder),
          HoldingRow(
            name: 'Amazon',
            ticker: 'AMZN',
            shares: '${shares['AMZN'] ?? 0} shares',
            value: _holdingValue('AMZN'),
            logoAsset: 'assets/images/logos/amazon_logo.png',
            fallback: 'a',
            sparklineCloses: historicalCloses['AMZN'],
            chartMode: chartModes['AMZN'],
            chartPeriodLabel: chartPeriodLabel,
            historyLoading: historyLoading,
            quote: amzn,
            onTap: amzn != null && onStockTap != null
                ? () => onStockTap!(amzn)
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
  final String logoAsset;
  final String fallback;
  final List<double>? sparklineCloses;
  final ChartDataMode? chartMode;
  final String chartPeriodLabel;
  final bool historyLoading;
  final StockQuote? quote;
  final VoidCallback? onTap;

  const HoldingRow({
    super.key,
    required this.name,
    required this.ticker,
    required this.shares,
    required this.value,
    required this.logoAsset,
    required this.fallback,
    this.sparklineCloses,
    this.chartMode,
    this.chartPeriodLabel = '',
    this.historyLoading = false,
    this.quote,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final points = sparklineCloses ?? const [];
    final trend = ClarivoSparklineChart.trendOf(points);
    final Color changeColor = trend.color;

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
              values: points,
              height: 46,
              loading: historyLoading,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 96,
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
                    if (trend.arrowIcon != null) ...[
                      Icon(
                        trend.arrowIcon,
                        size: 13,
                        color: changeColor,
                      ),
                      const SizedBox(width: 2),
                    ],
                    Flexible(
                      child: Text(
                        trend.formattedPercent,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: changeColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
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

    final aaplPct = total > 0 ? aaplVal / total : 0.0;
    final tslaPct = total > 0 ? tslaVal / total : 0.0;
    final amznPct = total > 0 ? amznVal / total : 0.0;

    final aaplStr = '${(aaplPct * 100).toStringAsFixed(0)}%';
    final tslaStr = '${(tslaPct * 100).toStringAsFixed(0)}%';
    final amznStr = '${(amznPct * 100).toStringAsFixed(0)}%';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
          SizedBox(
            height: 110,
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
    final tracked = shares.values.where((n) => n > 0).length;
    final Color bestColor =
        bestQ?.isDailyPositive == true ? kPositive : kNegative;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
            value: '${quotes.isEmpty ? '--' : tracked} stocks',
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
            value: 'Twelve Data',
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
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: kTextMuted, fontSize: 11),
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? kTextMain,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
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
