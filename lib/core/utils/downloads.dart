import 'dart:typed_data';

import '../network/api_client.dart';
import 'downloads_io.dart'
    if (dart.library.js_interop) 'downloads_web.dart'
    as platform;

/// Where a saved file ended up, so the UI can tell the user exactly where
/// to find it instead of a bare "descargado".
class SavedDownload {
  const SavedDownload({
    required this.fileName,
    this.folder,
    this.inBrowserDownloads = false,
  });

  /// Final name on disk (the user may have renamed it in the dialog).
  final String fileName;

  /// Human-readable folder the user picked, or null when the platform
  /// doesn't reveal it (the web save picker never exposes paths).
  final String? folder;

  /// True when the browser saved it on its own (no save picker available),
  /// i.e. it went to the browser's downloads folder.
  final bool inBrowserDownloads;

  String get message {
    if (inBrowserDownloads) {
      return '«$fileName» se descargó en la carpeta de descargas de tu '
          'navegador.';
    }
    if (folder != null) return '«$fileName» guardado en $folder.';
    return '«$fileName» guardado en la ubicación que elegiste.';
  }
}

/// Thrown on web when the browser's save picker can't open because the
/// click that started the download is too old (the file took a while to
/// generate). The caller asks for a fresh click and retries.
class DownloadNeedsUserGesture implements Exception {
  const DownloadNeedsUserGesture();
}

/// Cross-platform "Guardar como" (§39, §56, §72): opens the platform's save
/// dialog so the user picks the folder and name, and reports where the file
/// went. On Android it's the system document picker; on web it's the
/// browser's save picker where supported, else a regular browser download.
/// Features never talk to platform file APIs directly.
class Downloads {
  Downloads._();

  /// Returns null if the user cancelled the dialog. With [browserFallback]
  /// on web, a missing click gesture degrades to a plain browser download
  /// instead of throwing [DownloadNeedsUserGesture].
  static Future<SavedDownload?> save(
    BinaryDownload download, {
    bool browserFallback = false,
  }) {
    final dotIndex = download.fileName.lastIndexOf('.');
    final extension = dotIndex > 0
        ? download.fileName.substring(dotIndex + 1).toLowerCase()
        : '';
    return platform.saveBytes(
      fileName: download.fileName,
      bytes: Uint8List.fromList(download.bytes),
      extension: extension,
      mimeType: _mimeTypeFor(extension, download.contentType),
      browserFallback: browserFallback,
    );
  }

  static String _mimeTypeFor(String extension, String? contentType) {
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'csv':
        return 'text/csv';
      case 'zip':
        return 'application/zip';
    }
    final type = contentType?.split(';').first.trim();
    return (type == null || type.isEmpty) ? 'application/octet-stream' : type;
  }
}
