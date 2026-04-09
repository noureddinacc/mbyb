import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class BlockedScreen extends StatelessWidget {
  const BlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.red[900]!, Colors.red[700]!],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.block_flipped,
                color: Colors.white,
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                'تم حظر حسابك نهائياً',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'لقد تم حظر حسابك لمخالفة سياسات الاستخدام الخاصة بالتطبيق.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: const [
                    Text(
                      'إذا كنت تعتقد أن هناك خطأ، يرجى التواصل معنا عبر البريد الإلكتروني:',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'solosoulacc@tutamail.com',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () async {
                  await AuthService().logOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('تسجيل الخروج'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red[900],
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
