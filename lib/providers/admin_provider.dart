import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

/// Provider to check if the currently logged-in user is an admin.
/// Admin status is determined by the specific email address 'solosoulacc@tutamail.com'.
final isAdminProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) => user?.email == 'solosoulacc@tutamail.com',
    loading: () => false,
    error: (_, _) => false,
  );
});
