import 'package:flutter/material.dart';

import '../core/theme/app_tokens.dart';

/// Labelled, filled text field matching the Figma input style (48px, 12px
/// radius, leading icon, optional trailing widget).
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    required this.prefixIcon,
    this.labelTrailing,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.validator,
    this.forceErrorText,
    this.onChanged,
    this.onFieldSubmitted,
    this.enabled = true,
  });

  final String label;
  final Widget? labelTrailing;
  final String hintText;
  final TextEditingController controller;
  final IconData prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final FormFieldValidator<String>? validator;
  final String? forceErrorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;

    OutlineInputBorder border(Color color, {double width = 0}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        borderSide: width == 0
            ? BorderSide.none
            : BorderSide(color: color, width: width),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelTrailing == null)
          Text(label, style: theme.textTheme.labelMedium)
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: theme.textTheme.labelMedium),
              labelTrailing!,
            ],
          ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          validator: validator,
          forceErrorText: forceErrorText,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          enabled: enabled,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle:
                theme.textTheme.bodyMedium?.copyWith(color: tokens.textHint),
            filled: true,
            fillColor: tokens.fieldFill,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 44, minHeight: 48),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(prefixIcon, size: 20, color: tokens.textSecondary),
            ),
            suffixIconConstraints:
                const BoxConstraints(minWidth: 48, minHeight: 48),
            suffixIcon: suffix,
            border: border(Colors.transparent),
            enabledBorder: border(Colors.transparent),
            focusedBorder:
                border(theme.colorScheme.primary, width: 1.5),
            errorBorder: border(theme.colorScheme.error, width: 1.5),
            focusedErrorBorder: border(theme.colorScheme.error, width: 1.5),
          ),
        ),
      ],
    );
  }
}
