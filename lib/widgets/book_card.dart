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

  Widget _buildBadge(BookModel book) {
    Color bgColor;
    Color textColor;
    String text;

    if (book.postType == 'request') {
      bgColor = Colors.purple[50]!;
      textColor = Colors.purple[700]!;
      text = 'مطلوب';
    } else if (book.postType == 'free') {
      bgColor = Colors.green[50]!;
      textColor = Colors.green[700]!;
      text = 'مجاني';
    } else {
      bgColor = Colors.blue[50]!;
      textColor = Colors.blue[700]!;
      text = 'تبادل';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildMetaTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey[800]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final currentUser = authState.value;
    
    return Column(
      children: [
        Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Title, Author, Menu
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
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (book.author.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'بواسطة ${book.author}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz, color: Colors.grey),
                      splashRadius: 20,
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
                
                const SizedBox(height: 12),
                
                // Meta Tags (Type, Faculty, Condition) - Stacked vertically
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBadge(book),
                    if (book.faculty.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildMetaTag(Icons.school, book.faculty),
                    ],
                    if (book.postType != 'request') ...[
                      const SizedBox(height: 8),
                      _buildMetaTag(BookIcons.getConditionIcon(book.condition), book.condition),
                    ],
                  ],
                ),

                // Description
                if (book.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    book.description,
                    style: const TextStyle(
                      fontSize: 14, 
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],

                // Exchange Details Box
                if (book.postType == 'exchange' && book.exchangeDetails != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.swap_horiz, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ابحث عن:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                book.exchangeDetails!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Only show Action Button if user is NOT the publisher
                if (currentUser != null && currentUser.uid != book.publisherId) ...[
                  const SizedBox(height: 16),
                  StreamBuilder<RequestModel?>(
                    stream: RequestService().getMyRequestForBook(
                      book.id,
                      currentUser.uid,
                    ),
                    builder: (context, snapshot) {
                      final hasRequested = snapshot.data != null;
                      final isRequestPost = book.postType == 'request';

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
                          hasRequested 
                              ? Icons.cancel_outlined 
                              : (isRequestPost ? Icons.check_circle_outline : Icons.send_outlined),
                          size: 16,
                        ),
                        label: Text(
                          hasRequested 
                              ? 'إلغاء الطلب' 
                              : (isRequestPost ? 'لدي هذا الكتاب' : 'طلب'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          elevation: 0, // Flat design
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          backgroundColor: hasRequested
                              ? Colors.orange[50]
                              : Colors.green[50],
                          foregroundColor: hasRequested
                              ? Colors.orange[700]
                              : Colors.green[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: hasRequested ? Colors.orange[200]! : Colors.green[200]!,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: Colors.grey[200]),
      ],
    );
  }
}
