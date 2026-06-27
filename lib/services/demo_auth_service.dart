/// Frontend-only demo login — no backend, fixed test accounts for the exam.
class DemoAuthService {
  DemoAuthService._();

  static const String invalidCredentialsMessage = 'Invalid email or password';

  static const Map<String, String> _demoAccounts = {
    'demo@clarivo.com': '123456',
    'azra.ozdas@ue-germany.de': '123456',
  };

  /// Returns true when [email] and [password] match a demo account.
  static bool validate(String email, String password) {
    final key = email.trim().toLowerCase();
    final expected = _demoAccounts[key];
    if (expected == null) return false;
    return password == expected;
  }
}
