import 'package:shared_preferences/shared_preferences.dart';

/// Persists user share counts on the device using SharedPreferences.
/// Called by PortfolioPage to save and reload edited holdings.
///
/// Professor explanation:
///   "Prices come from the Marketstack API. User share quantities are stored
///   locally on the device with SharedPreferences. Portfolio values are
///   calculated dynamically from saved shares × live prices."
class PortfolioStorage {
  static const String _keyAapl = 'shares_AAPL';
  static const String _keyTsla = 'shares_TSLA';
  static const String _keyAmzn = 'shares_AMZN';

  /// Default demo holdings used when nothing has been saved yet.
  static const Map<String, int> defaults = {
    'AAPL': 10,
    'TSLA': 5,
    'AMZN': 8,
  };

  /// Loads saved share counts. Falls back to [defaults] on any error.
  static Future<Map<String, int>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'AAPL': prefs.getInt(_keyAapl) ?? defaults['AAPL']!,
        'TSLA': prefs.getInt(_keyTsla) ?? defaults['TSLA']!,
        'AMZN': prefs.getInt(_keyAmzn) ?? defaults['AMZN']!,
      };
    } catch (_) {
      return Map<String, int>.from(defaults);
    }
  }

  /// Saves [shares] to device storage. Silently ignores errors.
  static Future<void> save(Map<String, int> shares) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyAapl, shares['AAPL'] ?? defaults['AAPL']!);
      await prefs.setInt(_keyTsla, shares['TSLA'] ?? defaults['TSLA']!);
      await prefs.setInt(_keyAmzn, shares['AMZN'] ?? defaults['AMZN']!);
    } catch (_) {}
  }
}
