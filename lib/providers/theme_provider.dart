import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'service_providers.dart';

class ThemeNotifier extends Notifier<ThemeMode> {
  static const _themeKey = 'theme_mode';

  @override
  ThemeMode build() {
    // Read the pre-initialized SharedPreferences
    final prefs = ref.watch(sharedPreferencesProvider);
    final themeIndex = prefs.getInt(_themeKey);
    
    if (themeIndex != null) {
      return ThemeMode.values[themeIndex];
    }
    return ThemeMode.light;
  }

  Future<void> toggleTheme(bool isDark) async {
    final newMode = isDark ? ThemeMode.dark : ThemeMode.light;
    state = newMode;
    
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_themeKey, newMode.index);
  }
}

final themeModeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);
