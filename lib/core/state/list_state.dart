import '../errors/app_exception.dart';

enum ViewStatus { initial, loading, success, empty, error }

/// Shared shape for any paginated/listing screen's state (§12, §101):
/// Initial / Loading / Success / Empty / Error, plus the `[PAGE]` envelope
/// fields the backend returns. Every list-oriented provider composes this
/// instead of re-deriving the same five states from scratch.
class ListViewState<T> {
  const ListViewState({
    this.status = ViewStatus.initial,
    this.items = const [],
    this.error,
    this.page = 0,
    this.totalPages = 0,
    this.totalElements = 0,
  });

  final ViewStatus status;
  final List<T> items;
  final AppException? error;
  final int page;
  final int totalPages;
  final int totalElements;

  bool get isLoading => status == ViewStatus.loading;

  ListViewState<T> copyWith({
    ViewStatus? status,
    List<T>? items,
    AppException? error,
    int? page,
    int? totalPages,
    int? totalElements,
  }) {
    return ListViewState<T>(
      status: status ?? this.status,
      items: items ?? this.items,
      error: error,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      totalElements: totalElements ?? this.totalElements,
    );
  }

  factory ListViewState.loading() => const ListViewState(status: ViewStatus.loading);

  factory ListViewState.fromPage({
    required List<T> content,
    required int page,
    required int totalPages,
    required int totalElements,
  }) {
    return ListViewState<T>(
      status: content.isEmpty ? ViewStatus.empty : ViewStatus.success,
      items: content,
      page: page,
      totalPages: totalPages,
      totalElements: totalElements,
    );
  }

  factory ListViewState.list(List<T> content) => ListViewState<T>(
    status: content.isEmpty ? ViewStatus.empty : ViewStatus.success,
    items: content,
    totalElements: content.length,
    totalPages: 1,
  );

  factory ListViewState.error(AppException error) =>
      ListViewState<T>(status: ViewStatus.error, error: error);
}

/// A single generic parsed page, mirroring the backend's `[PAGE]` envelope:
/// `{ content, page, size, totalElements, totalPages }`.
class ApiPage<T> {
  const ApiPage({
    required this.content,
    required this.page,
    required this.totalPages,
    required this.totalElements,
  });

  final List<T> content;
  final int page;
  final int totalPages;
  final int totalElements;

  factory ApiPage.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return ApiPage<T>(
      content: (json['content'] as List<dynamic>)
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int,
      totalPages: json['totalPages'] as int,
      totalElements: json['totalElements'] as int,
    );
  }
}
