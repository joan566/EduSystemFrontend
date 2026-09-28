import 'package:flutter/material.dart';

import '../shared/picked_file.dart';

/// Mobile file intake: a full-width button that opens the native picker.
/// No drag & drop on phones.
class MobileFilePickerButton extends StatelessWidget {
  const MobileFilePickerButton({
    super.key,
    required this.onFilePicked,
    this.allowedExtensions,
    this.label = 'Seleccionar archivo',
    this.hint,
  });

  final void Function(PickedFile file) onFilePicked;
  final List<String>? allowedExtensions;
  final String label;

  /// Optional helper line under the button (formats, size limit...).
  final String? hint;

  Future<void> _pick() async {
    final file = await pickSingleFile(allowedExtensions: allowedExtensions);
    if (file != null) onFilePicked(file);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: _pick,
          icon: const Icon(Icons.upload_file_outlined),
          label: Text(label),
        ),
        if (hint != null) ...[
          const SizedBox(height: 8),
          Text(hint!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}
