import 'package:flutter/material.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Icon(
                  Icons.security_rounded,
                  size: 50,
                  color: isDark ? Colors.teal[300] : Colors.teal[600],
                ),
                const SizedBox(height: 16),
                const Text(
                  'إرشادات المجتمع',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'ساعدنا في إبقاء التبادل في الحرم الجامعي آمناً وموثوقاً للجميع.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const _SafetyCard(
                  title: 'اللقاء في أماكن عامة',
                  description:
                      'رتب دائماً للقاء في مناطق مضاءة جيداً ومكتظة في الحرم الجامعي مثل المكتبة، الساحات، أو نقاط الالتقاء المخصصة.',
                  icon: Icons.location_on_rounded,
                  iconColor: Colors.blue,
                ),

                const _SafetyCard(
                  title: 'تواصل بوضوح',
                  description:
                      'استخدم الدردشة داخل التطبيق لتأكيد تفاصيل اللقاء بما في ذلك التاريخ والوقت والمكان قبل الالتقاء.',
                  icon: Icons.forum_rounded,
                  iconColor: Colors.orange,
                ),
                const _SafetyCard(
                  title: 'الإبلاغ عن المشاكل',
                  description:
                      'إذا واجهت أي سلوك مشبوه أو تصرف غير لائق، قم بالإبلاغ عنه فوراً من خلال التطبيق.',
                  icon: Icons.report_problem_rounded,
                  iconColor: Colors.red,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SafetyCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;

  const _SafetyCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
