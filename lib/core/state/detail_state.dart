import '../errors/app_exception.dart';

enum DetailStatus { initial, loading, success, error }

/// Shared shape for a single-entity fetch (student detail, exam detail,
/// submission detail, ...). See [ListViewState] for the listing analog.
class DetailViewState<T> {
  const DetailViewState({this.status = DetailStatus.initial, this.data, this.error});

  final DetailStatus status;
  final T? data;
  final AppException? error;

  bool get isLoading => status == DetailStatus.loading;

  factory DetailViewState.loading() => const DetailViewState(status: DetailStatus.loading);

  factory DetailViewState.success(T data) =>
      DetailViewState<T>(status: DetailStatus.success, data: data);

  factory DetailViewState.error(AppException error) =>
      DetailViewState<T>(status: DetailStatus.error, error: error);
}
