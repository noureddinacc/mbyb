import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../services/report_service.dart';
import '../../services/book_service.dart';
import '../../services/auth_service.dart';
import '../../models/book.dart';
import '../../models/chat_message.dart';
import '../../providers/service_providers.dart';
import 'blocked_users_screen.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  void _showChatHistoryDialog(
    BuildContext context,
    WidgetRef ref,
    String chatId,
  ) {
    final chatService = ref.read(chatServiceProvider);
    final authService = ref.read(authServiceProvider);

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('سجل الدردشة (آخر 20 رسالة)'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: StreamBuilder<List<ChatMessage>>(
              stream: chatService.getChatMessages(chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('لا توجد رسائل في هذه المحادثة.'),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: messages.length > 20 ? 20 : messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return FutureBuilder<String?>(
                      future: authService.getStudentIdFromUid(msg.senderId),
                      builder: (context, userSnapshot) {
                        final senderId = userSnapshot.data ?? msg.senderId;
                        return ListTile(
                          title: Text(
                            senderId,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          subtitle: Text(msg.text),
                          trailing: Text(
                            DateFormat('HH:mm').format(msg.sentAt),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSendMessageDialog(
    BuildContext context,
    WidgetRef ref,
    String recipientId,
    String studentId,
  ) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('إرسال رسالة إلى $studentId'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'اكتب رسالتك هنا...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final message = controller.text.trim();
                if (message.isEmpty) return;

                try {
                  await ref
                      .read(systemMessageServiceProvider)
                      .sendAdminMessage(
                        recipientId: recipientId,
                        message: message,
                      );

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إرسال الرسالة بنجاح.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('فشل في إرسال الرسالة: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('إرسال'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBroadcastDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('بث تعميم لجميع الطلاب'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'سيتم إرسال هذه الرسالة إلى جميع المسجلين في التطبيق (صندوق الرسائل الواردة).',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'اكتب التعميم هنا...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final message = controller.text.trim();
                if (message.isEmpty) return;

                // Final confirmation
                final confirm = await showDialog<bool>(
                  context: ctx,
                  builder: (confirmCtx) => AlertDialog(
                    title: const Text('تأكيد الإرسال'),
                    content: const Text(
                      'هل أنت متأكد من رغبتك في إرسال هذا التعميم للجميع؟',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(confirmCtx, false),
                        child: const Text('تراجع'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(confirmCtx, true),
                        child: const Text('نعم، أرسل للكل'),
                      ),
                    ],
                  ),
                );

                if (confirm != true) return;

                if (context.mounted) {
                  // Show progress indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (loadingCtx) =>
                        const Center(child: CircularProgressIndicator()),
                  );
                }

                try {
                  await ref
                      .read(systemMessageServiceProvider)
                      .broadcastMessage(message: message);

                  if (context.mounted) {
                    Navigator.pop(context); // Close loading
                    Navigator.pop(ctx); // Close dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم إرسال التعميم بنجاح لجميع الطلاب.'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // Close loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('فشل في إرسال التعميم: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900],
                foregroundColor: Colors.white,
              ),
              child: const Text('بث للجميع'),
            ),
          ],
        ),
      ),
    );
  }

  /// Shared action buttons: Send Message + Block User
  /// Used for both user reports (passing targetId) and book reports (passing publisherId)
  Widget _buildUserActionButtons(
    BuildContext context,
    WidgetRef ref,
    AuthService authService,
    BookService bookService,
    String userId,
    String userStudentId,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showSendMessageDialog(
              context, ref, userId, userStudentId,
            ),
            icon: const Icon(Icons.send_rounded),
            label: const Text('إرسال رسالة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
            ),
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<bool>(
          stream: authService.isUserBlocked(userId),
          builder: (context, blockedSnapshot) {
            final isBlocked = blockedSnapshot.data ?? false;
            if (isBlocked) {
              return const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'هذا المستخدم محظور حالياً',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('حظر المستخدم نهائياً'),
                      content: Text(
                        'هل أنت متأكد من حظر الطالب $userStudentId نهائياً؟ سيتم إخفاء جميع إعلاناته ومنعه من استخدام التطبيق.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('إلغاء'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'تأكيد الحظر',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      await authService.blockUser(userId);
                      await bookService.hideBooksByUserId(userId);
                      final chatService = ref.read(chatServiceProvider);
                      await chatService.closeAllUserChats(userId, 'Admin (الحظر)');
                      await ref.read(systemMessageServiceProvider).sendAdminMessage(
                        recipientId: userId,
                        message: 'لقد تم حظرك نهائياً من استخدام التطبيق. إذا كنت تعتقد أن هذا حصل عن طريق خطأ، يرجى التواصل معنا عبر البريد الإلكتروني: solosoulacc@tutamail.com',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم حظر المستخدم بنجاح.')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('فشل في الحظر: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                icon: const Icon(Icons.block),
                label: const Text('حظر المستخدم نهائياً'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[900],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportService = ReportService();
    final bookService = BookService();
    final authService = ref.watch(authServiceProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة التقارير'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_off_rounded),
              tooltip: 'المستخدمون المحظورون',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BlockedUsersScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.campaign_outlined),
              tooltip: 'إرسال تعميم للكل',
              onPressed: () => _showBroadcastDialog(context, ref),
            ),
          ],
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: reportService.getAllReports(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('خطأ في تحميل التقارير: ${snapshot.error}'),
              );
            }

            final reports = snapshot.data ?? [];

            if (reports.isEmpty) {
              return const Center(child: Text('لا توجد تقارير حالياً.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                final dynamic rawTimestamp = report['timestamp'];
                final DateTime timestamp = rawTimestamp is DateTime
                    ? rawTimestamp
                    : (rawTimestamp as dynamic).toDate();

                final dateStr = DateFormat(
                  'yyyy/MM/dd hh:mm a',
                ).format(timestamp);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: FutureBuilder<String?>(
                      future: report['targetType'] == 'user'
                          ? ref
                                .read(authServiceProvider)
                                .getStudentIdFromUid(report['targetId'])
                          : Future.value(null),
                      builder: (context, userSnapshot) {
                        final displayTitle = report['targetType'] == 'user'
                            ? "مستخدم: ${userSnapshot.data ?? report['targetId']}"
                            : "كتاب: ${report['targetTitle'] ?? report['targetId']}";
                        return Text(
                          displayTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تاريخ: $dateStr'),
                        StreamBuilder<int>(
                          stream: reportService.getReportCount(
                            report['targetId'],
                          ),
                          builder: (context, countSnapshot) {
                            final count = countSnapshot.data ?? 0;
                            return Text(
                              'إجمالي الشكاوى على هذا الهدف: $count',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('النوع: ${report['targetType']}'),
                            const SizedBox(height: 4),
                            FutureBuilder<String?>(
                              future: ref
                                  .read(authServiceProvider)
                                  .getStudentIdFromUid(report['reporterId']),
                              builder: (context, userSnapshot) {
                                final studentId =
                                    userSnapshot.data ?? report['reporterId'];
                                return Text('المرسل: $studentId');
                              },
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'سبب الإبلاغ:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(report['reason'] ?? 'لا يوجد وصف.'),

                            // ── Common Actions: Send Message + Block User ──
                            const SizedBox(height: 12),
                            if (report['targetType'] == 'user') ...[  
                              FutureBuilder<String?>(
                                future: ref
                                    .read(authServiceProvider)
                                    .getStudentIdFromUid(report['targetId']),
                                builder: (context, targetSnapshot) {
                                  final targetStudentId =
                                      targetSnapshot.data ?? report['targetId'];
                                  return _buildUserActionButtons(
                                    context, ref, authService, bookService,
                                    report['targetId'], targetStudentId,
                                  );
                                },
                              ),
                            ],

                            // ── User-specific: Show Conversation ──
                            if (report['chatId'] != null) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _showChatHistoryDialog(
                                    context, ref, report['chatId'],
                                  ),
                                  icon: const Icon(Icons.chat_outlined),
                                  label: const Text('عرض سجل الدردشة'),
                                ),
                              ),
                            ],

                            const Divider(height: 32),

                            // ── Book-specific: Common Actions + Book Details + Delete Ad ──
                            if (report['targetType'] == 'book') ...[
                              FutureBuilder<BookModel?>(
                                future: bookService.getBookById(report['targetId']),
                                builder: (context, bookSnapshot) {
                                  if (bookSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  final book = bookSnapshot.data;
                                  if (book == null) {
                                    return const Text(
                                      'هذا الإعلان محذوف بالفعل.',
                                      style: TextStyle(color: Colors.red),
                                    );
                                  }
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Common action buttons targeting the book publisher
                                      FutureBuilder<String?>(
                                        future: ref
                                            .read(authServiceProvider)
                                            .getStudentIdFromUid(book.publisherId),
                                        builder: (context, publisherSnapshot) {
                                          final publisherStudentId =
                                              publisherSnapshot.data ?? book.publisherId;
                                          return _buildUserActionButtons(
                                            context, ref, authService, bookService,
                                            book.publisherId, publisherStudentId,
                                          );
                                        },
                                      ),
                                      const Divider(height: 24),
                                      // Book details
                                      const Text(
                                        'تفاصيل الإعلان المبلغ عنه:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text('العنوان: ${book.title}'),
                                      Text('المؤلف: ${book.author}'),
                                      FutureBuilder<String?>(
                                        future: ref
                                            .read(authServiceProvider)
                                            .getStudentIdFromUid(book.publisherId),
                                        builder: (context, userSnapshot) {
                                          return Text(
                                            'الناشر: ${userSnapshot.data ?? book.publisherId}',
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'الوصف:',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(book.description),
                                      const SizedBox(height: 16),
                                      // Delete Ad button
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text('حذف الإعلان'),
                                                content: const Text(
                                                  'هل أنت متأكد من حذف هذا الإعلان نهائياً؟ لا يمكن التراجع.',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(ctx, false),
                                                    child: const Text('إلغاء'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(ctx, true),
                                                    child: const Text(
                                                      'حذف الإعلان',
                                                      style: TextStyle(color: Colors.red),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              await bookService.deleteBook(
                                                report['targetId'],
                                              );
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'تم حذف الإعلان بنجاح.',
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.delete_forever,
                                            color: Colors.white,
                                          ),
                                          label: const Text(
                                            'حذف الإعلان',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],

                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('حذف التقرير'),
                                        content: const Text(
                                          'هل أنت متأكد من حذف هذا التقرير؟ (سيتم الاحتفاظ بالإعلان إذا لم يتم حذفه يدوياً).',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('إلغاء'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text(
                                              'حذف التقرير',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await reportService.deleteReport(
                                        report['id'],
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('تم حذف التقرير.'),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.grey,
                                  ),
                                  label: const Text(
                                    'حذف التقرير',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ],
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
