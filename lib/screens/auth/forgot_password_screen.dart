import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../validators/form_validators.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/clarivo_page_header.dart';

/// Forgot Password screen.
///
/// Two visual states managed with [AnimatedSwitcher]:
///   1. **Input** — email field + "Send Reset Link" button.
///   2. **Success** — confirmation illustration + "Back to Sign In" button.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;

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
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    // Simulate network call — replace with real password-reset service.
    await Future<void>.delayed(const Duration(milliseconds: 1800));

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isSuccess = true;
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      resizeToAvoidBottomInset: true,
      appBar: ClarivoAppBar(
        title: 'Forgot Password',
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
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
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    // AnimatedSwitcher handles the input ↔ success transition.
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.05),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _isSuccess
                          ? _SuccessView(
                              email: _emailCtrl.text.trim(),
                              onBackToLogin: () => Navigator.maybePop(context),
                            )
                          : _InputView(
                              formKey: _formKey,
                              emailCtrl: _emailCtrl,
                              isLoading: _isLoading,
                              errorMessage: _errorMessage,
                              onSubmit: _submit,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Input view ──────────────────────────────────────────────────────────────

/// The default state — shows the email field and the send button.
class _InputView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onSubmit;

  const _InputView({
    required this.formKey,
    required this.emailCtrl,
    required this.isLoading,
    required this.errorMessage,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('input'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Icon illustration.
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: kAccent.withAlpha(40),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              color: kAccent,
              size: 38,
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Forgot password?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: kTextMain,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Enter the email address linked to your account and we'll send you a password reset link.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: kTextMuted,
            fontSize: 14,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),
        Form(
          key: formKey,
          child: AuthTextField(
            controller: emailCtrl,
            label: 'Email address',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            textInputAction: TextInputAction.done,
            onEditingComplete: onSubmit,
            validator: FormValidators.email,
            enabled: !isLoading,
          ),
        ),
        const SizedBox(height: 8),
        // Error banner.
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: errorMessage != null
              ? Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: kNegative.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: kNegative.withAlpha(80), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: kNegative, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(
                              color: kNegative, fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 24),
        _SendButton(isLoading: isLoading, onTap: onSubmit),
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: const Text(
              'Back to Sign In',
              style: TextStyle(
                color: kAccent,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Success view ────────────────────────────────────────────────────────────

/// Shown after a successful reset-link request.
class _SuccessView extends StatelessWidget {
  final String email;
  final VoidCallback onBackToLogin;

  const _SuccessView({required this.email, required this.onBackToLogin});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('success'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Animated checkmark container.
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kAccent, Color(0xFF2BB89A)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: kAccent.withAlpha(80),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              color: kBackground,
              size: 38,
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Check your inbox',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: kTextMain,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        // Confirmation message with the submitted email highlighted.
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              color: kTextMuted,
              fontSize: 14,
              height: 1.6,
            ),
            children: [
              const TextSpan(text: "We sent a password reset link to\n"),
              TextSpan(
                text: email,
                style: const TextStyle(
                  color: kAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(
                text:
                    "\n\nCheck your spam folder if you don't see it within a few minutes.",
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        // Tip card.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: kAccent.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_outline_rounded,
                    color: kAccent, size: 20),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'The link expires in 15 minutes. Request a new one if needed.',
                  style: TextStyle(
                    color: kTextSec,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _BackToLoginButton(onTap: onBackToLogin),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Buttons ────────────────────────────────────────────────────────────────

class _SendButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _SendButton({required this.isLoading, required this.onTap});

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
          borderRadius: BorderRadius.circular(14),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: kAccent.withAlpha(80),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(kBackground),
                  ),
                )
              : const Text(
                  'Send Reset Link',
                  style: TextStyle(
                    color: kBackground,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}

class _BackToLoginButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackToLoginButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder, width: 1),
        ),
        child: const Center(
          child: Text(
            'Back to Sign In',
            style: TextStyle(
              color: kTextMain,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
