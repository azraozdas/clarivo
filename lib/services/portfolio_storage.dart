import 'package:shared_preferences/shared_preferences.dart';

/// Persists user share counts on the device using SharedPreferences.
/// Single source of truth for Home, Portfolio, and Stock Detail screens.
///
/// Professor explanation:
///   "Prices come from the Twelve Data API. User share quantities are stored
///   locally on the device with SharedPreferences. Portfolio values are
///   calculated dynamically from saved shares × live prices."
class PortfolioStorage {
  /// Stocks shown on Home / Portfolio watchlist.
  static const List<String> supportedSymbols = ['AAPL', 'TSLA', 'AMZN'];

  /// New users start with no holdings.
  static const int defaultShareCount = 0;

  /// Demo seed applied once on first launch so the Home chart is visible.
  static const Map<String, int> _demoSeed = {
    'AAPL': 2,
    'TSLA': 1,
    'AMZN': 1,
  };
  static const String _seedAppliedKey = 'portfolio_demo_seed_v1';

  /// Default share map — all supported symbols at 0.
  static Map<String, int> get defaults => {
        for (final sym in supportedSymbols) sym: defaultShareCount,
      };

  static String _prefKey(String symbol) =>
      'shares_${symbol.toUpperCase().trim()}';

  /// Seeds demo holdings once on first launch so the Home portfolio chart
  /// is visible on a fresh install / emulator without any prior data.
  /// Does nothing if shares were already saved or seed was already applied.
  static Future<void> seedDemoIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_seedAppliedKey) == true) return;
      // Check whether user already has any saved shares.
      final hasAny = supportedSymbols.any(
        (sym) => (prefs.getInt(_prefKey(sym)) ?? 0) > 0,
      );
      if (!hasAny) {
        for (final entry in _demoSeed.entries) {
          await prefs.setInt(_prefKey(entry.key), entry.value);
        }
      }
      await prefs.setBool(_seedAppliedKey, true);
    } catch (_) {}
  }

  /// Loads saved share counts for [supportedSymbols]. Missing keys default to 0.
  static Future<Map<String, int>> loadShares() async {
    await seedDemoIfNeeded();
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        for (final sym in supportedSymbols)
          sym: prefs.getInt(_prefKey(sym)) ?? defaultShareCount,
      };
    } catch (_) {
      return Map<String, int>.from(defaults);
    }
  }

  /// Alias kept for existing call sites.
  static Future<Map<String, int>> load() => loadShares();

  /// Returns saved shares for [symbol], or 0 if nothing saved yet.
  static Future<int> getShares(String symbol) async {
    final sym = symbol.toUpperCase().trim();
    if (sym.isEmpty) return defaultShareCount;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_prefKey(sym)) ?? defaultShareCount;
    } catch (_) {
      return defaultShareCount;
    }
  }

  /// Saves share count for [symbol]. Values are clamped to >= 0.
  static Future<void> setShares(String symbol, int count) async {
    final sym = symbol.toUpperCase().trim();
    if (sym.isEmpty) return;
    final safe = count < 0 ? 0 : count;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKey(sym), safe);
    } catch (_) {}
  }

  /// Adds 1 share and returns the new count.
  static Future<int> buyShare(String symbol) async {
    final current = await getShares(symbol);
    final newCount = current + 1;
    await setShares(symbol, newCount);
    return newCount;
  }

  /// Removes 1 share. Returns the new count, or -1 if none to sell.
  static Future<int> sellShare(String symbol) async {
    final current = await getShares(symbol);
    if (current <= 0) return -1;
    final newCount = current - 1;
    await setShares(symbol, newCount);
    return newCount;
  }

  /// Saves all share counts at once. Silently ignores errors.
  static Future<void> save(Map<String, int> shares) async {
    try {
      for (final sym in supportedSymbols) {
        await setShares(sym, shares[sym] ?? defaultShareCount);
      }
    } catch (_) {}
  }

  /// Clears all holdings back to 0 (useful for testing / profile reset).
  static Future<void> resetToDefaultShares() async {
    await save(Map<String, int>.from(defaults));
  }
}
