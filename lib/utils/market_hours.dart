import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// US regular session hours (Mon–Fri 9:30–16:00 America/New_York).
/// Holiday calendar is not implemented — see README limitation.
class MarketHours {
  /// Converts [utc] to approximate US Eastern (EST/EDT without tz package).
  static DateTime toUsEastern(DateTime utc) {
    final month = utc.month;
    // Simplified DST window (Mar–Oct) — documented in README.
    final isDst = month >= 3 && month <= 10;
    return utc.subtract(Duration(hours: isDst ? 4 : 5));
  }

  static bool isUsRegularSessionOpen(DateTime eastern) {
    if (eastern.weekday == DateTime.saturday ||
        eastern.weekday == DateTime.sunday) {
      return false;
    }
    final minutes = eastern.hour * 60 + eastern.minute;
    return minutes >= 9 * 60 + 30 && minutes < 16 * 60;
  }

  static bool isOpenNow([DateTime? at]) {
    final utc = (at ?? DateTime.now()).toUtc();
    return isUsRegularSessionOpen(toUsEastern(utc));
  }

  static String statusLabel([DateTime? at]) {
    return isOpenNow(at) ? 'US Market Open' : 'US Market Closed';
  }

  static Color statusDotColor([DateTime? at]) {
    return isOpenNow(at) ? kAccent : kTextMuted;
  }

  static Color statusTextColor([DateTime? at]) {
    return isOpenNow(at) ? kAccent : kTextSec;
  }
}
