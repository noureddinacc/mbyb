import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/book.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/book_provider.dart';
import '../../widgets/book_card.dart';

class MyPostsScreen extends ConsumerWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateProvider).value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (currentUser == null) return const Scaffold(body: Center(child: Text('يرجى تسجيل الدخول')));

    final postsAsync = ref.watch(myBooksProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'منشوراتي',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: postsAsync.when(
          data: (posts) {
            if (posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.library_books_outlined, 
                      size: 64, 
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[300]
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لم تقم بنشر أي كتاب بعد.',
                      style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return BookCard(book: posts[index]);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('خطأ في تحميل البيانات: $err')),
        ),
      ),
    );
  }
}
