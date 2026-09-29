import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'downloads.dart';

/// Android (and native desktop): the system "save as" dialog writes the
/// bytes to the location the user picks and hands back its path.
Future<SavedDownload?> saveBytes({
  required String fileName,
  required Uint8List bytes,
  required String extension,
  required String mimeType,
  required bool browserFallback,
}) async {
  final uri = await FilePicker.saveFile(
    fileName: fileName,
    bytes: bytes,
    mimeType: mimeType,
    dialogTitle: 'Guardar archivo',
    type: extension.isEmpty ? FileType.any : FileType.custom,
    allowedExtensions: extension.isEmpty ? null : [extension],
  );
  if (uri == null) return null;
  return describeSavedLocation(uri, fallbackName: fileName);
}

/// Turns what the picker returns into something a person recognizes. On
/// Android that's a document path such as
/// `/document/primary:Download/notas.xlsx`, which becomes
/// "Almacenamiento interno/Download". Providers that don't encode a path
/// (e.g. `msf:123`) leave the folder unknown.
SavedDownload describeSavedLocation(Uri uri, {required String fallbackName}) {
  var path = uri.scheme == 'file' ? uri.toFilePath() : uri.path;
  try {
    path = Uri.decodeFull(path);
  } catch (_) {
    // Already decoded.
  }

  final documentIndex = path.indexOf('/document/');
  if (documentIndex >= 0) {
    path = path.substring(documentIndex + '/document/'.length);
  }

  final String? readable;
  if (path.startsWith('raw:')) {
    readable = _friendlyAbsolute(path.substring(4));
  } else if (path.startsWith('primary:')) {
    readable = 'Almacenamiento interno/${path.substring(8)}';
  } else if (path.startsWith('home:')) {
    readable = 'Documentos/${path.substring(5)}';
  } else if (RegExp(r'^[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}:').hasMatch(path)) {
    readable = 'Tarjeta SD/${path.substring(path.indexOf(':') + 1)}';
  } else if (path.startsWith('/')) {
    readable = _friendlyAbsolute(path);
  } else {
    readable = null;
  }

  if (readable == null) return SavedDownload(fileName: fallbackName);
  final slash = readable.lastIndexOf('/');
  if (slash <= 0) return SavedDownload(fileName: readable);
  return SavedDownload(
    fileName: readable.substring(slash + 1),
    folder: readable.substring(0, slash),
  );
}

String _friendlyAbsolute(String path) {
  const internal = '/storage/emulated/0/';
  if (path.startsWith(internal)) {
    return 'Almacenamiento interno/${path.substring(internal.length)}';
  }
  return path;
}
