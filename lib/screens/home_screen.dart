import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:clarivo/routes/app_routes.dart';
import 'package:clarivo/services/location_service.dart';
import 'package:clarivo/services/marketstack_service.dart';
import 'package:clarivo/services/portfolio_storage.dart';
import 'package:clarivo/widgets/clarivo_nav_bar.dart';
import 'package:clarivo/widgets/clarivo_page_header.dart';
import 'package:clarivo/widgets/clarivo_sparkline_chart.dart';
import 'package:clarivo/widgets/current_location_chip.dart';
import 'package:clarivo/utils/market_hours.dart';
import 'package:clarivo/utils/visual_chart_trend.dart';

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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final Map<String, StockQuote> _quotes = {};
  Map<String, List<EodBar>> _history = {};
  bool _loading = true;
  bool _historyLoading = false;
  bool _hasError = false;
  String _errorMessage = 'Could not load market data.';
  String _errorHint = 'Check your connection and tap Retry.';
  bool _isStaleData = false;
  DateTime? _staleDate;
  String _updatedStr = '';
  bool _locationLoading = false;
  LocationResolveState _locationState = LocationResolveState.pending;
  UserLocation? _userLocation;
  bool _locationInFlight = false;
  bool _initStarted = false;
  bool _autoPermissionRequested = false;

  // Cached chart series — recomputed when quotes/history change, never in build().
  static const ChartSeries _emptyChartSeries = ChartSeries(
    points: [],
    mode: ChartDataMode.unavailable,
    reason: 'not loaded',
  );
  ChartSeries _balanceSeries = _emptyChartSeries;
  ChartSeries _aaplSeries = _emptyChartSeries;
  ChartSeries _tslaSeries = _emptyChartSeries;
  ChartSeries _amznSeries = _emptyChartSeries;

  // Loaded from SharedPreferences — same source as Portfolio page.
  Map<String, int> _shares = Map<String, int>.from(PortfolioStorage.defaults);
  final int _historyDays = MarketstackService.homeHistoryDays;

  void _enrichQuotesFromHistory() {
    final enriched =
        MarketstackService.enrichQuotesFromHistory(_quotes, _history);
    _quotes
      ..clear()
      ..addAll(enriched);
  }

  void _refreshChartSeries() {
    final period =
        MarketstackService.chartPeriodLabel(_historyDays);
    _balanceSeries = MarketstackService.portfolioChartSeries(
      _history,
      _shares,
      _quotes,
      context: 'Home',
      periodLabel: period,
    );
    _aaplSeries = MarketstackService.stockChartSeries(
      _history,
      'AAPL',
      _quotes['AAPL'],
      context: 'Home',
      periodLabel: period,
    );
    _tslaSeries = MarketstackService.stockChartSeries(
      _history,
      'TSLA',
      _quotes['TSLA'],
      context: 'Home',
      periodLabel: period,
    );
    _amznSeries = MarketstackService.stockChartSeries(
      _history,
      'AMZN',
      _quotes['AMZN'],
      context: 'Home',
      periodLabel: period,
    );
    for (final sym in ['AAPL', 'TSLA', 'AMZN']) {
      MarketstackService.logStockAudit(
        sym,
        _quotes[sym],
        _chartSeriesFor(sym).points,
        chartPeriod: period,
      );
    }
    MarketstackService.logPortfolioAudit(
      _balanceSeries.points,
      chartPeriod: period,
      dailyGain: _dailyGain,
    );
    if (kDebugMode) {
      _logChartPaintProof('Home Total Balance', _balanceSeries.points);
      for (final sym in ['AAPL', 'TSLA', 'AMZN']) {
        _logChartPaintProof('Home $sym', _chartSeriesFor(sym).points);
      }
    }
  }

  void _logChartPaintProof(String name, List<double> points) {
    final t = VisualChartTrend.trendFromVisualValues(points);
    debugPrint(
      '[ChartProof] $name first=${t.firstValue?.toStringAsFixed(2)} '
      'last=${t.lastValue?.toStringAsFixed(2)} '
      'pct=${t.formattedPercent} color=${t.isUp ? "green" : "red"}',
    );
  }

  ChartSeries _chartSeriesFor(String symbol) => switch (symbol.toUpperCase()) {
        'AAPL' => _aaplSeries,
        'TSLA' => _tslaSeries,
        'AMZN' => _amznSeries,
        _ => _emptyChartSeries,
      };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAndLoad();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_locationState != LocationResolveState.success &&
          !_locationInFlight) {
        _loadLocation(requestPermissionIfDenied: false);
      }
      if (_initStarted && !_loading) {
        _loadQuotes(forceRefresh: false);
      }
    }
  }

  /// Loads saved share counts, then warms cache, then fetches live prices.
  /// Location detection starts immediately in parallel — after login/Home load.
  Future<void> _initAndLoad() async {
    if (_initStarted) return;
    _initStarted = true;

    // Location runs in parallel with market data — not blocked by quote fetch.
    _loadLocation(requestPermissionIfDenied: true);

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
        _hasError = false;
        _isStaleData = true;
        _staleDate = MarketstackService.lastCacheDate;
      });
      _refreshChartSeries();
    }

    final warmedHist =
        await MarketstackService.warmHistoryFromPrefs(daysBack: 45);
    if (warmedHist != null && mounted) {
      setState(() => _history = warmedHist);
      _refreshChartSeries();
    }

    await _loadQuotes(forceRefresh: true);
  }

  Future<void> _loadLocation({required bool requestPermissionIfDenied}) async {
    if (!mounted || _locationInFlight) return;
    _locationInFlight = true;
    setState(() => _locationLoading = true);
    try {
      final shouldRequest = requestPermissionIfDenied && !_autoPermissionRequested;
      if (shouldRequest) _autoPermissionRequested = true;

      final result = await LocationService.resolveCurrentLocation(
        requestPermissionIfDenied: shouldRequest,
      );
      if (!mounted) return;
      setState(() {
        _locationState = result.state;
        _userLocation = result.location;
      });
      debugPrint(
        '[HomeScreen] location state=${result.state} '
        'place=${result.location?.formatted ?? "none"}',
      );
    } catch (e, st) {
      debugPrint('[HomeScreen] location error: $e\n$st');
      if (mounted) {
        setState(() => _locationState = LocationResolveState.unavailable);
      }
    } finally {
      _locationInFlight = false;
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  Future<void> _onLocationChipTap() async {
    if (_locationLoading) return;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() => _locationState = LocationResolveState.serviceDisabled);
      }
      await Geolocator.openLocationSettings();
      return;
    }

    var permission = await LocationService.currentPermission();
    debugPrint('[HomeScreen] chip tap permission=$permission');

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() => _locationState = LocationResolveState.deniedForever);
      }
      await Geolocator.openAppSettings();
      return;
    }

    if (permission == LocationPermission.denied) {
      permission = await LocationService.requestPermission();
      debugPrint('[HomeScreen] chip requestPermission result=$permission');
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _locationState = LocationResolveState.deniedForever);
        }
        await Geolocator.openAppSettings();
        return;
      }
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() => _locationState = LocationResolveState.denied);
        }
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 600));
    }

    await _loadLocation(requestPermissionIfDenied: false);
  }

  static const String _webAppUrl = 'https://clarivo.infinityfreeapp.com';

  Future<void> _openWebApp() async {
    final uri = Uri.parse(_webAppUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the web app.')),
      );
    }
  }

  Future<void> _refreshMarketData() async {
    await _loadQuotes(forceRefresh: true);
  }

  Future<void> _loadQuotes({bool forceRefresh = false}) async {
    if (forceRefresh) MarketstackService.invalidateSessionCache();

    setState(() {
      _loading = _quotes.isEmpty;
      _hasError = false;
      _isStaleData = false;
    });

    // Step 1: load latest prices — required for all card values.
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
        _hasError = false;
        _isStaleData = MarketstackService.lastFetchFromCache;
        _staleDate = MarketstackService.lastCacheDate;
        if (!MarketstackService.lastFetchFromCache) {
          _updatedStr =
              'Last updated ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        } else if (_updatedStr.isEmpty) {
          _updatedStr = 'Cached data';
        }
      });
      _refreshChartSeries();
      debugPrint('[HomeScreen] _quotes.length=${_quotes.length} '
          '_hasError=$_hasError');
    } catch (e) {
      debugPrint('[HomeScreen] loadQuotes error: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = _quotes.isEmpty;
          _errorMessage = 'Could not load market data.';
          _errorHint = 'Check your connection and tap Retry.';
        });
        debugPrint('[HomeScreen] after error _quotes.length=${_quotes.length} '
            '_hasError=$_hasError');
      }
      if (_quotes.isEmpty) return;
    }

    // Step 2: load historical closes for charts — failure is non-fatal.
    setState(() => _historyLoading = true);
    try {
      final hist = await MarketstackService.fetchWeeklyHistory(
        ['AAPL', 'TSLA', 'AMZN'],
        daysBack: _historyDays,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _history = hist;
        _historyLoading = false;
      });
      _enrichQuotesFromHistory();
      _refreshChartSeries();
      debugPrint('[HomeScreen] _history.length=${_history.length}');
      MarketstackService.debugLogChartCounts(_history, _shares, _quotes,
          screen: 'Home');
    } catch (e) {
      debugPrint('[HomeScreen] history error: $e');
      final warmed =
          await MarketstackService.warmHistoryFromPrefs(daysBack: _historyDays);
      if (mounted) {
        setState(() {
          if (warmed != null) _history = warmed;
          _historyLoading = false;
        });
        _enrichQuotesFromHistory();
        _refreshChartSeries();
        debugPrint('[HomeScreen] _history.length=${_history.length}');
        MarketstackService.debugLogChartCounts(_history, _shares, _quotes,
            screen: 'Home');
      }
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

  double get _dailyGain =>
      MarketstackService.portfolioDailyGain(_quotes, _shares);

  double get _invested {
    double inv = 0;
    for (final e in _shares.entries) {
      final q = _quotes[e.key];
      if (q != null) inv += q.open * e.value;
    }
    return inv;
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
    final balanceSeries = _balanceSeries;
    final aaplSeries = _hasData ? _aaplSeries : null;
    final tslaSeries = _hasData ? _tslaSeries : null;
    final amznSeries = _hasData ? _amznSeries : null;

    return Scaffold(
      backgroundColor: const Color(0xFF030D1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF030D1C),
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 0,
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
                CurrentLocationChip(
                  loading: _locationLoading,
                  state: _locationState,
                  location: _userLocation,
                  onTap: _onLocationChipTap,
                ),
                const SizedBox(height: 6),
                const _HeaderSection(),
                if (_isStaleData) ...[
                  const SizedBox(height: 6),
                  _StaleBanner(staleDate: _staleDate),
                ],
                const SizedBox(height: ClarivoLayout.sectionGap),
                if (_loading)
                  const _LoadingBalanceCard()
                else if (_hasError)
                  _ErrorCard(
                    onRetry: () => _loadQuotes(forceRefresh: true),
                    message: _errorMessage,
                    hint: _errorHint,
                  )
                else
                  _BalanceCard(
                    totalStr: _fmt(_totalBalance),
                    dailyGainStr:
                        '${_dailyGain >= 0 ? '+' : ''}${_fmt(_dailyGain.abs())}',
                    dailyGainPositive: _dailyGain >= 0,
                    investedStr: _fmt(_invested),
                    updatedStr: _updatedStr.isEmpty ? 'Just now' : _updatedStr,
                    chartPoints: balanceSeries.points,
                    chartMode: balanceSeries.mode,
                    chartPeriodLabel: balanceSeries.displayPeriodLabel,
                    historyLoading: _historyLoading,
                    onRefreshTap: _refreshMarketData,
                  ),
                const SizedBox(height: ClarivoLayout.sectionGap),
                _OpenWebAppLink(onTap: _openWebApp),
                const SizedBox(height: ClarivoLayout.sectionGap),
                const _MarketSnapshotHeader(),
                const SizedBox(height: 6),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _openDetail('AAPL'),
                          child: Align(
                            alignment: Alignment.center,
                            child: _StockCard(
                            name: 'Apple Inc.',
                            ticker: 'AAPL',
                            price: _hasData
                                ? (_quotes['AAPL']?.priceStr ?? '---')
                                : (_loading ? '...' : '---'),
                            initial: 'A',
                            iconColor: const Color(0xFF1A1A1A),
                            iconBorder: const Color(0xFF3A3A3A),
                            logoAsset: 'assets/images/logos/apple_logo.png',
                            chartPoints: aaplSeries?.points,
                            chartMode: aaplSeries?.mode,
                            chartPeriodLabel: aaplSeries?.displayPeriodLabel ?? '',
                            historyLoading: _historyLoading,
                            quote: _quotes['AAPL'],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _openDetail('TSLA'),
                          child: Align(
                            alignment: Alignment.center,
                            child: _StockCard(
                            name: 'Tesla',
                            ticker: 'TSLA',
                            price: _hasData
                                ? (_quotes['TSLA']?.priceStr ?? '---')
                                : (_loading ? '...' : '---'),
                            initial: 'T',
                            iconColor: const Color(0xFF1A1A1A),
                            iconBorder: const Color(0xFF3A3A3A),
                            logoAsset: 'assets/images/logos/tesla_logo.png',
                            chartPoints: tslaSeries?.points,
                            chartMode: tslaSeries?.mode,
                            chartPeriodLabel: tslaSeries?.displayPeriodLabel ?? '',
                            historyLoading: _historyLoading,
                            quote: _quotes['TSLA'],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _openDetail('AMZN'),
                          child: Align(
                            alignment: Alignment.center,
                            child: _StockCard(
                            name: 'Amazon',
                            ticker: 'AMZN',
                            price: _hasData
                                ? (_quotes['AMZN']?.priceStr ?? '---')
                                : (_loading ? '...' : '---'),
                            initial: 'a',
                            iconColor: const Color(0xFF1A1200),
                            iconBorder: const Color(0xFF3A2800),
                            logoAsset: 'assets/images/logos/amazon_logo.png',
                            logoImageScale: 0.87,
                            chartPoints: amznSeries?.points,
                            chartMode: amznSeries?.mode,
                            chartPeriodLabel: amznSeries?.displayPeriodLabel ?? '',
                            historyLoading: _historyLoading,
                            quote: _quotes['AMZN'],
                            ),
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
              style: ClarivoPageTitle.titleStyle,
            ),
            SizedBox(height: 4),
            Text(
              'Track your market today',
              style: ClarivoPageTitle.subtitleStyle,
            ),
          ],
        ),
        const ClarivoBellButton(),
      ],
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
  final bool dailyGainPositive;
  final String investedStr;
  final String updatedStr;
  final List<double> chartPoints;
  final ChartDataMode? chartMode;
  final String chartPeriodLabel;
  final bool historyLoading;
  final VoidCallback? onRefreshTap;

  const _BalanceCard({
    required this.totalStr,
    required this.dailyGainStr,
    required this.dailyGainPositive,
    required this.investedStr,
    required this.updatedStr,
    required this.chartPoints,
    this.chartMode,
    this.chartPeriodLabel = '',
    this.historyLoading = false,
    this.onRefreshTap,
  });

  @override
  Widget build(BuildContext context) {
    final trend = ClarivoSparklineChart.trendOf(chartPoints);
    final Color trendColor = trend.color;
    final String trendText = trend.formattedPercent;
    final Color dailyColor =
        dailyGainPositive ? kPositive : kNegative;

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
              if (trend.arrowIcon != null) ...[
                Icon(trend.arrowIcon, size: 15, color: trendColor),
                const SizedBox(width: 4),
              ],
              Text(
                trendText,
                style: TextStyle(
                  color: trendColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClarivoSparklineChart.main(
            values: chartPoints,
            height: 90,
            loading: historyLoading,
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
                valueColor: dailyColor,
              ),
              _CardStatItem(
                label: 'Updated',
                value: updatedStr,
                onTap: onRefreshTap,
                trailingIcon: onRefreshTap != null
                    ? Icons.refresh_rounded
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OpenWebAppLink extends StatelessWidget {
  final VoidCallback onTap;

  const _OpenWebAppLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.language_rounded, color: kAccent, size: 18),
            SizedBox(width: 8),
            Text(
              'Open Web App',
              style: TextStyle(
                color: kAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_forward_rounded, color: kAccent, size: 16),
          ],
        ),
      ),
    );
  }
}

class _CardStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;
  final IconData? trailingIcon;

  const _CardStatItem({
    required this.label,
    required this.value,
    this.valueColor,
    this.onTap,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  color: valueColor ?? kTextSec,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 4),
              Icon(trailingIcon, size: 14, color: kAccent),
            ],
          ],
        ),
      ],
    );

    if (onTap == null) return content;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}

