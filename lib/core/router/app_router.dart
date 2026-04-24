import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/home/main_screen.dart';
import '../../screens/chat/chat_thread_screen.dart';
import '../../screens/home/archived_chats_screen.dart';
import '../../models/chat.dart';

import 'package:flutter/foundation.dart';

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this.ref) {
    ref.listen(authStateProvider, (_, _) => notifyListeners());
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

      if (authState.isLoading) return null; // Wait until init finishes

      final user = authState.value;
      final isAuth = user != null;
      final isVerified = user?.emailVerified ?? false;
      final isLoggingIn =
          state.uri.path == '/login' || state.uri.path == '/signup';

      if (!isAuth || !isVerified) {
        // Redirect to login if not authenticated OR not verified
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),

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
