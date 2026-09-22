import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';

import '../network/api_client.dart';

/// Cross-platform "save this file" helper (§39, §56, §72): on Android it
/// writes to device storage, on web it triggers a browser download. Wraps
/// `file_saver` so features never talk to platform file APIs directly.
class Downloads {
  Downloads._();

  static Future<void> save(BinaryDownload download) async {
    final dotIndex = download.fileName.lastIndexOf('.');
    final hasExtension = dotIndex > 0;
    final baseName = hasExtension ? download.fileName.substring(0, dotIndex) : download.fileName;
    final extension = hasExtension ? download.fileName.substring(dotIndex + 1) : '';

    await FileSaver.instance.saveFile(
      name: baseName,
      bytes: Uint8List.fromList(download.bytes),
      fileExtension: extension,
      mimeType: _mimeTypeFor(extension),
    );
  }

  static MimeType _mimeTypeFor(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return MimeType.pdf;
      case 'xlsx':
        return MimeType.microsoftExcel;
      default:
        return MimeType.other;
    }
  }
}
