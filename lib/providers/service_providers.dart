import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/book_service.dart';
import '../services/chat_service.dart';
import '../services/request_service.dart';
import '../services/system_message_service.dart';
import '../services/university_service.dart';
import '../models/university.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final bookServiceProvider = Provider<BookService>((ref) {
  return BookService();
});

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

final requestServiceProvider = Provider<RequestService>((ref) {
  return RequestService();
});

final systemMessageServiceProvider = Provider<SystemMessageService>((ref) {
  return SystemMessageService();
});

final universityServiceProvider = Provider<UniversityService>((ref) {
  return UniversityService();
});

final universitiesProvider = StreamProvider<List<University>>((ref) {
  return ref.watch(universityServiceProvider).getUniversitiesStream();
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(); // This will be overridden in main.dart
});
