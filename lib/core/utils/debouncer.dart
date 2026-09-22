import 'dart:async';

/// Debounces rapid calls (e.g. search-as-you-type) so only the last one
/// within [delay] actually runs. Used by every search field to avoid
/// firing an HTTP request per keystroke.
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 400)});

  final Duration delay;
  Timer? _timer;

  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
