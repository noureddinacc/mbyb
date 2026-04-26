class Validators {
  static bool isValidStudentEmail(String email, String domain) {
    // must end with the specific university domain (case-insensitive)
    final escapedDomain = domain.replaceAll('.', r'\.');
    final regExp = RegExp(
      "^[a-zA-Z0-9._%+-]+@$escapedDomain\$",
      caseSensitive: false,
    );
    return regExp.hasMatch(email);
  }

  static String extractStudentId(String email) {
    return email.split('@').first;
  }

  static String? validateEmail(String? value, {String? requiredDomain, List<String>? adminEmails}) {
    if (value == null || value.isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }
    
    final email = value.trim().toLowerCase();

    // Check if it's an admin email (global or specific)
    if (adminEmails != null && adminEmails.any((e) => e.toLowerCase() == email)) {
      return null;
    }
    
    // Fallback for your original master admin
    if (email == 'solosoulacc@tutamail.com') {
      return null;
    }

    if (requiredDomain != null) {
      if (!isValidStudentEmail(email, requiredDomain)) {
        return 'يرجى إدخال بريد جامعي صالح (@$requiredDomain)';
      }
    } else {
      // Basic email validation if no domain is specified
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        return 'يرجى إدخال بريد إلكتروني صالح';
      }
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    if (value.length < 6) {
      return 'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'يرجى تأكيد كلمة المرور';
    }
    if (value != password) {
      return 'كلمات المرور غير متطابقة';
    }
    return null;
  }
}
