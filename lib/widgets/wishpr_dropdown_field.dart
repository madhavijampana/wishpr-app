import 'package:flutter/material.dart';

import '../theme/wishpr_constants.dart';

/// Dropdown styled like other Wishpr text fields (avoids deprecated form APIs).
class WishprDropdownField<T> extends StatelessWidget {
  const WishprDropdownField({
    super.key,
    required this.labelText,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String labelText;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: labelText,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(WishprLayout.fieldRadius),
          dropdownColor: cs.surfaceContainerHighest,
          iconEnabledColor: cs.primary,
          style: Theme.of(context).textTheme.bodyLarge,
          items: items
              .map(
                (e) => DropdownMenuItem<T>(
                  value: e,
                  child: Text(itemLabel(e)),
                ),
              )
              .toList(),
          onChanged: onChanged == null
              ? null
              : (v) {
                  if (v != null) onChanged!(v);
                },
        ),
      ),
    );
  }
}
