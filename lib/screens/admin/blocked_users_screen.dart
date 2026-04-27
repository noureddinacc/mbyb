import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../providers/service_providers.dart';
import '../../services/report_service.dart';
import '../../services/book_service.dart';
import '../../models/book.dart';
import '../../providers/auth_provider.dart';


class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final reportService = ReportService();
    final bookService = BookService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final userProfileAsync = ref.watch(userProfileProvider);
    
    return userProfileAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (userProfile) {
        final universityId = userProfile?['universityId'];
        if (universityId == null) {
          return const Scaffold(
            body: Center(
              child: Text('لا يمكن تحميل التقارير بدون معرف الجامعة.', style: TextStyle(color: Colors.red)),
            ),
          );
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('المستخدمون المحظورون'),
            ),
            body: StreamBuilder<List<Map<String, dynamic>>>(
              stream: ref.watch(authStateProvider).value?.email == 'solosoulacc@tutamail.com'
                  ? authService.getBlockedUsers()
                  : authService.getBlockedUsersByUniversity(universityId),
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
                    child: Text('لا يوجد مستخدمون محظورون حالياً.', style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: blockedUsers.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
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

                    return Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200]!),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          iconColor: isDark ? Colors.teal[300] : Colors.teal,
                          title: Text(
                            'الرقم الجامعي: $studentId',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            'انقر لعرض سجل الشكاوى',
                            style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600], fontSize: 12),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'سجل الشكاوى المقدمة ضد هذا المستخدم:',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                                  ),
                                  const SizedBox(height: 8),
                                  StreamBuilder<List<BookModel>>(
                                    stream: bookService.getBooksByPublisher(uid),
                                    builder: (context, booksSnapshot) {
                                      if (booksSnapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(child: CircularProgressIndicator());
                                      }
                                      
                                      final userBooks = booksSnapshot.data ?? [];
                                      final bookIds = userBooks.map((b) => b.id).toSet();

                                      return StreamBuilder<List<Map<String, dynamic>>>(
                                        stream: reportService.getReportsByUniversity(universityId),
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
                                            return const Text('لا توجد تقارير مسجلة حالياً.', style: TextStyle(color: Colors.grey));
                                          }

                                          return Column(
                                            children: userReports.map((report) {
                                              final date = (report['timestamp'] as dynamic)?.toDate() ?? DateTime.now();
                                              final targetTypeStr = report['targetType'] == 'user' ? 'شخصي' : 'إعلان كتاب';
                                              return ListTile(
                                                title: Text(
                                                  '${report['reason'] ?? 'بدون سبب'} ($targetTypeStr)',
                                                  style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black87, fontSize: 13),
                                                ),
                                                subtitle: Text(
                                                  DateFormat('yyyy/MM/dd hh:mm a').format(date),
                                                  style: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[500], fontSize: 11),
                                                ),
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
                                            await authService.unblockUser(uid);
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
                                      icon: const Icon(Icons.check_circle_outline, size: 18),
                                      label: const Text('إلغاء الحظر', style: TextStyle(fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isDark ? Colors.green[900]!.withValues(alpha: 0.3) : Colors.green[50],
                                        foregroundColor: isDark ? Colors.green[300] : Colors.green[700],
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: BorderSide(color: isDark ? Colors.green[800]! : Colors.green[200]!),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );

  }
}
