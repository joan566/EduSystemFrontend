import 'package:edusistem_front/core/errors/app_exception.dart';
import 'package:edusistem_front/core/state/kept_listing.dart';
import 'package:edusistem_front/core/state/list_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nothing to keep yet: the loading state passes through', () {
    final listing = KeptListing<int>();
    final view = listing.resolve(ListViewState<int>.loading());

    expect(view.state.status, ViewStatus.loading);
    expect(view.updating, isFalse);
  });

  test('the previous page stays, marked updating, while the next loads', () {
    final listing = KeptListing<int>();
    final first = ListViewState<int>.list([1, 2, 3]);
    listing.resolve(first);

    final view = listing.resolve(ListViewState<int>.loading());
    expect(view.state, same(first));
    expect(view.updating, isTrue);

    final next = ListViewState<int>.list([4, 5]);
    final settled = listing.resolve(next);
    expect(settled.state, same(next));
    expect(settled.updating, isFalse);
  });

  test('an error is shown, not hidden behind the previous rows', () {
    final listing = KeptListing<int>()..resolve(ListViewState<int>.list([1]));
    const error = AppException(code: AppErrorCode.network, message: 'x');

    final view = listing.resolve(ListViewState<int>.error(error));
    expect(view.state.status, ViewStatus.error);
    expect(view.updating, isFalse);
  });
}
