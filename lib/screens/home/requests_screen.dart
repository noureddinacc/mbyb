import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/request_service.dart';
import '../../services/auth_service.dart';
import '../../models/request.dart';
import '../../models/chat.dart';
import '../../widgets/empty_state_view.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final _requestService = RequestService();
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    if (currentUser == null) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(child: Text('يرجى تسجيل الدخول لعرض الطلبات.')),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: TabBarView(
        children: [
          _buildReceivedRequests(currentUser),
          _buildSentRequests(currentUser),
        ],
      ),
    );
  }

  Widget _buildReceivedRequests(User currentUser) {
    return StreamBuilder<List<RequestModel>>(
      stream: _requestService.getIncomingRequests(currentUser.uid),
      builder: (streamContext, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return const EmptyStateView(
            icon: Icons.inbox,
            message: 'لا توجد طلبات واردة حالياً',
          );
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (listContext, index) {
            final req = requests[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  req.postType == 'request' 
                      ? 'عرض ${req.requesterStudentId} تزويدك بكتاب "${req.bookTitle}"'
                      : 'طلب ${req.requesterStudentId} كتاب "${req.bookTitle}"',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'في: ${req.timestamp.toString().substring(0, 10)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 32,
                      ),
                      onPressed: () async {
                        debugPrint('Accept button pressed for request: ${req.id}');
                        final confirm = await showDialog<bool>(
                          context: context, // Use StatefulWidget's context
                          barrierDismissible: false,
                          builder: (dialogContext) => Directionality(
                            textDirection: TextDirection.rtl,
                            child: AlertDialog(
                              title: const Text('قبول الطلب'),
                              content: const Text('هل أنت متأكد أنك تريد قبول هذا الطلب؟ سيؤدي هذا إلى إنشاء محادثة مع صاحب الطلب.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(false),
                                  child: const Text('لا'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(true),
                                  child: const Text('نعم، أقبل', style: TextStyle(color: Colors.green)),
                                ),
                              ],
                            ),
                          ),
                        );

                        debugPrint('Confirmation result: $confirm');
                        if (confirm != true) return;

                        try {
                          final publisherStudentId =
                              currentUser.email?.split('@').first ?? '';
                          final chatId = await _requestService.acceptRequest(
                            req,
                            currentUser.uid,
                            publisherStudentId,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'تم قبول الطلب! جاري فتح المحادثة...',
                                ),
                              ),
                            );
                            // Navigate directly to the chat thread
                            context.push(
                              '/chat', 
                              extra: ChatModel(
                                id: chatId,
                                participantIds: [
                                  currentUser.uid,
                                  req.requesterId,
                                ],
                                participantStudentIds: {
                                  currentUser.uid: publisherStudentId,
                                  req.requesterId: req.requesterStudentId,
                                },
                                bookId: req.bookId,
                                updatedAt: DateTime.now(),
                                lastMessage: 'Request Accepted! Say Hi.',
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.cancel,
                        color: Colors.red,
                        size: 32,
                      ),
                      onPressed: () async {
                        debugPrint('Reject button pressed for request: ${req.id}');
                        final confirm = await showDialog<bool>(
                          context: context, // Use StatefulWidget's context
                          barrierDismissible: false,
                          builder: (dialogContext) => Directionality(
                            textDirection: TextDirection.rtl,
                            child: AlertDialog(
                              title: const Text('رفض الطلب'),
                              content: const Text('هل أنت متأكد أنك تريد رفض هذا الطلب؟ لا يمكن التراجع عن هذا الإجراء.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(false),
                                  child: const Text('لا'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(true),
                                  child: const Text('نعم، أرفض', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ),
                        );

                        debugPrint('Confirmation result: $confirm');
                        if (confirm != true) return;

                        try {
                          await _requestService.rejectRequest(req.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                              const SnackBar(
                                content: Text('تم رفض الطلب.'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSentRequests(User currentUser) {
    return StreamBuilder<List<RequestModel>>(
      stream: _requestService.getOutgoingRequests(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return const EmptyStateView(
            icon: Icons.send,
            message: 'لم تقم بإرسال أي طلبات بعد',
          );
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.outbox, color: Colors.white),
                ),
                title: Text(
                  req.postType == 'request'
                      ? 'لقد عرضت تزويد كتاب "${req.bookTitle}"'
                      : 'لقد طلبت كتاب "${req.bookTitle}"',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'في: ${req.timestamp.toString().substring(0, 10)}',
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.cancel,
                    color: Colors.red,
                    size: 32,
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => Directionality(
                        textDirection: TextDirection.rtl,
                        child: AlertDialog(
                          title: const Text('إلغاء الطلب'),
                          content: const Text('هل أنت متأكد أنك تريد إلغاء هذا الطلب؟'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('لا'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('نعم، إلغاء', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ),
                    );

                    if (confirm == true) {
                      try {
                        await _requestService.cancelRequest(req.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                            const SnackBar(
                              content: Text('تم إلغاء الطلب بنجاح.'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
