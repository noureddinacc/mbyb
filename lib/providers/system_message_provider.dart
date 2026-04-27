import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'service_providers.dart';
import 'auth_provider.dart';

final unreadSystemMessagesCountProvider = StreamProvider<int>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return Stream.value(0);
  
  final systemMessageService = ref.watch(systemMessageServiceProvider);
  return systemMessageService.getUnreadCount(authState.uid);
});

final userSystemMessagesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return Stream.value([]);
  
  final systemMessageService = ref.watch(systemMessageServiceProvider);
  return systemMessageService.getUserMessages(authState.uid);
});
