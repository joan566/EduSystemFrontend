import 'list_state.dart';

/// Keeps the last listing a screen showed while another query of the same
/// listing loads (the next server page, a new search or filter), so paging
/// never blanks the list into a skeleton: the previous rows stay, marked as
/// [KeptListingView.updating], until the new answer replaces them.
///
/// Owned by the page entry point (like its page/filters). A skeleton is
/// only shown when there is nothing to keep yet.
class KeptListing<T> {
  ListViewState<T>? _last;

  KeptListingView<T> resolve(ListViewState<T> current) {
    switch (current.status) {
      case ViewStatus.success:
      case ViewStatus.empty:
        _last = current;
        return (state: current, updating: false);
      case ViewStatus.initial:
      case ViewStatus.loading:
        final last = _last;
        return last == null
            ? (state: current, updating: false)
            : (state: last, updating: true);
      case ViewStatus.error:
        return (state: current, updating: false);
    }
  }
}

typedef KeptListingView<T> = ({ListViewState<T> state, bool updating});
