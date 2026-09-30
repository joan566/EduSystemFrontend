import '../state/list_state.dart';

/// Largest page the API serves; catalogs are read in pages of this size.
const int maxApiPageSize = 100;

/// Reads every page of a paginated endpoint, for resources the app needs
/// whole (catalogs: the classes, subjects, courses... of the teacher).
/// Page 0 alone is never assumed to be everything.
Future<List<T>> fetchAllPages<T>(
  Future<ApiPage<T>> Function(int page, int size) fetchPage, {
  int size = maxApiPageSize,
}) async {
  final items = <T>[];
  var page = 0;
  while (true) {
    final result = await fetchPage(page, size);
    items.addAll(result.content);
    page++;
    // An empty page also ends it, so a backend that miscounts
    // `totalPages` can't keep this looping.
    if (page >= result.totalPages || result.content.isEmpty) return items;
  }
}
