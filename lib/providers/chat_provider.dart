import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat.dart';
import '../models/chat_message.dart';
import 'service_providers.dart';
import 'auth_provider.dart';

final userChatsProvider = StreamProvider<List<ChatModel>>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  final userAsyncValue = ref.watch(authStateProvider);

  return userAsyncValue.when(
    data: (user) {
      if (user == null) {
        return Stream.value([]);
      }
      return chatService.getUserChats(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, _) => Stream.value([]),
  );
});

final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((
  ref,
  chatId,
) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.getChatMessages(chatId);
});

final archivedChatsProvider = StreamProvider<List<ChatModel>>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  final userAsyncValue = ref.watch(authStateProvider);

  return userAsyncValue.when(
    data: (user) {
      if (user == null) {
        return Stream.value([]);
      }
      return chatService.getArchivedChats(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, _) => Stream.value([]),
  );
});
