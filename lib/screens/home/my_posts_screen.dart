import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/book.dart';
import '../../providers/book_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/book_card.dart';

class MyPostsScreen extends ConsumerWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateProvider).value;
    final allBooks = ref.watch(availableBooksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('منشوراتي')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: allBooks.when(
          data: (books) {
            final myBooks = books.where((b) => b.publisherId == currentUser?.uid).toList();
            if (myBooks.isEmpty) {
              return const Center(child: Text('لم تقم بنشر أي كتب بعد.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myBooks.length,
              itemBuilder: (context, index) => BookCard(book: myBooks[index]),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}
