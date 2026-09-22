import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../utils/formatters.dart';
import '../utils/responsive.dart';

/// A picked file's bytes plus metadata, uniform across drag & drop and the
/// native file picker (and across web/Android, where paths aren't always
/// available).
class PickedFile {
  const PickedFile({required this.name, required this.bytes, this.size});

  final String name;
  final Uint8List bytes;
  final int? size;
}

/// File intake widget (§30, §31, §44): a drag & drop zone with a file
/// picker fallback on desktop/tablet, a plain "select file" button on
/// mobile (no drag & drop attempted there).
class AppUploadZone extends StatefulWidget {
  const AppUploadZone({
    super.key,
    required this.onFilePicked,
    this.allowedExtensions,
    this.title = 'Arrastra tu archivo aquí',
    this.subtitle,
  });

  final void Function(PickedFile file) onFilePicked;
  final List<String>? allowedExtensions;
  final String title;
  final String? subtitle;

  @override
  State<AppUploadZone> createState() => _AppUploadZoneState();
}

class _AppUploadZoneState extends State<AppUploadZone> {
  bool _dragging = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: widget.allowedExtensions == null ? FileType.any : FileType.custom,
      allowedExtensions: widget.allowedExtensions,
    );
    final file = result.singleOrNull;
    if (file == null) return;
    final bytes = await file.readAsBytes();
    widget.onFilePicked(
      PickedFile(name: file.name, bytes: bytes, size: file.lengthSync() ?? bytes.length),
    );
  }

  bool _extensionAllowed(String name) {
    final allowed = widget.allowedExtensions;
    if (allowed == null) return true;
    final ext = name.split('.').last.toLowerCase();
    return allowed.map((e) => e.toLowerCase()).contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      return OutlinedButton.icon(
        onPressed: _pickFile,
        icon: const Icon(Icons.upload_file_outlined),
        label: const Text('Seleccionar archivo'),
      );
    }

    final colors = Theme.of(context).colorScheme;

    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: (details) async {
        setState(() => _dragging = false);
        final dropped = details.files.firstOrNull;
        if (dropped == null) return;
        if (!_extensionAllowed(dropped.name)) {
          return;
        }
        final bytes = await dropped.readAsBytes();
        widget.onFilePicked(
          PickedFile(name: dropped.name, bytes: bytes, size: bytes.length),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: _dragging
              ? colors.primary.withValues(alpha: 0.06)
              : colors.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _dragging ? colors.primary : colors.outline,
            width: _dragging ? 1.5 : 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_upload_outlined, size: 32, color: colors.primary),
            const SizedBox(height: 12),
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('o', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _pickFile, child: const Text('Seleccionar archivo')),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 12),
              Text(
                widget.subtitle!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact summary row for a file selected via [AppUploadZone] (§72):
/// name, size, and a remove action.
class AppSelectedFileTile extends StatelessWidget {
  const AppSelectedFileTile({super.key, required this.file, required this.onRemove});

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
          IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onRemove),
        ],
      ),
    );
  }
}
