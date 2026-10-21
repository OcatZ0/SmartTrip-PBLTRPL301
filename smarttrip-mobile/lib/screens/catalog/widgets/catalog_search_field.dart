import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

/// The white search field of the catalog header, also used by trip step 2.
class CatalogSearchField extends StatelessWidget {
  const CatalogSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.hintText,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  /// Defaults to the catalog's hint.
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      height: 52,
      padding: const EdgeInsets.only(left: 14, right: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.floatShadow,
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 22, color: AppColors.sea600),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              cursorColor: AppColors.sea600,
              style: appText(14, FontWeight.w400, AppColors.ink),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hintText ?? l10n.catalogSearchHint,
                hintMaxLines: 1,
                hintStyle: appText(
                  14,
                  FontWeight.w400,
                  AppColors.inkMuted,
                ),
              ),
            ),
          ),
          // Listens to the field itself, so typing does not rebuild the
          // whole catalog just to show or hide this button.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: l10n.catalogClearSearch,
                    onPressed: onClear,
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.inkMuted,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
