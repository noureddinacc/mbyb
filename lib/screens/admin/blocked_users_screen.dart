import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../providers/service_providers.dart';
import '../../services/report_service.dart';
import '../../services/book_service.dart';
import '../../models/book.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final reportService = ReportService();
    final bookService = BookService();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المستخدمون المحظورون'),
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: authService.getBlockedUsers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'خطأ في تحميل قائمة المحظورين: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            final blockedUsers = snapshot.data ?? [];
            if (blockedUsers.isEmpty) {
              return const Center(
                child: Text('لا يوجد مستخدمون محظورون حالياً.'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: blockedUsers.length,
              itemBuilder: (context, index) {
                final user = blockedUsers[index];
                final uid = user['uid'] as String;
                final email = user['email'] as String?;
                
                String studentId = 'غير معروف';
                if (user['studentID'] != null && user['studentID'].toString().isNotEmpty) {
                  studentId = user['studentID'];
                } else if (email != null && email.isNotEmpty) {
                  studentId = email.split('@').first;
                } else {
                  studentId = uid;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: Text(
                      'الرقم الجامعي: $studentId',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('انقر لعرض سجل الشكاوى'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'سجل الشكاوى المقدمة ضد هذا المستخدم:',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                            const SizedBox(height: 8),
                            // Fetch reports for this specific user
                            StreamBuilder<List<BookModel>>(
                              stream: bookService.getBooksByPublisher(uid),
                              builder: (context, booksSnapshot) {
                                if (booksSnapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                
                                if (booksSnapshot.hasError) {
                                  final errorMsg = booksSnapshot.error.toString();
                                  if (errorMsg.contains('FAILED_PRECONDITION') || 
                                      errorMsg.contains('index')) {
                                    return const Text(
                                      'جاري بناء فهرس قاعدة البيانات... يرجى الانتظار بضع دقائق.',
                                      style: TextStyle(color: Colors.orange, fontSize: 12),
                                    );
                                  }
                                  return Text('خطأ في تحميل الكتب: ${booksSnapshot.error}');
                                }
                                
                                final userBooks = booksSnapshot.data ?? [];
                                final bookIds = userBooks.map((b) => b.id).toSet();

                                return StreamBuilder<List<Map<String, dynamic>>>(
                                  stream: reportService.getAllReports(),
                                  builder: (context, reportSnapshot) {
                                    if (reportSnapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator());
                                    }
                                    
                                    final allReports = reportSnapshot.data ?? [];
                                    final userReports = allReports.where((r) {
                                      if (r['targetType'] == 'user') {
                                        return r['targetId'] == uid;
                                      } else if (r['targetType'] == 'book') {
                                        return bookIds.contains(r['targetId']);
                                      }
                                      return false;
                                    }).toList();

                                    if (userReports.isEmpty) {
                                      return const Text('لا توجد تقارير مسجلة حالياً.');
                                    }

                                    return Column(
                                      children: userReports.map((report) {
                                        final date = (report['timestamp'] as dynamic)?.toDate() ?? DateTime.now();
                                        final targetTypeStr = report['targetType'] == 'user' ? 'شخصي' : 'إعلان كتاب';
                                        return ListTile(
                                          title: Text('${report['reason'] ?? 'بدون سبب'} ($targetTypeStr)'),
                                          subtitle: Text(DateFormat('yyyy/MM/dd hh:mm a').format(date)),
                                          dense: true,
                                        );
                                      }).toList(),
                                    );
                                  },
                                );
                              }
                            ),
                            const Divider(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('إلغاء الحظر'),
                                      content: Text('هل أنت متأكد من إلغاء حظر الطالب $studentId؟ سيتم استعادة وصوله وإعلاناته السابقة.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('إلغاء'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('إلغاء الحظر', style: TextStyle(color: Colors.green)),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    try {
                                      // 1. Unblock account
                                      await authService.unblockUser(uid);
                                      // 2. Restore books
                                      await bookService.unhideBooksByUserId(uid);
                                      
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('تم إلغاء حظر $studentId واستعادة إعلاناته.')),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('فشل في إلغاء الحظر: $e'), backgroundColor: Colors.red),
                                        );
                                      }
                                    }
                                  }
                                },
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text('إلغاء الحظر'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
