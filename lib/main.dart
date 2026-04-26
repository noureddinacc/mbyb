import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  try {
    // Initialize Firebase and SharedPreferences sequentially for better stability on web
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    final prefs = await SharedPreferences.getInstance();

    runApp(
      ProviderScope(
        overrides: [
          // Initialize the sharedPreferencesProvider with the pre-loaded instance
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MainApp(),
      ),
    );
  } catch (e) {
    debugPrint("Initialization error: $e");
  } finally {
    // Always remove the splash screen even if initialization fails
    FlutterNativeSplash.remove();
  }
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'MBYB',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
