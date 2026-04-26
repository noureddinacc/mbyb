import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/chat_service.dart';
import '../../widgets/empty_state_view.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/shimmer_loading.dart';

class ArchivedChatsScreen extends ConsumerStatefulWidget {
  const ArchivedChatsScreen({super.key});

  @override
  ConsumerState<ArchivedChatsScreen> createState() => _ArchivedChatsScreenState();
}

class _ArchivedChatsScreenState extends ConsumerState<ArchivedChatsScreen> {
  final _chatService = ChatService();

  Color _getAvatarColor(String? postType) {
    if (postType == 'request') return Colors.purple[50]!;
    if (postType == 'free') return Colors.green[50]!;
    if (postType == 'exchange') return Colors.blue[50]!;
    return Colors.grey[100]!;
  }

  Color _getIconColor(String? postType) {
    if (postType == 'request') return Colors.purple[700]!;
    if (postType == 'free') return Colors.green[700]!;
    if (postType == 'exchange') return Colors.blue[700]!;
    return Colors.grey[600]!;
  }

  @override
  Widget build(BuildContext context) {
    final userAsyncValue = ref.watch(authStateProvider);
    final currentUser = userAsyncValue.value;

    if (currentUser == null) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(child: Text('يرجى تسجيل الدخول لعرض المحادثات المؤرشفة.')),
        ),
      );
    }

    final archivedAsyncValue = ref.watch(archivedChatsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'المحادثات المؤرشفة',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: archivedAsyncValue.when(
          data: (chats) {
            if (chats.isEmpty) {
              return const EmptyStateView(
                icon: Icons.archive_outlined,
                message: 'لا توجد محادثات مؤرشفة.',
              );
            }

            return ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                final lastSeen = chat.lastSeenAt[currentUser.uid];
                final isNew = lastSeen == null || chat.updatedAt.isAfter(lastSeen);

                // Use denormalized data for instant loading
                final bookTitle = chat.bookTitle.isEmpty ? 'كتاب غير معروف' : chat.bookTitle;
                final postType = chat.postType;

                return Column(
                  children: [
                    Dismissible(
                      key: Key(chat.id),
                      direction: DismissDirection.startToEnd,
                      background: Container(
                        color: Colors.blue[50],
                        alignment: AlignmentDirectional.centerStart,
                        padding: const EdgeInsetsDirectional.only(start: 20),
                        child: Icon(Icons.unarchive, color: Colors.blue[700]),
                      ),
                      onDismissed: (_) {
                        _chatService.unarchiveChat(chat.id, currentUser.uid);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              const SnackBar(
                                content: Text('تم إلغاء أرشفة المحادثة'),
                              ),
                            );
                        }
                      },
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: _getAvatarColor(postType),
                          child: Icon(
                            Icons.book,
                            color: _getIconColor(postType),
                            size: 22,
                          ),
                        ),
                        title: Text(
                          bookTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            chat.lastMessage ?? 'لا توجد رسائل بعد.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (isNew)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'جديد!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                          ],
                        ),
                        onTap: () {
                          _chatService.markChatAsSeen(
                            chat.id,
                            currentUser.uid,
                          );
                          context.push('/chat', extra: chat);
                        },
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey[100],
                      indent: 16,
                    ),
                  ],
                );
              },
            );
          },
          loading: () {
            return ListView.builder(
              itemCount: 4,
              itemBuilder: (context, index) => const ChatCardSkeleton(),
            );
          },
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}
