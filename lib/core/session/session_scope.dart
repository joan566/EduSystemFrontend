import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../events/domain_events.dart';

/// Owns everything private to one signed-in teacher: the domain providers
/// (and every cache inside them), the domain event bus and the navigation
/// stack (its own [GoRouter]).
///
/// Mount it with `key: ValueKey(user?.id)`. When the user changes (logout,
/// forced logout, account deletion, another teacher signing in) the key
/// changes, Flutter disposes this whole subtree and a new, empty one is
/// built. That disposal *is* the reset: no provider has to remember to
/// clear itself, and a response that arrives for a disposed provider is
/// dropped (see `SessionNotifier`).
class SessionScope extends StatefulWidget {
  const SessionScope({
    super.key,
    required this.providers,
    required this.createRouter,
    required this.builder,
  });

  /// The session-level providers, built fresh for every session. They may
  /// read [DomainEvents] (provided above them by this scope).
  final List<SingleChildWidget> Function() providers;

  /// A router of this session's own, so no route (and no page state) of a
  /// previous session survives into this one.
  final GoRouter Function() createRouter;

  final Widget Function(BuildContext context, GoRouter router) builder;

  @override
  State<SessionScope> createState() => _SessionScopeState();
}

class _SessionScopeState extends State<SessionScope>
    with WidgetsBindingObserver {
  final DomainEvents _events = DomainEvents();
  late final GoRouter _router = widget.createRouter();
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _pausedAt ??= DateTime.now();
      case AppLifecycleState.resumed:
        final pausedAt = _pausedAt;
        _pausedAt = null;
        if (pausedAt != null) {
          _events.publish(AppResumed(DateTime.now().difference(pausedAt)));
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // The providers below were disposed before this state (children
    // unmount first), so nothing listens to the bus any more.
    _events.close();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DomainEvents>.value(value: _events),
        ...widget.providers(),
      ],
      child: Builder(builder: (context) => widget.builder(context, _router)),
    );
  }
}
