import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/book_provider.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/book_card.dart';
import '../../widgets/shimmer_loading.dart';

const List<String> faculties = [
  'كلية الآداب والعلوم الإنسانية',
  'كلية العلوم',
  'كلية الشريعة',
  'كلية الهندسة',
  'كلية الأمير الحسين بن عبدالله لتكنولوجيا المعلومات',
  'كلية الاقتصاد والعلوم الإدارية',
  'كلية الحقوق',
  'كلية العلوم التربوية',
  'كلية الأميرة سلمى للتمريض',
  'كلية اللغات الأجنبية',
  'كلية علوم الطيران',
  'كلية التربية البدنية وعلوم الرياضة',
  'كلية العلوم الطبية التطبيقية',
  'كلية التعليم الفني',
];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {



  @override
  Widget build(BuildContext context) {
    final filteredBooksAsync = ref.watch(filteredBooksProvider);
    final selectedFaculty = ref.watch(facultyFilterProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Expanded(
              child: filteredBooksAsync.when(
                data: (books) {
                  if (books.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.book,
                      message:
                          selectedFaculty == null &&
                              ref.read(searchQueryProvider).isEmpty
                          ? 'لا توجد كتب متاحة بعد'
                          : 'لا توجد كتب تطابق بحثك',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      return BookCard(book: books[index]);
                    },
                  );
                },
                loading: () {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 4,
                    itemBuilder: (context, index) => const BookCardSkeleton(),
                  );
                },
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
