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
        appBar: AppBar(
          title: const Text('رسائل الإدارة'),
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
              return const Center(
                child: Text('لا توجد رسائل من الإدارة حالياً.'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final timestamp = (msg['timestamp'] as dynamic)?.toDate() ?? DateTime.now();
                final dateStr = DateFormat('yyyy/MM/dd hh:mm a').format(timestamp);

                if (!(msg['isRead'] ?? false)) {
                  // Mark as read asynchronously behind the scenes
                  Future.microtask(() => messageService.markAsRead(msg['id']));
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: (msg['isRead'] ?? false) ? Colors.transparent : Colors.blue,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'مسؤول النظام (Admin)',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                            Text(
                              dateStr,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          msg['message'] ?? '',
                          style: const TextStyle(fontSize: 15, height: 1.4),
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
  }
}
