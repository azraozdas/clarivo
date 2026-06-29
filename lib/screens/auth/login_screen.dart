import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../services/demo_auth_service.dart';
import '../../theme/app_colors.dart';
import '../../validators/form_validators.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/clarivo_page_header.dart';
import '../../widgets/clarivo_logo.dart';

/// Login screen — MaterialApp entry route with demo auth (PDF: Form + navigation).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // ── Form state ────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _rememberMe = false;
  bool _isLoading = false;
  String? _errorMessage;

  // ── Entrance animation ────────────────────────────────────────────────────
  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    // Short UI delay — frontend-only demo auth, no backend call.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    if (!DemoAuthService.validate(_emailCtrl.text, _passwordCtrl.text)) {
      setState(() {
        _isLoading = false;
        _errorMessage = DemoAuthService.invalidCredentialsMessage;
      });
      return;
    }

    setState(() => _isLoading = false);
    AppRoutes.openHomeAndClearStack(context);
  }

  void _goToRegister() => Navigator.pushNamed(context, AppRoutes.register);

  void _goToForgotPassword() =>
      Navigator.pushNamed(context, AppRoutes.forgotPassword);

  void _showDemoSocialSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Social sign-in is not implemented in this frontend demo.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      resizeToAvoidBottomInset: true,
      appBar: const ClarivoAppBar(title: 'Login'),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: kBgGradientColors,
            stops: kBgGradientStops,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final keyboardOpen =
                      MediaQuery.viewInsetsOf(context).bottom > 0;
                  return SingleChildScrollView(
                    physics: keyboardOpen
                        ? const ClampingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        _buildHeroHeader(),
                        const SizedBox(height: 20),
                        _buildForm(),
                        const SizedBox(height: 10),
                        _buildOptionsRow(),
                        _buildErrorBanner(),
                        const SizedBox(height: 16),
                        _buildSignInButton(),
                        const SizedBox(height: 16),
                        _buildSocialDivider(),
                        const SizedBox(height: 12),
                        _buildGoogleButton(),
                        const SizedBox(height: 8),
                        _buildAppleButton(),
                        const SizedBox(height: 12),
                        _buildSignUpLink(),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Section builders ──────────────────────────────────────────────────────

  /// Avatar circle + "Welcome to Clarivo" heading + subtitle — centered.
  Widget _buildHeroHeader() {
    return Column(
      children: [
        // Clarivo logo — brand mark from Main_logo.png.
        const ClarivoLogo(size: 96, fit: BoxFit.contain),
        const SizedBox(height: 14),
        const Text(
          'Welcome to Clarivo',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: kTextMain,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Sign in to manage your investments',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: kTextMuted,
            fontSize: 14,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AuthTextField(
            controller: _emailCtrl,
            label: 'Email Address',
            hint: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            textInputAction: TextInputAction.next,
            focusNode: _emailFocus,
            onEditingComplete: () =>
                FocusScope.of(context).requestFocus(_passwordFocus),
            validator: FormValidators.email,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: _passwordCtrl,
            label: 'Password',
            hint: 'Enter your password',
            isPassword: true,
            prefixIcon: Icons.lock_outline_rounded,
            textInputAction: TextInputAction.done,
            focusNode: _passwordFocus,
            onEditingComplete: _submit,
            validator: FormValidators.loginPassword,
            enabled: !_isLoading,
          ),
        ],
      ),
    );
  }

  /// "Remember me" on the left, "Forgot Password?" on the right.
  Widget _buildOptionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: _isLoading
              ? null
              : () => setState(() => _rememberMe = !_rememberMe),
          child: Row(
            children: [
              _CheckboxTile(
                value: _rememberMe,
                onChanged: _isLoading
                    ? null
                    : (v) => setState(() => _rememberMe = v ?? false),
              ),
              const SizedBox(width: 8),
              const Text(
                'Remember me',
                style: TextStyle(
                  color: kTextSec,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: _isLoading ? null : _goToForgotPassword,
          child: const Text(
            'Forgot Password?',
            style: TextStyle(
              color: kAccent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: _errorMessage != null
          ? Container(
              margin: const EdgeInsets.only(top: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: kNegative.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kNegative.withAlpha(80), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: kNegative, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: kNegative,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildSignInButton() {
    return _PrimaryButton(
      label: 'Sign In',
      isLoading: _isLoading,
      onTap: _submit,
    );
  }

  /// Horizontal rule with "Or continue with" in the center.
  Widget _buildSocialDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: kBorder, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Or continue with',
            style: TextStyle(
              color: kTextMuted.withAlpha(180),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(child: Divider(color: kBorder, thickness: 1)),
      ],
    );
  }

  /// UI-only Google login stub — wire up OAuth in production.
  Widget _buildGoogleButton() {
    // UI demo only — no real Google Sign-In backend.
    return _SocialButton(
      onTap: () {
        if (!_isLoading) _showDemoSocialSnackBar();
      },
      icon: const _GoogleIcon(),
      label: 'Continue with Google',
    );
  }

  /// UI-only Apple login stub — wire up Sign in with Apple in production.
  Widget _buildAppleButton() {
    // UI demo only — no real Apple Sign-In backend.
    return _SocialButton(
      onTap: () {
        if (!_isLoading) _showDemoSocialSnackBar();
      },
      icon: const _AppleIcon(),
      label: 'Continue with Apple',
    );
  }

  Widget _buildSignUpLink() {
    return Center(
      child: GestureDetector(
        onTap: _goToRegister,
        child: RichText(
          text: const TextSpan(
            text: "Don't have an account?  ",
            style: TextStyle(color: kTextMuted, fontSize: 14),
            children: [
              TextSpan(
                text: 'Sign Up',
                style: TextStyle(
                  color: kAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Private widgets ────────────────────────────────────────────────────────

/// Full-width teal gradient CTA button with loading state.
class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: isLoading
                ? [
                    kAccent.withAlpha(160),
                    const Color(0xFF2BB89A).withAlpha(160),
                  ]
                : [kAccent, const Color(0xFF2BB89A)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: kAccent.withAlpha(90),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(kBackground),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: kBackground,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Full-width outlined social login button.
class _SocialButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget icon;
  final String label;

  const _SocialButton({
    required this.onTap,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: kTextMain,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Google logo loaded from assets — replaces the custom-painter placeholder.
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logos/google_logo.png',
      width: 24,
      height: 24,
      fit: BoxFit.contain,
    );
  }
}

/// Apple logo loaded from assets — replaces the custom-painter placeholder.
class _AppleIcon extends StatelessWidget {
  const _AppleIcon();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logos/apple_logo.png',
      width: 28,
      height: 28,
      fit: BoxFit.contain,
    );
  }
}

/// Teal-styled checkbox matching the app's dark theme.
class _CheckboxTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;

  const _CheckboxTile({required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: Checkbox(
        value: value,
        onChanged: onChanged,
        activeColor: kAccent,
        checkColor: kBackground,
        side: const BorderSide(color: kBorder, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