class _MarketStatusPill extends StatelessWidget {
  const _MarketStatusPill();

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
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: textColor,
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
    return ClarivoSectionHeading(
      text: 'Market Snapshot',
      trailing: GestureDetector(
        onTap: () => AppRoutes.openNews(context),
        child: const Text(
          'View All >',
          style: TextStyle(
            color: kAccent,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  final String name;
  final String ticker;
  final String price;
  final String initial;
  final Color iconColor;
  final Color iconBorder;
  final String logoAsset;
  final double logoImageScale;
  final List<double>? chartPoints;
  final ChartDataMode? chartMode;
  final String chartPeriodLabel;
  final bool historyLoading;
  final StockQuote? quote;

  const _StockCard({
    required this.name,
    required this.ticker,
    required this.price,
    required this.initial,
    required this.iconColor,
    required this.iconBorder,
    required this.logoAsset,
    this.logoImageScale = 1.0,
    this.chartPoints,
    this.chartMode,
    this.chartPeriodLabel = '',
    this.historyLoading = false,
    this.quote,
  });

  static const double _logoSize = 44;

  @override
  Widget build(BuildContext context) {
    final points = chartPoints ?? const [];
    final trend = ClarivoSparklineChart.trendOf(points);
    final Color changeColor = trend.color;
    final IconData? changeIcon = trend.arrowIcon;
    final String changeText = trend.formattedPercent;
    final double imageSize = _logoSize * logoImageScale;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ticker,
                  style: const TextStyle(
                    color: kTextMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ClarivoSparklineChart.mini(
              values: points,
              height: 42,
              loading: historyLoading,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 86,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  price,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    color: kTextMain,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (changeIcon != null) ...[
                      Icon(changeIcon, size: 11, color: changeColor),
                      const SizedBox(width: 2),
                    ],
                    Flexible(
                      child: Text(
                        changeText,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: changeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
