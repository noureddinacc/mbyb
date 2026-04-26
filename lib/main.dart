import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/theme_provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'providers/service_providers.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  try {
    // Initialize Firebase and SharedPreferences in parallel for speed
    final results = await Future.wait([
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
      SharedPreferences.getInstance(),
    ]);

    final prefs = results[1] as SharedPreferences;

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
    FlutterNativeSplash.remove();
  }
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp.router(
      title: 'MBYB',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
