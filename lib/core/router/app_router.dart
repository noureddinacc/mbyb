import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/service_providers.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/home/main_screen.dart';
import '../../screens/chat/chat_thread_screen.dart';
import '../../screens/home/archived_chats_screen.dart';
import '../../models/chat.dart';

import 'package:flutter/foundation.dart';

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this.ref) {
    ref.listen(authStateProvider, (_, _) => notifyListeners());
    ref.listen(universitiesProvider, (_, _) => notifyListeners());
  }
  final Ref ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      if (authState.isLoading) return null; // Wait for auth init

      final user = authState.value;
      final isAuth = user != null;
      final isVerified = user?.emailVerified ?? false;
      final userEmail = user?.email?.toLowerCase();

      // Fast-path: master admin never gets blocked
      if (userEmail == 'solosoulacc@tutamail.com') {
        return (isAuth && state.uri.path == '/login') ? '/home' : null;
      }

      // Wait for universities to load before checking uni-admin status
      final universitiesState = ref.read(universitiesProvider);
      if (universitiesState.isLoading) return null;

      final universities = universitiesState.value ?? [];
      final isUniAdmin = universities.any((u) =>
        u.adminEmails.any((e) => e.toLowerCase() == userEmail)
      );
      final isAdmin = isUniAdmin;

      if (kDebugMode && isAuth) {
        print('Router [$userEmail] verified=$isVerified admin=$isAdmin unis=${universities.length}');
      }

      final isLoggingIn = state.uri.path == '/login';

      if (!isAuth || (!isVerified && !isAdmin)) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn) return '/home';

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      GoRoute(path: '/home', builder: (context, state) => const MainScreen()),
      GoRoute(
        path: '/archived-chats',
        builder: (context, state) => const ArchivedChatsScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) {
          final chat = state.extra as ChatModel;
          return ChatThreadScreen(chat: chat);
        },
      ),
    ],
  );
});
