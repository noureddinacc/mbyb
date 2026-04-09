import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/book_service.dart';
import '../../services/chat_service.dart';
import '../../models/book.dart';
import '../../widgets/empty_state_view.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/shimmer_loading.dart';

class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({super.key});

  @override
  ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  final _bookService = BookService();
  final _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    final userAsyncValue = ref.watch(authStateProvider);
    final currentUser = userAsyncValue.value;

    if (currentUser == null) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: Center(child: Text('يرجى تسجيل الدخول لعرض المحادثات.')),
      );
    }

    final chatsAsyncValue = ref.watch(userChatsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: chatsAsyncValue.when(
        data: (chats) {
          if (chats.isEmpty) {
            return const EmptyStateView(
              icon: Icons.chat_bubble_outline,
              message: 'لا توجد محادثات نشطة بعد.',
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final lastSeen = chat.lastSeenAt[currentUser.uid];
              final isNew = lastSeen == null || chat.updatedAt.isAfter(lastSeen);

              return FutureBuilder<BookModel?>(
                future: _bookService.getBookById(chat.bookId),
                builder: (context, bookSnapshot) {
                  final bookTitle = bookSnapshot.data?.title ?? 'جاري تحميل الكتاب...';

                  return Dismissible(
                    key: Key(chat.id),
                    direction: DismissDirection.startToEnd,
                    background: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: AlignmentDirectional.centerStart,
                      padding: const EdgeInsetsDirectional.only(start: 20),
                      child: const Icon(Icons.archive, color: Colors.white),
                    ),
                    onDismissed: (_) {
                      _chatService.archiveChat(chat.id, currentUser.uid);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(content: Text('تم أرشفة المحادثة')),
                          );
                      }
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        leading: const CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.book, color: Colors.white),
                        ),
                        title: Text(
                          bookTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          chat.lastMessage ?? 'لا توجد رسائل بعد.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: isNew
                            ? Container(
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
                            : const Icon(Icons.chevron_right),
                        onTap: () {
                          _chatService.markChatAsSeen(chat.id, currentUser.uid);
                          context.push('/chat', extra: chat);
                        },
                      ),
                    ),
                  );
                },
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
    );
  }
}

