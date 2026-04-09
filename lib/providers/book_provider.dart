import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import 'service_providers.dart';

class FacultyFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setFilter(String? value) => state = value;
}
final facultyFilterProvider = NotifierProvider<FacultyFilterNotifier, String?>(
  FacultyFilterNotifier.new,
);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String value) => state = value;
}
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

final availableBooksProvider = StreamProvider<List<BookModel>>((ref) {
  final bookService = ref.watch(bookServiceProvider);
  return bookService.getAvailableBooks();
});

final filteredBooksProvider = Provider<AsyncValue<List<BookModel>>>((ref) {
  final asyncBooks = ref.watch(availableBooksProvider);
  final facultyFilter = ref.watch(facultyFilterProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();

  return asyncBooks.whenData((books) {
    if (facultyFilter == null && searchQuery.isEmpty) {
      return books;
    }

    return books.where((book) {
      final matchesFaculty = facultyFilter == null || book.faculty == facultyFilter;
      final matchesSearch = book.title.toLowerCase().contains(searchQuery) || 
                            book.author.toLowerCase().contains(searchQuery);
      return matchesFaculty && matchesSearch;
    }).toList();
  });
});
