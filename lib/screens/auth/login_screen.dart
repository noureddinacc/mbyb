import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../utils/validators.dart';
import '../../services/auth_service.dart';
import '../../providers/auth_provider.dart';
import '../../models/university.dart';
import '../../providers/service_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  University? _selectedUniversity;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() async {
    final rawEmail = _emailController.text.trim().toLowerCase();
    final isMasterAdmin = rawEmail == 'solosoulacc@tutamail.com';

    // Everyone except the master admin must select a university
    if (!isMasterAdmin && _selectedUniversity == null) {
      setState(() {
        _errorMessage = 'يرجى اختيار الجامعة أولاً قبل تسجيل الدخول.';
      });
      return;
    }

    // Check if the email belongs to a known admin (using fresh provider data)
    final universities = ref.read(universitiesProvider).value ?? [];
    final isUniAdmin = universities.any((u) =>
      u.adminEmails.any((e) => e.toLowerCase() == rawEmail)
    );
    final isAdmin = isMasterAdmin || isUniAdmin;

    // For admins: skip form domain validation, go straight to sign-in
    // For students: run form validation (domain check etc.)
    if (!isAdmin && !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      await _authService.logIn(
        email: email,
        password: password,
        universityId: _selectedUniversity?.id,
      );
      await _authService.refreshUser();

      if (!mounted) return;
      ref.read(authRefreshTriggerProvider.notifier).trigger();

      if (!isAdmin && !_authService.isEmailVerified) {
        try { await _authService.sendVerificationEmail(); } catch (_) {}
        if (mounted) {
          setState(() {
            _errorMessage = 'يجب التحقق من البريد الإلكتروني. تم إرسال رابط جديد إلى بريدك الجامعي.';
          });
        }
        await _authService.logOut();
        return;
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() { _errorMessage = e.message ?? 'حدث خطأ أثناء المصادقة'; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _errorMessage = 'حدث خطأ غير متوقع: $e'; });
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final universitiesAsync = ref.watch(universitiesProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  // Logo & Welcome Section
                  Center(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/in/app-logo.png', height: 70),
                            if (_selectedUniversity?.logoUrl != null) ...[
                              const SizedBox(width: 16),
                              Container(
                                width: 2,
                                height: 40,
                                color: isDark ? Colors.grey[800] : Colors.grey[300],
                              ),
                              const SizedBox(width: 16),
                              Container(
                                width: 55,
                                height: 55,
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    _selectedUniversity!.logoUrl!,
                                    fit: BoxFit.contain,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                    },
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                      Icons.school_rounded,
                                      color: Colors.green[700],
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'مرحباً بعودتك',
                          style: TextStyle(
                            fontSize: 28, 
                            fontWeight: FontWeight.w900, 
                            color: isDark ? Colors.white : Colors.black87
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedUniversity != null 
                            ? 'سجل دخولك إلى ${_selectedUniversity!.name}'
                            : 'سجل دخولك للمتابعة في مجتمع MBYB',
                          style: TextStyle(
                            fontSize: 14, 
                            color: isDark ? Colors.grey[500] : Colors.grey[500]
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: _errorMessage!.contains('تم إرسال')
                            ? (isDark ? Colors.orange[900]!.withValues(alpha: 0.2) : Colors.orange[50])
                            : (isDark ? Colors.red[900]!.withValues(alpha: 0.2) : Colors.red[50]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _errorMessage!.contains('تم إرسال') ? Icons.mail_outline : Icons.error_outline,
                            color: _errorMessage!.contains('تم إرسال') ? Colors.orange : Colors.red, 
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: _errorMessage!.contains('تم إرسال')
                                    ? (isDark ? Colors.orange[300] : Colors.orange[800])
                                    : Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // University Dropdown
                  Text(
                    'الجامعة',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  universitiesAsync.when(
                    data: (universities) => DropdownButtonFormField<University>(
                      value: _selectedUniversity,
                      decoration: InputDecoration(
                        hintText: 'اختر جامعتك',
                        hintStyle: TextStyle(color: isDark ? Colors.grey[700] : Colors.grey[400], fontSize: 14),
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        prefixIcon: Icon(Icons.school_outlined, size: 20, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                      items: universities.map((u) => DropdownMenuItem(
                        value: u,
                        child: Text(u.name),
                      )).toList(),
                      onChanged: (u) {
                        setState(() {
                          _selectedUniversity = u;
                          _emailController.clear();
                        });
                      },
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('خطأ في تحميل الجامعات: $e'),
                  ),
                  const SizedBox(height: 16),

                  // Email Field
                  Text(
                    'البريد الجامعي', 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black
                    )
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    textAlign: TextAlign.left,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: _selectedUniversity != null
                          ? 'studentID@${_selectedUniversity!.emailDomain}'
                          : 'studentID@university.edu.jo',
                      hintStyle: TextStyle(color: isDark ? Colors.grey[700] : Colors.grey[300], fontSize: 14),
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      prefixIcon: Icon(Icons.alternate_email_rounded, size: 20, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'البريد الإلكتروني مطلوب';
                      }
                      final email = value.trim().toLowerCase();
                      // Basic email format check
                      if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(email)) {
                        return 'يرجى إدخال بريد إلكتروني صالح';
                      }
                      // Domain check only applies to regular students (non-admins)
                      // Admin bypass is handled in _onLogin with fresh data
                      final universities = universitiesAsync.value ?? [];
                      final isAnyAdmin = email == 'solosoulacc@tutamail.com' ||
                        universities.any((u) =>
                          u.adminEmails.any((e) => e.toLowerCase() == email)
                        );
                      if (isAnyAdmin) return null; // Admin: skip domain check
                      if (_selectedUniversity != null) {
                        if (!Validators.isValidStudentEmail(email, _selectedUniversity!.emailDomain)) {
                          return 'يرجى إدخال بريد جامعي صالح (@${_selectedUniversity!.emailDomain})';
                        }
                      }
                      return null;
                    },
                  ),
                  // Smart Shortcut - only shows when a university is selected
                  if (_selectedUniversity != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          final text = _emailController.text.trim();
                          if (text.isNotEmpty && !text.contains('@')) {
                            _emailController.text = '$text@${_selectedUniversity!.emailDomain}';
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline, size: 16),
                        label: Text('@${_selectedUniversity!.emailDomain}', textDirection: TextDirection.ltr),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? Colors.green[300] : Colors.green[700],
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Password Field
                  Text(
                    'كلمة المرور', 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black
                    )
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textAlign: TextAlign.left,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      hintStyle: TextStyle(color: isDark ? Colors.grey[700] : Colors.grey[300]),
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      prefixIcon: Icon(Icons.lock_outline_rounded, size: 20, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: Validators.validatePassword,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _onLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.green[900] : Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('تسجيل الدخول', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('ليس لديك حساب؟', style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600])),
                      TextButton(
                        onPressed: () => context.go('/signup'),
                        child: Text(
                          'إنشاء حساب جديد', 
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.teal[300] : Colors.green[700]
                          )
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
