import '../models/auth_models.dart';

/// Pure validation functions used by every auth form.
///
/// Each function returns `null` on success or a user-facing error message
/// string on failure — the convention expected by Flutter's [FormField.validator].
class FormValidators {
  FormValidators._();

  /// Validates a non-empty, properly formatted email address.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final RegExp emailRegex =
        RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates login password — demo accounts use 6+ characters.
  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validates a non-empty password of at least 8 characters.
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  /// Validates that [value] matches [original] (confirm-password field).
  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != original) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validates a non-empty full name containing only letters, spaces,
  /// hyphens, and apostrophes (e.g. "Jean-Luc O'Brien").
  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value.trim())) {
      return "Name may only contain letters, spaces, hyphens, and apostrophes";
    }
    return null;
  }

  /// Scores a password and returns the corresponding [PasswordStrength].
  ///
  /// Scoring criteria (each worth 1 point):
  ///   1. At least 8 characters
  ///   2. At least 12 characters
  ///   3. Contains an uppercase letter
  ///   4. Contains a digit
  ///   5. Contains a special character
  static PasswordStrength passwordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.empty;

    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-\+]').hasMatch(password)) score++;

    if (score <= 1) return PasswordStrength.weak;
    if (score == 2) return PasswordStrength.fair;
    if (score == 3) return PasswordStrength.good;
    return PasswordStrength.strong;
  }
}
