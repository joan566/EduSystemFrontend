import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

import '../shared/app_loading.dart';
import '../shared/picked_file.dart';

/// Desktop file intake (§30, §31, §44): a drag & drop zone with a file
/// picker fallback.
class DesktopUploadZone extends StatefulWidget {
  const DesktopUploadZone({
    super.key,
    required this.onFilePicked,
    this.allowedExtensions,
    this.title = 'Arrastra tu archivo aquí',
    this.subtitle,
    this.busy = false,
  });

  final void Function(PickedFile file) onFilePicked;
  final List<String>? allowedExtensions;
  final String title;
  final String? subtitle;

  /// True while the picked file is being uploaded: drops and picks are
  /// ignored and the zone shows an indeterminate progress bar.
  final bool busy;

  @override
  State<DesktopUploadZone> createState() => _DesktopUploadZoneState();
}

class _DesktopUploadZoneState extends State<DesktopUploadZone> {
  bool _dragging = false;

  Future<void> _pickFile() async {
    final file = await pickSingleFile(
      allowedExtensions: widget.allowedExtensions,
    );
    if (file != null) widget.onFilePicked(file);
  }

  bool _extensionAllowed(String name) {
    final allowed = widget.allowedExtensions;
    if (allowed == null) return true;
    final ext = name.split('.').last.toLowerCase();
    return allowed.map((e) => e.toLowerCase()).contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DropTarget(
      enable: !widget.busy,
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
            if (widget.busy) ...[
              Text(
                'Subiendo archivo…',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              const SizedBox(width: 240, child: AppProgressBar()),
            ] else ...[
              Icon(
                Icons.cloud_upload_outlined,
                size: 32,
                color: colors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text('o', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _pickFile,
                child: const Text('Seleccionar archivo'),
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 12),
                Text(
                  widget.subtitle!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
