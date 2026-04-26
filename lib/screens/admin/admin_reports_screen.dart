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
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.forum_rounded, color: Colors.green[700], size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'سجل المحادثة',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<List<ChatMessage>>(
                    stream: chatService.getChatMessages(chatId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final messages = snapshot.data ?? [];
                      if (messages.isEmpty) {
                        return const Center(child: Text('لا توجد رسائل في هذه المحادثة.', style: TextStyle(color: Colors.grey)));
                      }

                      // Reverse list to show newest at bottom if typical chat, but for history top-down is fine.
                      // Let's stick to chronological order (top to bottom).
                      return ListView.builder(
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          // Simple sender differentiation based on ID hash or parity for preview
                          final bool isAlternativeSender = index % 2 == 0; 
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Column(
                              crossAxisAlignment: isAlternativeSender ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                              children: [
                                FutureBuilder<String?>(
                                  future: authService.getStudentIdFromUid(msg.senderId),
                                  builder: (context, userSnapshot) {
                                    return Text(
                                      userSnapshot.data ?? 'مستخدم',
                                      style: TextStyle(
                                        fontSize: 10, 
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[400],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isAlternativeSender ? Colors.grey[100] : Colors.green[700],
                                    borderRadius: BorderRadius.circular(16).copyWith(
                                      bottomRight: isAlternativeSender ? const Radius.circular(16) : Radius.zero,
                                      bottomLeft: isAlternativeSender ? Radius.zero : const Radius.circular(16),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg.text,
                                        style: TextStyle(
                                          color: isAlternativeSender ? Colors.black87 : Colors.white,
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('hh:mm a').format(msg.sentAt),
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: isAlternativeSender ? Colors.grey[500] : Colors.green[100],
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
                const SizedBox(height: 16),
                const Text(
                  '* هذا السجل للمراجعة فقط *',
                  style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
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
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إرسال إلى $studentId',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: controller,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'اكتب رسالتك هنا...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final message = controller.text.trim();
                        if (message.isEmpty) return;
                        try {
                          await ref.read(systemMessageServiceProvider).sendAdminMessage(
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
                              SnackBar(content: Text('فشل: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('إرسال الآن'),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'بث تعميم لجميع الطلاب',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'سيتم إرسال هذه الرسالة إلى جميع المسجلين.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: controller,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'اكتب التعميم هنا...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('إلغاء'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final message = controller.text.trim();
                        if (message.isEmpty) return;

                        final confirm = await showDialog<bool>(
                          context: ctx,
                          builder: (confirmCtx) => AlertDialog(
                            title: const Text('تأكيد الإرسال'),
                            content: const Text('هل أنت متأكد من إرسال هذا التعميم للجميع؟'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(confirmCtx, false), child: const Text('تراجع')),
                              TextButton(onPressed: () => Navigator.pop(confirmCtx, true), child: const Text('نعم، أرسل')),
                            ],
                          ),
                        );

                        if (confirm != true) return;

                        if (context.mounted) {
                          showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                          try {
                            await ref.read(systemMessageServiceProvider).broadcastMessage(message: message);
                            if (context.mounted) {
                              Navigator.pop(context); // Close loading
                              Navigator.pop(ctx); // Close dialog
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال التعميم بنجاح.')));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل: $e'), backgroundColor: Colors.red));
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('بث للجميع'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
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
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
          title: const Text('إدارة التقارير', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_off_rounded, size: 22),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockedUsersScreen())),
            ),
            IconButton(
              icon: const Icon(Icons.campaign_outlined, size: 24),
              onPressed: () => _showBroadcastDialog(context, ref),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: reportService.getAllReports(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text('خطأ في تحميل التقارير'));

            final reports = snapshot.data ?? [];
            if (reports.isEmpty) return const Center(child: Text('لا توجد تقارير حالياً.', style: TextStyle(color: Colors.grey)));

            return ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: reports.length,
              separatorBuilder: (context, index) => Divider(
                height: 1, 
                thickness: 1, 
                color: Colors.grey[100],
                indent: 16,
              ),
              itemBuilder: (context, index) {
                final report = reports[index];
                final DateTime timestamp = (report['timestamp'] as dynamic).toDate();
                final dateStr = DateFormat('yyyy/MM/dd hh:mm a').format(timestamp);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Target Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          FutureBuilder<String?>(
                            future: report['targetType'] == 'user'
                                ? authService.getStudentIdFromUid(report['targetId'])
                                : Future.value(report['targetTitle']),
                            builder: (context, targetSnapshot) {
                              final title = targetSnapshot.data ?? 'هدف غير معروف';
                              return Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: report['targetType'] == 'user' ? Colors.orange[50] : Colors.blue[50],
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            report['targetType'] == 'user' ? 'مستخدم' : 'كتاب',
                                            style: TextStyle(
                                              fontSize: 10, 
                                              fontWeight: FontWeight.bold,
                                              color: report['targetType'] == 'user' ? Colors.orange[700] : Colors.blue[700],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                                  ],
                                ),
                              );
                            },
                          ),
                          // Report Count Badge
                          StreamBuilder<int>(
                            stream: reportService.getReportCount(report['targetId']),
                            builder: (context, countSnapshot) {
                              final count = countSnapshot.data ?? 0;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$count تقارير',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red[700]),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Reporter Info
                      FutureBuilder<String?>(
                        future: authService.getStudentIdFromUid(report['reporterId']),
                        builder: (context, reporterSnapshot) {
                          return Row(
                            children: [
                              Icon(Icons.flag_outlined, size: 14, color: Colors.grey[400]),
                              const SizedBox(width: 4),
                              Text(
                                'بواسطة: ${reporterSnapshot.data ?? 'مجهول'}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      // Reason Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          report['reason'] ?? 'لا يوجد وصف.',
                          style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Conversation Button if exists
                      if (report['chatId'] != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _showChatHistoryDialog(context, ref, report['chatId']),
                              icon: const Icon(Icons.forum_outlined, size: 18),
                              label: const Text('عرض المحادثة المتعلقة'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue[700],
                                side: BorderSide(color: Colors.blue[100]!),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ),
                      // Action Pills
                      FutureBuilder<String?>(
                        future: report['targetType'] == 'user' 
                          ? authService.getStudentIdFromUid(report['targetId'])
                          : bookService.getBookById(report['targetId']).then((b) => b?.publisherId),
                        builder: (context, targetUserSnapshot) {
                          final targetUserId = report['targetType'] == 'user' ? report['targetId'] : targetUserSnapshot.data;
                          if (targetUserId == null) return const SizedBox.shrink();

                          return Row(
                            children: [
                              _buildActionPill(
                                icon: Icons.mail_outline,
                                label: 'مراسلة',
                                color: Colors.blue,
                                onTap: () async {
                                  final studentId = await authService.getStudentIdFromUid(targetUserId);
                                  if (context.mounted) _showSendMessageDialog(context, ref, targetUserId, studentId ?? 'مستخدم');
                                },
                              ),
                              const SizedBox(width: 12),
                              _buildActionPill(
                                icon: Icons.block_flipped,
                                label: 'حظر نهائي',
                                color: Colors.red,
                                onTap: () async {
                                  final studentId = await authService.getStudentIdFromUid(targetUserId);
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (dialogCtx) => AlertDialog(
                                      title: const Text('حظر نهائي'),
                                      content: Text('هل أنت متأكد من حظر $studentId؟'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('إلغاء')),
                                        TextButton(onPressed: () => Navigator.pop(dialogCtx, true), child: const Text('حظر', style: TextStyle(color: Colors.red))),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await authService.blockUser(targetUserId);
                                    await bookService.hideBooksByUserId(targetUserId);
                                    await ref.read(chatServiceProvider).closeAllUserChats(targetUserId, 'Admin (Ban)');
                                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحظر.')));
                                  }
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // Close Report Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (dialogCtx) => AlertDialog(
                                  title: const Text('إغلاق التقرير'),
                                  content: const Text('هل تريد أرشفة/حذف هذا التقرير؟'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('إلغاء')),
                                    TextButton(onPressed: () => Navigator.pop(dialogCtx, true), child: const Text('إغلاق', style: TextStyle(color: Colors.grey))),
                                  ],
                                ),
                              );
                              if (confirm == true) await reportService.deleteReport(report['id']);
                            },
                            icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.grey),
                            label: const Text('إغلاق التقرير', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ),
                        ],
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
