import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Native: only Android has an update channel (Google Play).
bool get updateSupported =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

Future<bool> openUpdate({
  required String packageName,
  required String overrideUrl,
}) async {
  final candidates = overrideUrl.isNotEmpty
      ? [Uri.parse(overrideUrl)]
      : [
          // The Play Store app; the web listing when it isn't installed.
          Uri(scheme: 'market', host: 'details', queryParameters: {
            'id': packageName,
          }),
          Uri.https('play.google.com', '/store/apps/details', {
            'id': packageName,
          }),
        ];
  for (final uri in candidates) {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return true;
      }
    } catch (e) {
      debugPrint('[AppVersion] could not open $uri: $e');
    }
  }
  return false;
}
