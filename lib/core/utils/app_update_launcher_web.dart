import 'package:web/web.dart' as web;

/// Web: the hosting always serves the latest build, so updating is a reload.
bool get updateSupported => true;

Future<bool> openUpdate({
  required String packageName,
  required String overrideUrl,
}) async {
  web.window.location.reload();
  return true;
}
