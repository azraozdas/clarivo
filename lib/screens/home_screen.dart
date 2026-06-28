import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:clarivo/routes/app_routes.dart';
import 'package:clarivo/services/location_service.dart';
import 'package:clarivo/services/twelve_data_service.dart';
import 'package:clarivo/services/portfolio_storage.dart';
import 'package:clarivo/widgets/clarivo_nav_bar.dart';
import 'package:clarivo/widgets/clarivo_page_header.dart';
import 'package:clarivo/widgets/clarivo_sparkline_chart.dart';
import 'package:clarivo/widgets/current_location_chip.dart';
import 'package:clarivo/theme/app_colors.dart';
import 'package:clarivo/utils/market_hours.dart';
import 'package:clarivo/utils/visual_chart_trend.dart';

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
  String _updatedStr = '';
  bool _locationLoading = false;
  LocationResolveState _locationState = LocationResolveState.pending;
  UserLocation? _userLocation;
  bool _locationInFlight = false;
  bool _initStarted = false;
  bool _locationPromptScheduled = false;

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
  final int _historyDays = TwelveDataService.homeHistoryDays;

  bool get _hasAnyChartHistory {
    for (final sym in ['AAPL', 'TSLA', 'AMZN']) {
      if (TwelveDataService.closesForSymbol(_history, sym).length >= 2) {
        return true;
      }
    }
    return false;
  }

  bool get _hasPortfolioChart =>
      _balanceSeries.points.length >= TwelveDataService.minWavyChartPoints;

  /// Show chart spinners only while history is missing — keep cached charts visible.
  bool get _showHistoryLoading => _historyLoading && !_hasPortfolioChart;

  bool get _showBalanceLoading =>
      _loading && !_hasAnyChartHistory && _quotes.isEmpty;

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

  void _enrichQuotesFromHistory() {
    final enriched =
        TwelveDataService.enrichQuotesFromHistory(_quotes, _history);
    _quotes
      ..clear()
      ..addAll(enriched);
  }

  void _refreshChartSeries() {
    final period =
        TwelveDataService.chartPeriodLabel(_historyDays);
    _balanceSeries = TwelveDataService.portfolioChartSeries(
      _history,
      _shares,
      _quotes,
      context: 'Home',
      periodLabel: period,
    );
    _aaplSeries = TwelveDataService.stockChartSeries(
      _history,
      'AAPL',
      _quotes['AAPL'],
      context: 'Home',
      periodLabel: period,
    );
    _tslaSeries = TwelveDataService.stockChartSeries(
      _history,
      'TSLA',
      _quotes['TSLA'],
      context: 'Home',
      periodLabel: period,
    );
    _amznSeries = TwelveDataService.stockChartSeries(
      _history,
      'AMZN',
      _quotes['AMZN'],
      context: 'Home',
      periodLabel: period,
    );
    for (final sym in ['AAPL', 'TSLA', 'AMZN']) {
      TwelveDataService.logStockAudit(
        sym,
        _quotes[sym],
        _chartSeriesFor(sym).points,
        chartPeriod: period,
      );
    }
    TwelveDataService.logPortfolioAudit(
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
      if (!_locationInFlight) {
        _refreshLocationOnResume();
      }
      if (_initStarted && !_loading) {
        _loadQuotes(forceRefresh: false);
      }
    }
  }

  /// Re-resolves GPS after emulator location changes or returning from settings.
  Future<void> _refreshLocationOnResume() async {
    if (_locationInFlight || _locationLoading) return;
    final permission = await LocationService.currentPermission();
    final shouldRequest = LocationService.isPermissionDenied(permission) &&
        (_locationState == LocationResolveState.denied ||
            _locationState == LocationResolveState.pending);
    if (LocationService.isPermissionGranted(permission) ||
        _locationState != LocationResolveState.success) {
      await _runLocationFlow(requestPermissionIfDenied: shouldRequest);
    }
  }

  /// Loads saved share counts, then warms cache, then fetches live prices.
  /// Location detection starts after first frame so the permission dialog can show.
  Future<void> _initAndLoad() async {
    if (_initStarted) return;
    _initStarted = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleInitialLocationPrompt();
    });

    final saved = await PortfolioStorage.load();
    if (mounted) {
      setState(() => _shares = saved);
    }

    // Warm quotes + history in parallel so charts can paint on first frame.
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
          _hasError = false;
          _isStaleData = true;
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

    // Background refresh — reuse warmed memory/prefs cache (no force invalidate).
    await _loadQuotes(forceRefresh: false);
  }

  /// Waits for Home to settle, then checks permission without long loading.
  void _scheduleInitialLocationPrompt() {
    if (_locationPromptScheduled || !mounted) return;
    _locationPromptScheduled = true;
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _runLocationFlow(requestPermissionIfDenied: false);
    });
  }

  Future<LocationResolveState> _stateWithPermissionSync(
    LocationResolveResult result,
  ) async {
    if (result.state != LocationResolveState.unavailable) {
      return result.state;
    }
    final permission = await LocationService.currentPermission();
    if (permission == LocationPermission.deniedForever) {
      return LocationResolveState.deniedForever;
    }
    if (LocationService.isPermissionDenied(permission)) {
      return LocationResolveState.denied;
    }
    return result.state;
  }

  void _applyLocationResult(
    LocationResolveResult result,
    LocationResolveState state,
  ) {
    _locationState = state;
    _userLocation = result.location;
  }

  /// Quick permission/service check, then GPS fetch only when access is granted.
  Future<void> _runLocationFlow({
    required bool requestPermissionIfDenied,
    bool force = false,
  }) async {
    if (!mounted) return;
    if (_locationInFlight && !force) return;
    _locationInFlight = true;

    try {
      final access = await LocationService.resolveAccess(
        requestIfDenied: requestPermissionIfDenied,
      );
      if (!mounted) return;

      if (access.state != LocationResolveState.pending) {
        setState(() {
          _locationLoading = false;
          _applyLocationResult(access, access.state);
        });
        debugPrint('[HomeScreen] location access state=${access.state}');
        return;
      }

      setState(() => _locationLoading = true);

      final result = await LocationService.fetchLocationAfterPermissionGranted()
          .timeout(
        const Duration(seconds: 24),
        onTimeout: () {
          debugPrint('[HomeScreen] location fetch timed out');
          return const LocationResolveResult(
            state: LocationResolveState.unavailable,
          );
        },
      );
      if (!mounted) return;

      final syncedState = await _stateWithPermissionSync(result);
      setState(() {
        _locationLoading = false;
        _applyLocationResult(result, syncedState);
      });
      debugPrint(
        '[HomeScreen] location state=$syncedState '
        'place=${result.location?.formatted ?? "none"}',
      );
    } catch (e, st) {
      debugPrint('[HomeScreen] location error: $e\n$st');
      if (mounted) {
        final syncedState = await _stateWithPermissionSync(
          const LocationResolveResult(state: LocationResolveState.unavailable),
        );
        setState(() {
          _locationLoading = false;
          _locationState = syncedState;
        });
      }
    } finally {
      _locationInFlight = false;
      if (mounted && _locationLoading) {
        setState(() => _locationLoading = false);
      }
    }
  }

  Future<void> _onLocationChipTap() async {
    if (_locationLoading || _locationInFlight) {
      _locationInFlight = false;
      if (mounted) setState(() => _locationLoading = false);
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() => _locationState = LocationResolveState.serviceDisabled);
      }
      await Geolocator.openLocationSettings();
      return;
    }

    final permission = await LocationService.ensurePermission(
      requestIfDenied: true,
    );
    debugPrint('[HomeScreen] chip tap permission=$permission');

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() => _locationState = LocationResolveState.deniedForever);
      }
      await Geolocator.openAppSettings();
      return;
    }

    if (LocationService.isPermissionDenied(permission)) {
      if (mounted) {
        setState(() => _locationState = LocationResolveState.denied);
      }
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 300));
    await _runLocationFlow(
      requestPermissionIfDenied: false,
      force: true,
    );
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
    final hadCachedHistory = _hasAnyChartHistory;

    if (mounted) {
      setState(() {
        _loading = _quotes.isEmpty && !_hasAnyChartHistory;
        _hasError = false;
        if (forceRefresh) _isStaleData = false;
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
        _hasError = _quotes.isEmpty && !_hasAnyChartHistory;
        if (_hasError && TwelveDataService.isRateLimitActive) {
          _errorMessage =
              'Twelve Data API rate limit reached. Showing cached data.';
          _errorHint =
              'Quota resets daily. Cached data will appear when available.';
          _isStaleData = true;
        } else if (_hasError) {
          _errorMessage = 'Could not load market data.';
          _errorHint = 'Check your connection and tap Retry.';
        }
        _isStaleData = data.fromCache || TwelveDataService.lastFetchFromCache;
        if (!data.fromCache && !TwelveDataService.lastFetchFromCache) {
          _updatedStr =
              'Last updated ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        } else if (_updatedStr.isEmpty) {
          _updatedStr = 'Cached data';
        }
      });
      debugPrint(
        '[HomeScreen] bootstrap quotes=${_quotes.length} '
        'history=${_history.length} apiCalls=${TwelveDataService.apiRequestCount}',
      );
      TwelveDataService.debugLogChartCounts(_history, _shares, _quotes,
          screen: 'Home');
    } catch (e) {
      debugPrint('[HomeScreen] bootstrap error: $e');
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
            _hasError = !_hasAnyChartHistory && _quotes.isEmpty;
            if (_hasError && TwelveDataService.isRateLimitActive) {
              _errorMessage =
                  'Twelve Data API rate limit reached. Showing cached data.';
              _errorHint =
                  'Quota resets daily. Cached data will appear when available.';
            }
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
    var t = 0.0;
    for (final e in _shares.entries) {
      final q = _quotes[e.key];
      if (q != null) {
        t += q.close * e.value;
      } else {
        final closes = TwelveDataService.closesForSymbol(_history, e.key);
        if (closes.isNotEmpty) t += closes.last * e.value;
      }
    }
    return t;
  }

  double get _dailyGain =>
      TwelveDataService.portfolioDailyGain(_quotes, _shares);

  double get _invested {
    double inv = 0;
    for (final e in _shares.entries) {
      final q = _quotes[e.key];
      if (q != null) inv += q.open * e.value;
    }
    return inv;
  }

  bool get _hasData => _quotes.isNotEmpty || _hasAnyChartHistory;

  ChartSeries? _seriesForDisplay(ChartSeries series) =>
      series.points.length >= TwelveDataService.minWavyChartPoints ? series : null;

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
    final aaplSeries = _seriesForDisplay(_aaplSeries);
    final tslaSeries = _seriesForDisplay(_tslaSeries);
    final amznSeries = _seriesForDisplay(_amznSeries);

    return Scaffold(
      backgroundColor: kBackground,
      appBar: const ClarivoAppBar(title: 'Home'),
      bottomNavigationBar: ClarivoBotNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onNavTap,
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
                const SizedBox(height: ClarivoLayout.sectionGap),
                if (_showBalanceLoading)
                  const _LoadingBalanceCard()
                else if (_hasError && !_hasAnyChartHistory && _quotes.isEmpty)
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
                    updatedStr: _updatedStr.isEmpty
                        ? 'Just now'
                        : (_isStaleData ? 'Cached data' : _updatedStr),
                    chartPoints: balanceSeries.points,
                    chartMode: balanceSeries.mode,
                    chartPeriodLabel: balanceSeries.displayPeriodLabel,
                    historyLoading: _showHistoryLoading,
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
                            chartPeriodLabel:
                                aaplSeries?.displayPeriodLabel ?? '',
                            historyLoading:
                                _historyLoading && aaplSeries == null,
                            quote: _quotes['AAPL'],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _openDetail('TSLA'),
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
                            chartPeriodLabel:
                                tslaSeries?.displayPeriodLabel ?? '',
                            historyLoading:
                                _historyLoading && tslaSeries == null,
                            quote: _quotes['TSLA'],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _openDetail('AMZN'),
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
                            chartPeriodLabel:
                                amznSeries?.displayPeriodLabel ?? '',
                            historyLoading:
                                _historyLoading && amznSeries == null,
                            quote: _quotes['AMZN'],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
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
          colors: kCardGradientColors,
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
          colors: kCardGradientColors,
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
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: kCardGradientColors,
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
          const SizedBox(height: 10),
          Text(
            totalStr,
            style: const TextStyle(
              color: kTextMain,
              fontSize: 40,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 8),
          ClarivoSparklineChart.main(
            values: chartPoints,
            height: 74,
            loading: historyLoading,
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: kBorder),
          const SizedBox(height: 12),
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

  static const double _logoSize = 40;

  @override
  Widget build(BuildContext context) {
    final points = chartPoints ?? const [];
    final trend = ClarivoSparklineChart.trendOf(points);
    final Color changeColor = trend.color;
    final IconData? changeIcon = trend.arrowIcon;
    final String changeText = trend.formattedPercent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final innerHeight = constraints.maxHeight;
          final rowHeight = innerHeight.isFinite && innerHeight > 0
              ? innerHeight.clamp(36.0, _logoSize)
              : _logoSize;
          final logoSide = rowHeight;
          final imageSize = logoSide * logoImageScale;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: logoSide,
                height: logoSide,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: iconBorder, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Center(
                      child: Image.asset(
                        logoAsset,
                        width: imageSize,
                        height: imageSize,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            initial,
                            style: TextStyle(
                              color: kTextMain,
                              fontSize: logoSide * 0.45,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 92,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(
                        color: kTextMain,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ticker,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(
                        color: kTextMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: rowHeight,
                  child: ClarivoSparklineChart.mini(
                    values: points,
                    height: rowHeight,
                    loading: historyLoading,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 82,
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
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
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
                              height: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
