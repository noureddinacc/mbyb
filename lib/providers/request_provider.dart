import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/request.dart';
import 'service_providers.dart';
import 'auth_provider.dart';

final incomingRequestsProvider = StreamProvider<List<RequestModel>>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return Stream.value([]);
  
  final requestService = ref.watch(requestServiceProvider);
  return requestService.getIncomingRequests(authState.uid);
});

final outgoingRequestsProvider = StreamProvider<List<RequestModel>>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return Stream.value([]);
  
  final requestService = ref.watch(requestServiceProvider);
  return requestService.getOutgoingRequests(authState.uid);
});

final myRequestForBookProvider = StreamProvider.family<RequestModel?, String>((ref, bookId) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return Stream.value(null);
  
  final requestService = ref.watch(requestServiceProvider);
  return requestService.getMyRequestForBook(bookId, authState.uid);
});
