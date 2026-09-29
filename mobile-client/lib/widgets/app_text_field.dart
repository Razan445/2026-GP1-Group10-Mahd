import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A styled text field matching the Mahd design spec:
/// white fill, 1.5 px beige border, 16 px rounded corners,
/// 52 px minimum height, IBM Plex Sans Arabic typography.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint = '',
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.validator,
    this.helperText,
    this.errorText,
    this.textDirection,
  });

  final String label;
  final String hint;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final String? helperText;
  final String? errorText;
  final TextDirection? textDirection;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Field label ──────────────────────────────
        Text(widget.label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: 4),

        // ── Input ────────────────────────────────────
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword && _obscure,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          textDirection: widget.textDirection,
          style: AppTextStyles.bodyText.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
            // Password visibility toggle
            suffixIcon: widget.isPassword
                ? GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFFB39C8C),
                      size: 20,
                    ),
                  )
                : null,
          ),
        ),

        // ── Helper text (below field) ─────────────────
        if (widget.helperText != null) ...[
          const SizedBox(height: 4),
          Text(widget.helperText!, style: AppTextStyles.helperText),
        ],
      ],
    );
  }
}
