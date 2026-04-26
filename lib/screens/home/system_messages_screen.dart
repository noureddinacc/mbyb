import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../providers/auth_provider.dart';
import '../../providers/service_providers.dart';

class SystemMessagesScreen extends ConsumerWidget {
  const SystemMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateProvider).value;
    if (currentUser == null) return const Scaffold(body: Center(child: Text('يرجى تسجيل الدخول')));

    final messageService = ref.read(systemMessageServiceProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'رسائل الإدارة',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: messageService.getUserMessages(currentUser.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'خطأ في تحميل الرسائل: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            final messages = snapshot.data ?? [];
            if (messages.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mark_email_read_outlined, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد رسائل من الإدارة حالياً.',
                      style: TextStyle(color: Colors.grey[500], fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final timestamp = (msg['timestamp'] as dynamic)?.toDate() ?? DateTime.now();
                final dateStr = DateFormat('h:mm a • yyyy/MM/dd').format(timestamp);
                final isRead = msg['isRead'] ?? false;

                if (!isRead) {
                  Future.microtask(() => messageService.markAsRead(msg['id']));
                }

                return Dismissible(
                  key: Key(msg['id']),
                  direction: DismissDirection.startToEnd,
                  background: Container(
                    color: Colors.red[50],
                    alignment: AlignmentDirectional.centerStart,
                    padding: const EdgeInsetsDirectional.only(start: 20),
                    child: Icon(Icons.delete_outline, color: Colors.red[700]),
                  ),
                  onDismissed: (direction) {
                    final messageData = Map<String, dynamic>.from(msg);
                    messageService.deleteMessage(msg['id']);

                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('تم مسح الرسالة'),
                        action: SnackBarAction(
                          label: 'تراجع',
                          onPressed: () {
                            messageService.restoreMessage(messageData);
                          },
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.verified_user, color: Colors.green[700], size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                        'مسؤول النظام',
                                        style: TextStyle(
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      dateStr,
                                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                    ),
                                    if (!isRead) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              msg['message'] ?? '',
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, thickness: 1, color: Colors.grey[100], indent: 20, endIndent: 20),
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
