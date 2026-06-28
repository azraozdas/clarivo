import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Password strength levels for the register screen meter.
enum PasswordStrength { empty, weak, fair, good, strong }

extension PasswordStrengthX on PasswordStrength {
  String get label {
    switch (this) {
      case PasswordStrength.empty:  return '';
      case PasswordStrength.weak:   return 'Weak';
      case PasswordStrength.fair:   return 'Fair';
      case PasswordStrength.good:   return 'Good';
      case PasswordStrength.strong: return 'Strong';
    }
  }

  Color get color {
    switch (this) {
      case PasswordStrength.empty:  return Colors.transparent;
      case PasswordStrength.weak:   return kNegative;
      case PasswordStrength.fair:   return kWarning;
      case PasswordStrength.good:   return const Color(0xFF8BC34A);
      case PasswordStrength.strong: return kAccent;
    }
  }

  int get segmentsFilled {
    switch (this) {
      case PasswordStrength.empty:  return 0;
      case PasswordStrength.weak:   return 1;
      case PasswordStrength.fair:   return 2;
      case PasswordStrength.good:   return 3;
      case PasswordStrength.strong: return 4;
    }
  }
}
