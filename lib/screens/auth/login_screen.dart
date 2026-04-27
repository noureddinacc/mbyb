import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  bool _showAdminLogin = false;
  University? _selectedUniversity;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final rawEmail = _emailController.text.trim().toLowerCase();
    final isMasterAdmin = rawEmail == 'solosoulacc@tutamail.com';

    // Admins (except master) must select their university first
    if (!isMasterAdmin && _selectedUniversity == null) {
      setState(() {
        _errorMessage = 'يرجى اختيار جامعتك أولاً.';
      });
      return;
    }

    // Check if the email belongs to the specific selected university's admin list
    bool isUniAdmin = false;
    if (_selectedUniversity != null) {
      isUniAdmin = _selectedUniversity!.adminEmails.any((e) => e.toLowerCase() == rawEmail);
    }
    
    final isAdmin = isMasterAdmin || isUniAdmin;

    // Strict Security: Reject non-admins immediately without hitting Firebase
    if (!isAdmin) {
      setState(() {
        _errorMessage = 'عذراً، هذا البريد غير مسجل كمسؤول في الجامعة المحددة.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final password = _passwordController.text;

      await _authService.logIn(
        email: rawEmail,
        password: password,
        universityId: _selectedUniversity?.id,
      );
      await _authService.refreshUser();

      if (!mounted) return;
      ref.read(authRefreshTriggerProvider.notifier).trigger();

    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message ?? 'حدث خطأ أثناء المصادقة';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'حدث خطأ غير متوقع: $e';
        });
      }
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  void _onMicrosoftLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithMicrosoft();

      if (!mounted) return;
      ref.read(authRefreshTriggerProvider.notifier).trigger();

      // Successfully logged in via Microsoft
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              e.message ?? 'حدث خطأ أثناء تسجيل الدخول باستخدام حساب الجامعة';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'حدث خطأ غير متوقع: $e';
        });
      }
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo & Welcome Section
                    Image.asset('assets/in/app-logo.png', height: 80),
                    const SizedBox(height: 24),
                    Text(
                      'مرحباً بعودتك',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedUniversity != null
                          ? 'سجل دخولك إلى ${_selectedUniversity!.name}'
                          : 'سجل دخولك للمتابعة في مجتمع MBYB',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                    ),
                  const SizedBox(height: 40),

                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: _errorMessage!.contains('تم إرسال')
                            ? (isDark
                                  ? Colors.orange[900]!.withValues(alpha: 0.2)
                                  : Colors.orange[50])
                            : (isDark
                                  ? Colors.red[900]!.withValues(alpha: 0.2)
                                  : Colors.red[50]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _errorMessage!.contains('تم إرسال')
                                ? Icons.mail_outline
                                : Icons.error_outline,
                            color: _errorMessage!.contains('تم إرسال')
                                ? Colors.orange
                                : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: _errorMessage!.contains('تم إرسال')
                                    ? (isDark
                                          ? Colors.orange[300]
                                          : Colors.orange[800])
                                    : Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Primary Login: Microsoft
                  ElevatedButton(
                    onPressed: _isLoading ? null : _onMicrosoftLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      backgroundColor: isDark ? Colors.green[800] : Colors.green[600],
                      foregroundColor: Colors.white,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Image.asset(
                            'assets/microsoft-logo.png',
                            height: 18,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.account_balance, size: 18, color: Colors.black),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'تسجيل الدخول بحساب الجامعة',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Toggle Admin Login Button
                  TextButton(
                    onPressed: () => setState(() => _showAdminLogin = !_showAdminLogin),
                    child: Text(
                      _showAdminLogin ? 'تسجيل دخول الإدارة' : 'دخول الإدارة',
                      style: TextStyle(
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ),

                  if (_showAdminLogin) ...[
                    const SizedBox(height: 24),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // University Dropdown
                        Text(
                      'الجامعة (إن وجدت)',
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
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[700] : Colors.grey[400],
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          prefixIcon: Icon(
                            Icons.school_outlined,
                            size: 20,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        items: universities
                            .map(
                              (u) =>
                                  DropdownMenuItem(value: u, child: Text(u.name)),
                            )
                            .toList(),
                        onChanged: (u) {
                          setState(() {
                            _selectedUniversity = u;
                            _emailController.clear();
                          });
                        },
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('خطأ في تحميل الجامعات: $e'),
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    Text(
                      'البريد الإلكتروني للإدارة',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      textAlign: TextAlign.left,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'admin@university.edu.jo',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[700] : Colors.grey[300],
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        prefixIcon: Icon(
                          Icons.alternate_email_rounded,
                          size: 20,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'البريد الإلكتروني مطلوب';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    Text(
                      'كلمة المرور',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textAlign: TextAlign.left,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[700] : Colors.grey[300],
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline_rounded,
                          size: 20,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 20,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: Validators.validatePassword,
                    ),

                    const SizedBox(height: 32),

                    // Login Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _onLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? Colors.green[900]
                            : Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'دخول الإدارة',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  }
}
