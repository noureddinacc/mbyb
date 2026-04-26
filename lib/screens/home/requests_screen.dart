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

  Color _getTypeColor(String postType) {
    if (postType == 'request') return Colors.purple[600]!;
    if (postType == 'free') return Colors.green[600]!;
    return Colors.blue[600]!;
  }

  Color _getTypeBgColor(String postType) {
    if (postType == 'request') return Colors.purple[50]!;
    if (postType == 'free') return Colors.green[50]!;
    return Colors.blue[50]!;
  }

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
            icon: Icons.inbox_outlined,
            message: 'لا توجد طلبات واردة حالياً',
          );
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (listContext, index) {
            final req = requests[index];
            final typeColor = _getTypeColor(req.postType);
            final typeBg = _getTypeBgColor(req.postType);

            return Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: typeBg,
                    child: Icon(Icons.person, color: typeColor, size: 24),
                  ),
                  title: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black, fontSize: 14, height: 1.4),
                      children: [
                        TextSpan(
                          text: req.requesterStudentId,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: req.postType == 'request' 
                              ? ' عرض تزويدك بكتاب ' 
                              : ' طلب كتاب ',
                        ),
                        TextSpan(
                          text: '"${req.bookTitle}"',
                          style: TextStyle(fontWeight: FontWeight.bold, color: typeColor),
                        ),
                      ],
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'في: ${req.timestamp.toString().substring(0, 10)}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Reject Button
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey, size: 22),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => Directionality(
                              textDirection: TextDirection.rtl,
                              child: AlertDialog(
                                title: const Text('رفض الطلب'),
                                content: const Text('هل أنت متأكد أنك تريد رفض هذا الطلب؟'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(false),
                                    child: const Text('تراجع'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(true),
                                    child: const Text('رفض', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            ),
                          );

                          if (confirm == true) {
                            try {
                              await _requestService.rejectRequest(req.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(const SnackBar(content: Text('تم رفض الطلب.')));
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            }
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      // Accept Button
                      ElevatedButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => Directionality(
                              textDirection: TextDirection.rtl,
                              child: AlertDialog(
                                title: const Text('قبول الطلب'),
                                content: const Text('عند القبول، سيتم فتح محادثة مع الطالب.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(false),
                                    child: const Text('إلغاء'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(true),
                                    child: const Text('قبول', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          );

                          if (confirm == true) {
                            try {
                              final publisherStudentId = currentUser.email?.split('@').first ?? '';
                              final chatId = await _requestService.acceptRequest(
                                req,
                                currentUser.uid,
                                publisherStudentId,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(const SnackBar(content: Text('تم قبول الطلب! جاري فتح المحادثة...')));
                                
                                context.push(
                                  '/chat', 
                                  extra: ChatModel(
                                    id: chatId,
                                    participantIds: [currentUser.uid, req.requesterId],
                                    participantStudentIds: {
                                      currentUser.uid: publisherStudentId,
                                      req.requesterId: req.requesterStudentId,
                                    },
                                    bookId: req.bookId,
                                    bookTitle: req.bookTitle,
                                    postType: req.postType,
                                    updatedAt: DateTime.now(),
                                    lastMessage: 'Request Accepted! Say Hi.',
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          minimumSize: const Size(0, 36),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('قبول', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 1, color: Colors.grey[100], indent: 16),
              ],
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
            icon: Icons.send_outlined,
            message: 'لم تقم بإرسال أي طلبات بعد',
          );
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            final typeColor = _getTypeColor(req.postType);
            final typeBg = _getTypeBgColor(req.postType);

            return Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: typeBg,
                    child: Icon(Icons.outbox, color: typeColor, size: 24),
                  ),
                  title: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black, fontSize: 14, height: 1.4),
                      children: [
                        const TextSpan(text: 'لقد قمت بـ '),
                        TextSpan(
                          text: req.postType == 'request' ? 'عرض تزويد ' : 'طلب ',
                        ),
                        TextSpan(
                          text: '"${req.bookTitle}"',
                          style: TextStyle(fontWeight: FontWeight.bold, color: typeColor),
                        ),
                      ],
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'بانتظار الرد • ${req.timestamp.toString().substring(0, 10)}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ),
                  trailing: TextButton(
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
                                child: const Text('إلغاء الطلب', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        ),
                      );

                      if (confirm == true) {
                        try {
                          await _requestService.cancelRequest(req.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إلغاء الطلب.')));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        }
                      }
                    },
                    child: Text('إلغاء', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ),
                ),
                Divider(height: 1, thickness: 1, color: Colors.grey[100], indent: 16),
              ],
            );
          },
        );
      },
    );
  }
}
