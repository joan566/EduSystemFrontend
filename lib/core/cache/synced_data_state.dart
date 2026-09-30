import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../events/domain_events.dart';
import '../router/shell_route_observer.dart';

/// Keeps a screen's data present without re-reading what is already
/// cached. [ensureData] (a set of `ensure...` calls, which are no-ops for
/// fresh data) runs:
///
/// * after the first frame (entering the screen),
/// * when the screen is shown again after a page pushed on top of it is
///   popped ("volver"),
/// * after a domain event (a mutation somewhere made something stale),
///   while the screen is the visible one; a covered screen catches up when
///   it is shown again.
///
/// It never runs from `build`. Pull-to-refresh and "retry" call the
/// providers' `refresh...` methods directly instead.
mixin SyncedDataState<W extends StatefulWidget> on State<W>
    implements RouteAware {
  StreamSubscription<DomainEvent>? _events;
  ModalRoute<void>? _route;
  bool _scheduled = false;

  /// Ensures (never forces) everything this screen shows.
  void ensureData();

  @override
  void initState() {
    super.initState();
    scheduleEnsureData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _events ??= context.read<DomainEvents>().stream.listen(
      (_) => scheduleEnsureData(),
    );
    final route = ModalRoute.of(context);
    if (route != _route) {
      shellRouteObserver.unsubscribe(this);
      _route = route;
      if (route != null) shellRouteObserver.subscribe(this, route);
    }
  }

  /// Runs [ensureData] after the current frame (once, however many times
  /// it is requested within it).
  void scheduleEnsureData() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      // A screen covered by another page catches up in [didPopNext].
      if (_route != null && !_route!.isCurrent) return;
      ensureData();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void didPopNext() => scheduleEnsureData();

  @override
  void didPush() {}

  @override
  void didPop() {}

  @override
  void didPushNext() {}

  @override
  void dispose() {
    _events?.cancel();
    shellRouteObserver.unsubscribe(this);
    super.dispose();
  }
}
