import '../state/list_state.dart';
import 'cached_value.dart';

/// A whole catalog of the teacher (levels, subjects, courses, classes...)
/// held for the session: read once (every page), then filtered, paged and
/// kept in step with mutations locally, in the server's own order.
class Catalog<E> {
  Catalog(
    this._value, {
    required this.idOf,
    required Future<List<E>> Function() fetch,
    this.compare,
  }) : _fetch = fetch;

  final CachedValue<List<E>> _value;
  final int Function(E item) idOf;
  final Future<List<E>> Function() _fetch;

  /// The server's sort, applied after local inserts and updates. Null keeps
  /// the server order and appends new items.
  final int Function(E a, E b)? compare;

  /// Every item (empty until loaded).
  List<E> get items => _value.data ?? const [];
  bool get isLoaded => _value.hasData;
  bool get isLoading => _value.isLoading;

  /// The whole catalog as a screen state.
  ListViewState<E> get view => _value.view;

  /// One page of the items matching [where], paged in memory.
  ListViewState<E> page({
    bool Function(E item)? where,
    int page = 0,
    int size = 20,
  }) => _value.listView(
    (items) => localPage(
      where == null ? items : items.where(where).toList(),
      page: page,
      size: size,
    ),
  );

  /// Every item matching [where] as a single-page screen state.
  ListViewState<E> filtered(bool Function(E item) where) => _value.listView(
    (items) => ListViewState.list(items.where(where).toList()),
  );

  E? byId(int id) {
    for (final item in items) {
      if (idOf(item) == id) return item;
    }
    return null;
  }

  Future<void> ensure() => _value.ensure(_fetch);
  Future<void> refresh() => _value.refresh(_fetch);
  void invalidate() => _value.invalidate();

  /// Inserts or replaces [item] (the backend's answer to a POST/PUT).
  void upsert(E item) => _value.update((items) {
    final id = idOf(item);
    final index = items.indexWhere((e) => idOf(e) == id);
    final next = [...items];
    if (index == -1) {
      next.add(item);
    } else {
      next[index] = item;
    }
    if (compare != null) next.sort(compare);
    return next;
  });

  /// Patches the item with [id], if loaded.
  void patch(int id, E Function(E item) change) => _value.update(
    (items) => [for (final e in items) idOf(e) == id ? change(e) : e],
  );

  /// Removes the item with [id] (after a DELETE).
  void remove(int id) =>
      _value.update((items) => items.where((e) => idOf(e) != id).toList());
}
