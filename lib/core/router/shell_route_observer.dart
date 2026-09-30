import 'package:flutter/widgets.dart';

/// Observes the authenticated shell's navigator, so a page can tell when it
/// is shown again after the page pushed on top of it is popped (see
/// `SyncedDataState`). Only one session router is alive at a time, so a
/// single observer serves them all.
final RouteObserver<ModalRoute<void>> shellRouteObserver =
    RouteObserver<ModalRoute<void>>();
