import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Data passed from the Login form on submission.
class LoginFormData {
  final String email;
  final String password;
  final bool rememberMe;

  const LoginFormData({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });
}

/// Data passed from the Register form on submission.
class RegisterFormData {
  final String fullName;
  final String email;
  final String password;
  final String confirmPassword;

  const RegisterFormData({
    required this.fullName,
    required this.email,
    required this.password,
    required this.confirmPassword,
  });
}

/// Represents the relative strength of a password, used by the strength meter.
enum PasswordStrength { empty, weak, fair, good, strong }

extension PasswordStrengthX on PasswordStrength {
  /// Human-readable label shown below the strength meter.
  String get label {
    switch (this) {
      case PasswordStrength.empty:  return '';
      case PasswordStrength.weak:   return 'Weak';
      case PasswordStrength.fair:   return 'Fair';
      case PasswordStrength.good:   return 'Good';
      case PasswordStrength.strong: return 'Strong';
    }
  }

  /// Accent color for the filled segments and the label.
  Color get color {
    switch (this) {
      case PasswordStrength.empty:  return Colors.transparent;
      case PasswordStrength.weak:   return kNegative;
      case PasswordStrength.fair:   return kWarning;
      case PasswordStrength.good:   return const Color(0xFF8BC34A);
      case PasswordStrength.strong: return kAccent;
    }
  }

  /// Number of segments (out of 4) that should be filled.
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
