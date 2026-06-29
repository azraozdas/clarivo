import 'package:flutter/material.dart';

import '../../models/auth_models.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../validators/form_validators.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/clarivo_logo.dart';
import '../../widgets/clarivo_page_header.dart';

// Re-export shared private widgets from login_screen via a local copy.
// Keeping them here avoids a cross-screen import of private classes.

/// Registration screen for new Clarivo users.
///
/// Collects full name, email, password (with live strength meter), and
/// confirm password. Includes terms acceptance and navigates back to login.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _acceptedTerms = false;
  bool _isLoading = false;
  String? _errorMessage;
  PasswordStrength _strength = PasswordStrength.empty;

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
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  void _onPasswordChanged(String value) {
    setState(() => _strength = FormValidators.passwordStrength(value));
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    if (!_acceptedTerms) {
      setState(() =>
          _errorMessage = 'Please accept the Terms & Conditions to continue.');
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    // Simulate network call — replace with real auth service.
    await Future<void>.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;
    setState(() => _isLoading = false);

    AppRoutes.openHomeAndClearStack(context);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      resizeToAvoidBottomInset: true,
      appBar: ClarivoAppBar(
        title: 'Register',
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
                    const ClarivoLogo(size: 64),
                    const SizedBox(height: 28),
                    _buildHeading(),
                    const SizedBox(height: 28),
                    _buildForm(),
                    const SizedBox(height: 12),
                    _buildTermsRow(),
                    const SizedBox(height: 8),
                    _buildErrorBanner(),
                    const SizedBox(height: 24),
                    _buildCreateButton(),
                    const SizedBox(height: 32),
                    _buildLoginLink(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Sub-builders ─────────────────────────────────────────────────────────

  Widget _buildHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Create account',
          style: TextStyle(
            color: kTextMain,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Join Clarivo and start tracking your investments',
          style: TextStyle(
            color: kTextMuted,
            fontSize: 14,
            height: 1.5,
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
            controller: _nameCtrl,
            label: 'Full name',
            hint: 'Your full name',
            prefixIcon: Icons.person_outline_rounded,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            focusNode: _nameFocus,
            onEditingComplete: () =>
                FocusScope.of(context).requestFocus(_emailFocus),
            validator: FormValidators.fullName,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _emailCtrl,
            label: 'Email address',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            textInputAction: TextInputAction.next,
            focusNode: _emailFocus,
            onEditingComplete: () =>
                FocusScope.of(context).requestFocus(_passwordFocus),
            validator: FormValidators.email,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _passwordCtrl,
            label: 'Password',
            hint: 'Create a strong password',
            isPassword: true,
            prefixIcon: Icons.lock_outline_rounded,
            textInputAction: TextInputAction.next,
            focusNode: _passwordFocus,
            onEditingComplete: () =>
                FocusScope.of(context).requestFocus(_confirmFocus),
            onChanged: _onPasswordChanged,
            validator: FormValidators.password,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 10),
          // Password strength meter — only visible once typing starts.
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _strength != PasswordStrength.empty
                ? _PasswordStrengthMeter(strength: _strength)
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _confirmCtrl,
            label: 'Confirm password',
            hint: 'Repeat your password',
            isPassword: true,
            prefixIcon: Icons.lock_outline_rounded,
            textInputAction: TextInputAction.done,
            focusNode: _confirmFocus,
            onEditingComplete: _submit,
            validator: (v) =>
                FormValidators.confirmPassword(v, _passwordCtrl.text),
            enabled: !_isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildTermsRow() {
    return GestureDetector(
      onTap: _isLoading
          ? null
          : () => setState(() => _acceptedTerms = !_acceptedTerms),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: _acceptedTerms,
              onChanged: _isLoading
                  ? null
                  : (v) => setState(() => _acceptedTerms = v ?? false),
              activeColor: kAccent,
              checkColor: kBackground,
              side: const BorderSide(color: kBorder, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  color: kTextMuted,
                  fontSize: 13,
                  height: 1.5,
                ),
                children: [
                  TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                        color: kAccent, fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                        color: kAccent, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: _errorMessage != null
          ? Container(
              margin: const EdgeInsets.only(top: 8),
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
                          color: kNegative, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildCreateButton() {
    return _PrimaryButton(
      label: 'Create Account',
      isLoading: _isLoading,
      onTap: _submit,
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.maybePop(context),
        child: RichText(
          text: const TextSpan(
            text: 'Already have an account?  ',
            style: TextStyle(color: kTextMuted, fontSize: 14),
            children: [
              TextSpan(
                text: 'Sign In',
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

/// Four-segment password strength bar with animated fill and a label.
class _PasswordStrengthMeter extends StatelessWidget {
  final PasswordStrength strength;

  const _PasswordStrengthMeter({required this.strength});

  static const _segmentCount = 4;

  @override
  Widget build(BuildContext context) {
    final Color fillColor = strength.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Segmented bar.
        Row(
          children: List.generate(_segmentCount, (i) {
            final bool filled = i < strength.segmentsFilled;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: 4,
                margin: EdgeInsets.only(right: i < _segmentCount - 1 ? 6 : 0),
                decoration: BoxDecoration(
                  color: filled ? fillColor : kBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        // Strength label.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            strength.label,
            key: ValueKey(strength),
            style: TextStyle(
              color: fillColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Teal gradient CTA button — mirrors the one in login_screen.dart.
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
              : Text(
                  label,
                  style: const TextStyle(
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
