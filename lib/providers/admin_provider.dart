import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'service_providers.dart';

/// Provider to check if the currently logged-in user is an admin.
/// Checks both the global master admin and the university-specific admin list.
final isAdminProvider = Provider<bool>((ref) {
  final userProfile = ref.watch(userProfileProvider).value;
  if (userProfile == null) return false;

  final email = userProfile['email']?.toString().toLowerCase();
  if (email == null) return false;

  // 1. Global Master Admin Check (Your master email)
  if (email == 'solosoulacc@tutamail.com') return true;

  // 2. University-Specific Admin Check
  final universityId = userProfile['universityId'];
  if (universityId == null) return false;

  // We watch the universities list to see if the user's email is in their university's admin list
  final universitiesAsync = ref.watch(universitiesProvider);
  
  return universitiesAsync.maybeWhen(
    data: (universities) {
      try {
        final university = universities.firstWhere((u) => u.id == universityId);
        return university.adminEmails.any((adminEmail) => 
          adminEmail.toLowerCase() == email
        );
      } catch (e) {
        return false;
      }
    },
    orElse: () => false,
  );
});
