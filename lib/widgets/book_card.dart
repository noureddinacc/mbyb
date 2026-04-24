import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/request.dart';
import '../utils/book_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/request_service.dart';
import '../services/book_service.dart';
import '../providers/auth_provider.dart';
import '../services/report_service.dart';

class BookCard extends ConsumerWidget {
  final BookModel book;

  const BookCard({super.key, required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final currentUser = authState.value;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (book.author.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'بواسطة ${book.author}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                        if (book.postType != 'request') ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 238, 238, 238),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 1.0),
                                  child: Icon(
                                    BookIcons.getConditionIcon(book.condition),
                                    size: 14,
                                    color: const Color.fromARGB(255, 77, 76, 76),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'الحالة: ${book.condition}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color.fromARGB(255, 77, 76, 76),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (book.faculty.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 238, 238, 238),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 1.0),
                                  child: Icon(
                                    Icons.school,
                                    size: 14,
                                    color: Color.fromARGB(255, 77, 76, 76),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    book.faculty,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color.fromARGB(255, 77, 76, 76),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (value) async {
                      if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => Directionality(
                            textDirection: TextDirection.rtl,
                            child: AlertDialog(
                              title: const Text('حذف المنشور'),
                              content: const Text(
                                'هل أنت متأكد أنك تريد حذف هذا المنشور؟',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('إلغاء'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text(
                                    'حذف',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );

                        if (confirm == true) {
                          try {
                            await BookService().deleteBook(book.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  const SnackBar(
                                    content: Text('تم حذف المنشور بنجاح'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: Text('خطأ في حذف المنشور: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                            }
                          }
                        }
                      } else if (value == 'report') {
                        final controller = TextEditingController();
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => Directionality(
                            textDirection: TextDirection.rtl,
                            child: AlertDialog(
                              title: const Text('الإبلاغ عن المنشور'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'يرجى وصف سبب الإبلاغ عن هذا المنشور:',
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: controller,
                                    maxLines: 3,
                                    decoration: const InputDecoration(
                                      hintText: 'أدخل التقرير...',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('إلغاء'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    if (controller.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(ctx)
                                        ..hideCurrentSnackBar()
                                        ..showSnackBar(
                                          const SnackBar(
                                            content: Text('يرجى إدخال سبب.'),
                                          ),
                                        );
                                      return;
                                    }
                                    Navigator.of(ctx).pop(true);
                                  },
                                  child: const Text(
                                    'إرسال التقرير',
                                    style: TextStyle(color: Colors.orange),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );

                        if (confirm == true && context.mounted) {
                          try {
                            final reportService = ReportService();
                            await reportService.submitReport(
                              reporterId: currentUser!.uid,
                              targetId: book.id,
                              targetType: 'book',
                              targetTitle: book.title,
                              reason: controller.text.trim(),
                            );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  const SnackBar(
                                    content: Text('تم إرسال التقرير بنجاح.'),
                                    backgroundColor: Colors.grey,
                                  ),
                                );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: Text('فشل إرسال التقرير: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                            }
                          }
                        }
                      }
                    },
                    itemBuilder: (context) {
                      if (currentUser != null &&
                          currentUser.uid == book.publisherId) {
                        return [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'حذف',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ];
                      } else {
                        return [
                          const PopupMenuItem(
                            value: 'report',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.flag,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'إبلاغ',
                                  style: TextStyle(color: Colors.orange),
                                ),
                              ],
                            ),
                          ),
                        ];
                      }
                    },
                  ),
                ],
              ),
              if (book.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 147, 205, 247),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الوصف :',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.description,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
              if (book.postType == 'exchange' && book.exchangeDetails != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(81, 3, 222, 39),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ابحث عن :',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.exchangeDetails!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ] else if (book.postType == 'request') ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'مطلوب',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.purple[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ] else if (book.postType == 'free') ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'مجاني',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child:
                    currentUser == null || currentUser.uid == book.publisherId
                    ? ElevatedButton.icon(
                        onPressed: null,
                        icon: Icon(book.postType == 'request' ? Icons.check_circle : Icons.send),
                        label: Text(book.postType == 'request' ? 'لدي هذا الكتاب' : 'طلب'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                      )
                    : StreamBuilder<RequestModel?>(
                        stream: RequestService().getMyRequestForBook(
                          book.id,
                          currentUser.uid,
                        ),
                        builder: (context, snapshot) {
                          final hasRequested = snapshot.data != null;

                          return ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                final requestService = RequestService();
                                if (hasRequested) {
                                  await requestService.cancelRequest(
                                    snapshot.data!.id,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        const SnackBar(
                                          content: Text('تم إلغاء الطلب.'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                  }
                                } else {
                                  await requestService.sendRequest(
                                    bookId: book.id,
                                    bookTitle: book.title,
                                    publisherId: book.publisherId,
                                    requesterId: currentUser.uid,
                                    requesterStudentId:
                                        currentUser.email?.split('@')[0] ??
                                        'Unknown',
                                    postType: book.postType,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'تم إرسال الطلب بنجاح!',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(
                                        content: Text('خطأ: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                }
                              }
                            },
                            icon: Icon(
                              hasRequested ? Icons.cancel : (book.postType == 'request' ? Icons.check_circle : Icons.send),
                            ),
                            label: Text(hasRequested ? 'إلغاء الطلب' : (book.postType == 'request' ? 'لدي هذا الكتاب' : 'طلب')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hasRequested
                                  ? Colors.orange
                                  : Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
