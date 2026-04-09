import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/rounded_button.dart';
import '../../utils/validators.dart';
import '../../services/auth_service.dart';
import '../../providers/auth_provider.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text;
        
        await _authService.logIn(email: email, password: password);
        
        // Force fresh fetch from Firebase servers (local cache can be stale)
        await _authService.refreshUser();
        // Trigger a refresh of the authStateProvider so GoRouter can see the new verified status
        ref.read(authRefreshTriggerProvider.notifier).trigger();
        
        // If the user's email is not yet verified, reject the login
        if (!_authService.isEmailVerified) {
          try {
            await _authService.sendVerificationEmail();
          } catch (_) {
            // Ignore quota/rate-limit errors for resending
          }
          setState(() {
            _errorMessage = 'يجب التحقق من البريد الإلكتروني. تم إرسال رابط جديد إلى بريدك الجامعي.';
          });
          await _authService.logOut();
          return;
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = e.message ?? 'حدث خطأ أثناء المصادقة';
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'حدث خطأ غير متوقع';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.vertical,
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset('assets/in/app-logo.png', height: 250),
                    const SizedBox(height: 24),
                    const Text(
                      'مرحباً بعودتك',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    if (_errorMessage != null) const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.validateEmail,
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        onPressed: () {
                          final text = _emailController.text;
                          if (!text.contains('@')) {
                            _emailController.text = '$text@st.aabu.edu.jo';
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('@st.aabu.edu.jo', textDirection: TextDirection.ltr),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: Validators.validatePassword,
                    ),
                    const SizedBox(height: 32),
                    RoundedButton(
                      text: _isLoading ? 'جاري تسجيل الدخول...' : 'تسجيل الدخول',
                      onPressed: _isLoading ? () {} : _onLogin,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              context.go('/signup');
                            },
                      child: const Text('ليس لديك حساب؟ إنشاء حساب'),
                    ),
                  ],
                ),
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }
}
