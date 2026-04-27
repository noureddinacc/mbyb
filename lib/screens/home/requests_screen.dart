import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/request_service.dart';
import '../../services/auth_service.dart';
import '../../models/chat.dart';
import '../../widgets/empty_state_view.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/request_provider.dart';
import '../../providers/auth_provider.dart';

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> {
  final _requestService = RequestService();
  final _authService = AuthService();

  Color _getTypeColor(BuildContext context, String postType) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (postType == 'request')
      return isDark ? Colors.purple[300]! : Colors.purple[600]!;
    if (postType == 'free')
      return isDark ? Colors.green[300]! : Colors.green[600]!;
    return isDark ? Colors.blue[300]! : Colors.blue[600]!;
  }

  Color _getTypeBgColor(BuildContext context, String postType) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (postType == 'request')
      return isDark
          ? Colors.purple[900]!.withValues(alpha: 0.2)
          : Colors.purple[50]!;
    if (postType == 'free')
      return isDark
          ? Colors.green[900]!.withValues(alpha: 0.2)
          : Colors.green[50]!;
    return isDark ? Colors.blue[900]!.withValues(alpha: 0.2) : Colors.blue[50]!;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).value;

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
          _buildReceivedRequests(context, currentUser),
          _buildSentRequests(context, currentUser),
        ],
      ),
    );
  }

  Widget _buildReceivedRequests(BuildContext context, User currentUser) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final requestsAsync = ref.watch(incomingRequestsProvider);

    return requestsAsync.when(
      data: (requests) {
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
            final typeColor = _getTypeColor(context, req.postType);
            final typeBg = _getTypeBgColor(context, req.postType);

            return Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: typeBg,
                    child: Icon(
                      Icons.person_outline,
                      color: typeColor,
                      size: 24,
                    ),
                  ),
                  title: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 14,
                        height: 1.4,
                      ),
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: typeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'في: ${req.timestamp.toString().substring(0, 10)}',
                      style: TextStyle(
                        color: isDark ? Colors.grey[600] : Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: isDark ? Colors.grey[700] : Colors.grey,
                          size: 22,
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => Directionality(
                              textDirection: TextDirection.rtl,
                              child: AlertDialog(
                                backgroundColor: isDark
                                    ? const Color(0xFF1A1D1E)
                                    : Colors.white,
                                title: Text(
                                  'رفض الطلب',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                content: Text(
                                  'هل أنت متأكد أنك تريد رفض هذا الطلب؟',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.grey[300]
                                        : Colors.black87,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(false),
                                    child: const Text('تراجع'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(true),
                                    child: const Text(
                                      'رفض',
                                      style: TextStyle(color: Colors.red),
                                    ),
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
                                  ..showSnackBar(
                                    const SnackBar(
                                      content: Text('تم رفض الطلب.'),
                                    ),
                                  );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => Directionality(
                              textDirection: TextDirection.rtl,
                              child: AlertDialog(
                                backgroundColor: isDark
                                    ? const Color(0xFF1A1D1E)
                                    : Colors.white,
                                title: Text(
                                  'قبول الطلب',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                content: Text(
                                  'عند القبول، سيتم فتح محادثة مع الطالب.',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.grey[300]
                                        : Colors.black87,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(false),
                                    child: const Text('إلغاء'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(true),
                                    child: const Text(
                                      'قبول',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );

                          if (confirm == true) {
                            try {
                              final publisherStudentId =
                                  currentUser.email?.split('@').first ?? '';
                              final chatId = await _requestService
                                  .acceptRequest(
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
                                    bookTitle: req.bookTitle,
                                    postType: req.postType,
                                    updatedAt: DateTime.now(),
                                    lastMessage: 'Request Accepted! Say Hi.',
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.green[900]
                              : Colors.green[600],
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          minimumSize: const Size(0, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'قبول',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey[100],
                  indent: 16,
                ),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildSentRequests(BuildContext context, User currentUser) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final requestsAsync = ref.watch(outgoingRequestsProvider);

    return requestsAsync.when(
      data: (requests) {
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
            final typeColor = _getTypeColor(context, req.postType);
            final typeBg = _getTypeBgColor(context, req.postType);

            return Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: typeBg,
                    child: Icon(Icons.outbox, color: typeColor, size: 24),
                  ),
                  title: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(text: 'لقد قمت بـ '),
                        TextSpan(
                          text: req.postType == 'request'
                              ? 'عرض تزويد '
                              : 'طلب ',
                        ),
                        TextSpan(
                          text: '"${req.bookTitle}"',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: typeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'بانتظار الرد • ${req.timestamp.toString().substring(0, 10)}',
                      style: TextStyle(
                        color: isDark ? Colors.grey[600] : Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => Directionality(
                          textDirection: TextDirection.rtl,
                          child: AlertDialog(
                            backgroundColor: isDark
                                ? const Color(0xFF1A1D1E)
                                : Colors.white,
                            title: Text(
                              'إلغاء الطلب',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            content: Text(
                              'هل أنت متأكد أنك تريد إلغاء هذا الطلب؟',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[300]
                                    : Colors.black87,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('لا'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text(
                                  'إلغاء الطلب',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );

                      if (confirm == true) {
                        try {
                          await _requestService.cancelRequest(req.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم إلغاء الطلب.')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      }
                    },
                    child: Text(
                      'إلغاء',
                      style: TextStyle(
                        color: isDark ? Colors.grey[600] : Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey[100],
                  indent: 16,
                ),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
