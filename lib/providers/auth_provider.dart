import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'service_providers.dart';

class AuthRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void trigger() => state++;
}

final authRefreshTriggerProvider = NotifierProvider<AuthRefreshNotifier, int>(
  AuthRefreshNotifier.new,
);

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  ref.watch(authRefreshTriggerProvider);
  return authService.authStateChanges;
});
