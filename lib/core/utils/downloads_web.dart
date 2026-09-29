import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'downloads.dart';

/// Web: the File System Access save picker (Chrome, Edge, Opera) lets the
/// user choose folder and name. Browsers without it (Firefox, Safari) get a
/// regular download into their downloads folder. The browser never reveals
/// the chosen folder, only the final file name.
Future<SavedDownload?> saveBytes({
  required String fileName,
  required Uint8List bytes,
  required String extension,
  required String mimeType,
  required bool browserFallback,
}) async {
  if (!web.window.has('showSaveFilePicker')) {
    return _browserDownload(fileName, bytes, mimeType);
  }
  // The picker needs a recent click; a slow export outlives it.
  if (!web.window.navigator.userActivation.isActive) {
    if (browserFallback) return _browserDownload(fileName, bytes, mimeType);
    throw const DownloadNeedsUserGesture();
  }

  final _FileHandle handle;
  try {
    handle = await _showSaveFilePicker(
      _pickerOptions(fileName, extension, mimeType),
    ).toDart;
  } catch (e) {
    final error = e.toString();
    if (error.contains('AbortError')) return null;
    if (error.contains('SecurityError') || error.contains('NotAllowedError')) {
      if (browserFallback) return _browserDownload(fileName, bytes, mimeType);
      throw const DownloadNeedsUserGesture();
    }
    rethrow;
  }

  final writable = await handle.createWritable().toDart;
  await writable.write(bytes.toJS).toDart;
  await writable.close().toDart;
  return SavedDownload(fileName: handle.name);
}

SavedDownload _browserDownload(
  String fileName,
  Uint8List bytes,
  String mimeType,
) {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..click();
  // Revoking right away can cancel the download in some browsers.
  Timer(const Duration(minutes: 1), () => web.URL.revokeObjectURL(url));
  return SavedDownload(fileName: fileName, inBrowserDownloads: true);
}

_SaveFilePickerOptions _pickerOptions(
  String fileName,
  String extension,
  String mimeType,
) {
  if (extension.isEmpty || mimeType == 'application/octet-stream') {
    return _SaveFilePickerOptions(suggestedName: fileName.toJS);
  }
  final accept = JSObject()..[mimeType] = ['.$extension'.toJS].toJS;
  return _SaveFilePickerOptions(
    suggestedName: fileName.toJS,
    types: [
      _FilePickerAcceptType(
        description: extension.toUpperCase().toJS,
        accept: accept,
      ),
    ].toJS,
  );
}

@JS('showSaveFilePicker')
external JSPromise<_FileHandle> _showSaveFilePicker(
  _SaveFilePickerOptions options,
);

extension type _SaveFilePickerOptions._(JSObject _) implements JSObject {
  external factory _SaveFilePickerOptions({
    JSString suggestedName,
    JSArray<_FilePickerAcceptType> types,
  });
}

extension type _FilePickerAcceptType._(JSObject _) implements JSObject {
  external factory _FilePickerAcceptType({
    JSString description,
    JSObject accept,
  });
}

extension type _FileHandle._(JSObject _) implements JSObject {
  external String get name;
  external JSPromise<_Writable> createWritable();
}

extension type _Writable._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> write(JSAny data);
  external JSPromise<JSAny?> close();
}
