import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A styled text input field used across all Clarivo auth screens.
///
/// Matches the dark-card aesthetic of the rest of the app:
///   • [kCard] fill  •  [kBorder] idle border  •  [kAccent] focused border
///   • [kNegative] error border  •  [kNavInactive] hint text
///
/// Pass [isPassword] to enable the show / hide eye-icon toggle.
class AuthTextField extends StatefulWidget {
  final TextEditingController controller;

  /// Short label rendered above the field (e.g. "Email address").
  final String label;

  /// Placeholder text shown inside the field when empty.
  final String hint;

  /// When `true` text is obscured and a toggle icon is shown.
  final bool isPassword;

  final TextInputType keyboardType;

  /// Flutter form validator — return `null` on success, a string on error.
  final String? Function(String?)? validator;

  /// Optional leading icon inside the field (e.g. `Icons.email_outlined`).
  final IconData? prefixIcon;

  final TextInputAction? textInputAction;

  /// Provide an external [FocusNode] to control focus from the parent.
  final FocusNode? focusNode;

  /// Called when the user presses the keyboard's action button.
  final VoidCallback? onEditingComplete;

  /// Called on every keystroke — useful for real-time feedback (strength meter).
  final ValueChanged<String>? onChanged;

  final bool enabled;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.textInputAction,
    this.focusNode,
    this.onEditingComplete,
    this.onChanged,
    this.enabled = true,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscure = true;
  late final FocusNode _node;
  bool _hasFocus = false;

  // Tracks whether the field owns the FocusNode so we can dispose it safely.
  bool _ownsNode = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _node = widget.focusNode!;
    } else {
      _node = FocusNode();
      _ownsNode = true;
    }
    _node.addListener(_onFocus);
  }

  void _onFocus() => setState(() => _hasFocus = _node.hasFocus);

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    if (_ownsNode) _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: kTextSec,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          focusNode: _node,
          obscureText: widget.isPassword && _obscure,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          textInputAction: widget.textInputAction,
          onEditingComplete: widget.onEditingComplete,
          onChanged: widget.onChanged,
          enabled: widget.enabled,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: const TextStyle(
            color: kTextMain,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(
              color: kNavInactive,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: kCard,
            // Prefix icon color shifts to accent when focused.
            prefixIcon: widget.prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 14, right: 10),
                    child: Icon(
                      widget.prefixIcon,
                      color: _hasFocus ? kAccent : kTextMuted,
                      size: 20,
                    ),
                  )
                : null,
            prefixIconConstraints:
                widget.prefixIcon != null ? const BoxConstraints() : null,
            // Password visibility toggle.
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: kTextMuted,
                      size: 20,
                    ),
                    splashRadius: 20,
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            // Border states — idle, focused, error, focused+error.
            border: _border(kBorder),
            enabledBorder: _border(kBorder),
            focusedBorder: _border(kAccent, width: 1.5),
            errorBorder: _border(kNegative),
            focusedErrorBorder: _border(kNegative, width: 1.5),
            disabledBorder: _border(kBorder.withAlpha(100)),
            errorStyle: const TextStyle(
              color: kNegative,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
            errorMaxLines: 2,
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1.0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
