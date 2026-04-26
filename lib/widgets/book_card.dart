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

  Widget _buildBadge(BuildContext context, BookModel book) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor;
    Color textColor;
    String text;

    if (book.postType == 'request') {
      bgColor = isDark ? Colors.purple[900]!.withValues(alpha: 0.3) : Colors.purple[50]!;
      textColor = isDark ? Colors.purple[200]! : Colors.purple[700]!;
      text = 'مطلوب';
    } else if (book.postType == 'free') {
      bgColor = isDark ? Colors.green[900]!.withValues(alpha: 0.3) : Colors.green[50]!;
      textColor = isDark ? Colors.green[200]! : Colors.green[700]!;
      text = 'مجاني';
    } else {
      bgColor = isDark ? Colors.blue[900]!.withValues(alpha: 0.3) : Colors.blue[50]!;
      textColor = isDark ? Colors.blue[200]! : Colors.blue[700]!;
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

  Widget _buildMetaTag(BuildContext context, IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12, 
              color: isDark ? Colors.grey[300] : Colors.grey[800], 
              fontWeight: FontWeight.w500
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final currentUser = authState.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: isDark ? Colors.white : Colors.black,
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
                                color: isDark ? Colors.grey[500] : Colors.grey[500],
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
                        if (value == 'report') {
                          final controller = TextEditingController();
                          final isDark = Theme.of(context).brightness == Brightness.dark;
                          showDialog(
                            context: context,
                            builder: (ctx) => Directionality(
                              textDirection: TextDirection.rtl,
                              child: AlertDialog(
                                backgroundColor: isDark ? const Color(0xFF1A1D1E) : Colors.white,
                                title: Text('إبلاغ عن هذا المنشور', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('يرجى توضيح سبب الإبلاغ:', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.black87)),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: controller,
                                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                      decoration: InputDecoration(
                                        hintText: 'مثلاً: محتوى غير لائق، معلومات خاطئة...',
                                        hintStyle: TextStyle(color: isDark ? Colors.grey[700] : Colors.grey[400]),
                                        filled: true,
                                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                                  TextButton(
                                    onPressed: () async {
                                      if (controller.text.isNotEmpty) {
                                        await ReportService().submitReport(
                                          reporterId: currentUser!.uid,
                                          targetId: book.id,
                                          targetType: 'book',
                                          targetTitle: book.title,
                                          reason: controller.text,
                                        );
                                        if (context.mounted) {
                                          Navigator.pop(ctx);
                                          ScaffoldMessenger.of(context).clearSnackBars();
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الإبلاغ. شكراً لمساهمتك.')));
                                        }
                                      }
                                    },
                                    child: const Text('إرسال', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else if (value == 'delete') {
                          final isDark = Theme.of(context).brightness == Brightness.dark;
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => Directionality(
                              textDirection: TextDirection.rtl,
                              child: AlertDialog(
                                backgroundColor: isDark ? const Color(0xFF1A1D1E) : Colors.white,
                                title: Text('حذف المنشور', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                                content: Text('هل أنت متأكد من حذف هذا الكتاب؟ لا يمكن التراجع عن هذا الإجراء.', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.black87)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('حذف', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          );
                          if (confirm == true) {
                            await BookService().deleteBook(book.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المنشور بنجاح.')));
                            }
                          }
                        }
                      },
                      itemBuilder: (context) {
                        if (currentUser != null && currentUser.uid == book.publisherId) {
                          return [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(children: [Icon(Icons.delete_outline, color: Colors.red, size: 20), SizedBox(width: 8), Text('حذف', style: TextStyle(color: Colors.red))]),
                            ),
                          ];
                        } else {
                          return [
                            const PopupMenuItem(
                              value: 'report',
                              child: Row(children: [Icon(Icons.flag_outlined, color: Colors.orange, size: 20), SizedBox(width: 8), Text('إبلاغ', style: TextStyle(color: Colors.orange))]),
                            ),
                          ];
                        }
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Meta Tags
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBadge(context, book),
                    if (book.faculty.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildMetaTag(context, Icons.school_outlined, book.faculty),
                    ],
                    if (book.postType != 'request') ...[
                      const SizedBox(height: 8),
                      _buildMetaTag(context, BookIcons.getConditionIcon(book.condition), book.condition),
                    ],
                  ],
                ),

                // Description
                if (book.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    book.description,
                    style: TextStyle(
                      fontSize: 14, 
                      color: isDark ? Colors.grey[400] : Colors.grey[800], 
                      height: 1.5
                    ),
                  ),
                ],

                // Exchange Details Box
                if (book.postType == 'exchange' && book.exchangeDetails != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.blue[900]!.withValues(alpha: 0.2) : Colors.blue[50],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.swap_horiz, color: isDark ? Colors.blue[300] : Colors.blue[700], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'مطلوب للتبادل:', 
                                style: TextStyle(
                                  fontSize: 11, 
                                  fontWeight: FontWeight.bold, 
                                  color: isDark ? Colors.blue[200] : Colors.blue[800]
                                )
                              ),
                              Text(
                                book.exchangeDetails!, 
                                style: TextStyle(
                                  fontSize: 13, 
                                  color: isDark ? Colors.white : Colors.blue[900]
                                )
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action Area
                if (currentUser != null && currentUser.uid != book.publisherId) ...[
                  const SizedBox(height: 20),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: StreamBuilder<RequestModel?>(
                      stream: RequestService().getMyRequestForBook(book.id, currentUser.uid),
                      builder: (context, snapshot) {
                        final hasRequested = snapshot.data != null;
                        final isRequestPost = book.postType == 'request';

                        return ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final requestService = RequestService();
                              if (hasRequested) {
                                await requestService.cancelRequest(snapshot.data!.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إلغاء الطلب.'), backgroundColor: Colors.orange));
                                }
                              } else {
                                await requestService.sendRequest(
                                  bookId: book.id,
                                  bookTitle: book.title,
                                  publisherId: book.publisherId,
                                  requesterId: currentUser.uid,
                                  requesterStudentId: currentUser.email?.split('@')[0] ?? 'Unknown',
                                  postType: book.postType,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الطلب بنجاح!'), backgroundColor: Colors.green));
                                }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
                              }
                            }
                          },
                          icon: Icon(
                            hasRequested 
                                ? Icons.cancel_outlined 
                                : (isRequestPost ? Icons.volunteer_activism_outlined : Icons.archive),
                            size: 16,
                          ),
                          label: Text(
                            hasRequested ? 'إلغاء الطلب' : (isRequestPost ? 'لدي هذا الكتاب' : 'اطلب الكتاب'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            backgroundColor: hasRequested 
                                ? (isDark ? Colors.orange[900]!.withValues(alpha: 0.3) : Colors.orange[50])
                                : (isRequestPost 
                                    ? (isDark ? Colors.purple[900]!.withValues(alpha: 0.3) : Colors.purple[50])
                                    : (isDark ? Colors.green[900]!.withValues(alpha: 0.3) : Colors.green[50])),
                            foregroundColor: hasRequested 
                                ? (isDark ? Colors.orange[300] : Colors.orange[700])
                                : (isRequestPost 
                                    ? (isDark ? Colors.purple[300] : Colors.purple[700])
                                    : (isDark ? Colors.green[300] : Colors.green[700])),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: hasRequested 
                                    ? (isDark ? Colors.orange[800]! : Colors.orange[200]!) 
                                    : (isRequestPost 
                                        ? (isDark ? Colors.purple[800]! : Colors.purple[200]!)
                                        : (isDark ? Colors.green[800]! : Colors.green[200]!)),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100]),
      ],
    );
  }
}
