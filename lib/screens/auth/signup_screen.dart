import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/rounded_button.dart';
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
        
        setState(() {
          _errorMessage =
              'تم إنشاء الحساب بنجاح! يرجى التحقق من بريدك الإلكتروني لتسجيل الدخول.';
        });
        await ref.read(authServiceProvider).logOut();
        return;
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
    final universitiesAsync = ref.watch(universitiesProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
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
                      Image.asset('assets/in/app-logo.png', height: 180),
                      const SizedBox(height: 16),
                      const Text(
                        'إنشاء حساب جديد',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      
                      // University Selection
                      universitiesAsync.when(
                        data: (universities) => DropdownButtonFormField<University>(
                          value: _selectedUniversity,
                          decoration: InputDecoration(
                            labelText: 'اختر جامعتك',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: const Icon(Icons.school_outlined),
                          ),
                          items: universities.map((u) => DropdownMenuItem(
                            value: u,
                            child: Text(u.name),
                          )).toList(),
                          onChanged: (u) {
                            setState(() {
                              _selectedUniversity = u;
                              _emailController.clear(); // Clear email when university changes
                            });
                          },
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (e, _) => Text('خطأ في تحميل الجامعات: $e'),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'البريد الإلكتروني الجامعي',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => Validators.validateEmail(
                          value, 
                          requiredDomain: _selectedUniversity?.emailDomain,
                          adminEmails: _selectedUniversity?.adminEmails,
                        ),
                      ),
                      if (_selectedUniversity != null)
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton(
                            onPressed: () {
                              final text = _emailController.text;
                              if (!text.contains('@')) {
                                _emailController.text = '$text@${_selectedUniversity!.emailDomain}';
                              }
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              '@${_selectedUniversity!.emailDomain}',
                              textDirection: TextDirection.ltr,
                            ),
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
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
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
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmController,
                        decoration: InputDecoration(
                          labelText: 'تأكيد كلمة المرور',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscureConfirmPassword,
                        validator: (value) =>
                            Validators.validateConfirmPassword(
                              value,
                              _passwordController.text,
                            ),
                      ),
                      const SizedBox(height: 32),
                      RoundedButton(
                        text: _isLoading
                            ? 'جاري إنشاء الحساب...'
                            : 'إنشاء حساب',
                        onPressed: _isLoading ? () {} : _onSignup,
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                context.go('/login');
                              },
                        child: const Text('لديك حساب بالفعل؟ تسجيل الدخول'),
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
