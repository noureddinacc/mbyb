import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'service_providers.dart';

/// Provider to check if the currently logged-in user is an admin.
/// Checks both the global master admin and the university-specific admin list.
final isAdminProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider).value;
  final email = authState?.email?.toLowerCase();
  if (email == null) return false;

  // 1. Global Master Admin Check
  if (email == 'solosoulacc@tutamail.com') return true;

  // 2. University-Specific Admin Check — scan ALL universities' admin lists
  final universitiesAsync = ref.watch(universitiesProvider);
  return universitiesAsync.maybeWhen(
    data: (universities) {
      return universities.any((u) =>
        u.adminEmails.any((adminEmail) => adminEmail.toLowerCase() == email)
      );
    },
    orElse: () => false,
  );
});
