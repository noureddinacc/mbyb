import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../utils/validators.dart';
import '../../services/auth_service.dart';

import '../../models/university.dart';
import '../../providers/service_providers.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  
  University? _selectedUniversity;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onSignup() async {
    if (_selectedUniversity == null) {
      setState(() => _errorMessage = 'يرجى اختيار الجامعة');
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text;

        await ref.read(authServiceProvider).signUp(
          email: email, 
          password: password,
          universityId: _selectedUniversity!.id,
        );
        
        if (mounted) {
          setState(() {
            _errorMessage = 'تم إنشاء الحساب بنجاح! يرجى التحقق من بريدك الإلكتروني لتسجيل الدخول.';
          });
        }
        await ref.read(authServiceProvider).logOut();
        return;
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          setState(() { _errorMessage = e.message ?? 'حدث خطأ أثناء المصادقة'; });
        }
      } catch (e) {
        if (mounted) {
          setState(() { _errorMessage = 'حدث خطأ غير متوقع'; });
        }
      } finally {
        if (mounted) setState(() { _isLoading = false; });
      }
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
                  const SizedBox(height: 40),
                  // Logo & Welcome Section
                  Center(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/in/app-logo.png', height: 60),
                            if (_selectedUniversity?.logoUrl != null) ...[
                              const SizedBox(width: 16),
                              Container(
                                width: 2,
                                height: 30,
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
                          'إنشاء حساب جديد',
                          style: TextStyle(
                            fontSize: 28, 
                            fontWeight: FontWeight.w900, 
                            color: isDark ? Colors.white : Colors.black87
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedUniversity != null
                            ? 'انضم إلى مجتمع ${_selectedUniversity!.name}'
                            : 'انضم إلى مجتمع MBYB لتبادل الكتب مع زملائك',
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
                        color: _errorMessage!.contains('بنجاح') 
                            ? (isDark ? Colors.green[900]!.withValues(alpha: 0.2) : Colors.green[50])
                            : (isDark ? Colors.red[900]!.withValues(alpha: 0.2) : Colors.red[50]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _errorMessage!.contains('بنجاح') ? Icons.check_circle_outline : Icons.error_outline, 
                            color: _errorMessage!.contains('بنجاح') ? Colors.green : Colors.red, 
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: _errorMessage!.contains('بنجاح') 
                                    ? (isDark ? Colors.green[300] : Colors.green[700]) 
                                    : (isDark ? Colors.red[300] : Colors.red), 
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // University Selection
                  Text(
                    'الجامعة', 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black
                    )
                  ),
                  const SizedBox(height: 8),
                  universitiesAsync.when(
                    data: (universities) => DropdownButtonFormField<University>(
                      value: _selectedUniversity,
                      decoration: InputDecoration(
                        hintText: 'اختر جامعتك',
                        hintStyle: TextStyle(color: isDark ? Colors.grey[700] : Colors.grey[300], fontSize: 14),
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
                      final universities = universitiesAsync.value ?? [];
                      final allAdmins = universities
                          .expand((u) => u.adminEmails)
                          .toList();
                      
                      return Validators.validateEmail(
                        value,
                        requiredDomain: _selectedUniversity?.emailDomain,
                        adminEmails: _selectedUniversity?.adminEmails,
                        allAdminEmails: allAdmins,
                      );
                    },
                  ),
                  // Smart Shortcut
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
                  
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  Text(
                    'تأكيد كلمة المرور', 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black
                    )
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: _obscureConfirmPassword,
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
                      prefixIcon: Icon(Icons.lock_clock_outlined, size: 20, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, size: 20, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                    ),
                    validator: (value) => Validators.validateConfirmPassword(value, _passwordController.text),
                  ),

                  const SizedBox(height: 32),

                  // Signup Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _onSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.green[900] : Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('إنشاء الحساب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),

                  const SizedBox(height: 24),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('لديك حساب بالفعل؟', style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600])),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text(
                          'تسجيل الدخول', 
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
