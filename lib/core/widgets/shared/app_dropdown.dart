import 'package:flutter/material.dart';

/// Standard dropdown, consistent with [AppTextField] styling.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.items,
    required this.itemLabel,
    this.value,
    this.label,
    this.hint,
    this.helperText,
    this.required = false,
    this.onChanged,
    this.validator,
    this.enabled = true,
  });

  final List<T> items;
  final String Function(T) itemLabel;
  final T? value;
  final String? label;
  final String? hint;

  /// Shown below the field regardless of focus — use it to explain a
  /// constraint (e.g. why the field is disabled), not to restate the label.
  final String? helperText;
  final bool required;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final labelText = label == null ? null : (required ? '$label *' : label);
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hint,
        helperText: helperText,
        helperMaxLines: 2,
      ),
      items: items
          .map((e) => DropdownMenuItem<T>(value: e, child: Text(itemLabel(e))))
          .toList(),
      onChanged: enabled ? onChanged : null,
      validator: validator,
    );
  }
}
