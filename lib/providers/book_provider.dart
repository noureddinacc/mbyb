import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import 'service_providers.dart';
import 'auth_provider.dart';

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

class PostTypeFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setFilter(String? value) => state = value;
}
final postTypeFilterProvider = NotifierProvider<PostTypeFilterNotifier, String?>(
  PostTypeFilterNotifier.new,
);

final availableBooksProvider = StreamProvider<List<BookModel>>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return Stream.value([]);
  
  final userProfile = ref.watch(userProfileProvider).value;
  final universityId = userProfile?['universityId'] as String?;
  final isMasterAdmin = authState.email == 'solosoulacc@tutamail.com';
  
  final bookService = ref.watch(bookServiceProvider);

  // Master admin sees everything, everyone else is strictly filtered by university
  if (isMasterAdmin) {
    return bookService.getAvailableBooks();
  }

  // If universityId hasn't loaded yet, return empty to avoid showing wrong data
  if (universityId == null || universityId.isEmpty) {
    return Stream.value([]);
  }

  return bookService.getAvailableBooksByUniversity(universityId);
});

final filteredBooksProvider = Provider<AsyncValue<List<BookModel>>>((ref) {
  final asyncBooks = ref.watch(availableBooksProvider);
  final facultyFilter = ref.watch(facultyFilterProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
  final postTypeFilter = ref.watch(postTypeFilterProvider);

  return asyncBooks.whenData((books) {
    if (facultyFilter == null && searchQuery.isEmpty && postTypeFilter == null) {
      return books;
    }

    return books.where((book) {
      final matchesFaculty = facultyFilter == null || book.faculty == facultyFilter;
      final matchesSearch = book.title.toLowerCase().contains(searchQuery) || 
                            book.author.toLowerCase().contains(searchQuery);
      final matchesPostType = postTypeFilter == null || book.postType == postTypeFilter;
      return matchesFaculty && matchesSearch && matchesPostType;
    }).toList();
  });
});

final universityBooksProvider = StreamProvider.family<List<BookModel>, String>((ref, universityId) {
  final bookService = ref.watch(bookServiceProvider);
  return bookService.getAvailableBooksByUniversity(universityId);
});

final myBooksProvider = StreamProvider<List<BookModel>>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return Stream.value([]);
  
  final bookService = ref.watch(bookServiceProvider);
  return bookService.getBooksByPublisher(authState.uid);
});
