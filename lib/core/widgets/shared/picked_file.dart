import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../utils/formatters.dart';

/// A picked file's bytes plus metadata, uniform across drag & drop and the
/// native file picker (and across web/Android, where paths aren't always
/// available).
class PickedFile {
  const PickedFile({required this.name, required this.bytes, this.size});

  final String name;
  final Uint8List bytes;
  final int? size;
}

/// Opens the native file picker and returns the chosen file, or null if
/// the user cancelled.
Future<PickedFile?> pickSingleFile({List<String>? allowedExtensions}) async {
  final result = await FilePicker.pickFiles(
    type: allowedExtensions == null ? FileType.any : FileType.custom,
    allowedExtensions: allowedExtensions,
  );
  final file = result.singleOrNull;
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  return PickedFile(
    name: file.name,
    bytes: bytes,
    size: file.lengthSync() ?? bytes.length,
  );
}

/// Compact summary row for a selected file (§72): name, size, and a
/// remove action.
class AppSelectedFileTile extends StatelessWidget {
  const AppSelectedFileTile({
    super.key,
    required this.file,
    required this.onRemove,
  });

  final PickedFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file.name, overflow: TextOverflow.ellipsis),
                if (file.size != null)
                  Text(
                    Formatters.fileSize(file.size!),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
