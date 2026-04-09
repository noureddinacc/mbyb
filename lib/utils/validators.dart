class Validators {
  static bool isValidStudentEmail(String email) {
    // must end with @st.aabu.edu.jo (case-insensitive)
    final regExp = RegExp(
      r"^[a-zA-Z0-9._%+-]+@st\.aabu\.edu\.jo$",
      caseSensitive: false,
    );
    return regExp.hasMatch(email);
  }

  static String extractStudentId(String email) {
    return email.split('@').first;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }
    const extraValidEmail = 'solosoulacc@tutamail.com';
    if (value.trim().toLowerCase() == extraValidEmail.toLowerCase()) {
      return null;
    }

    if (!isValidStudentEmail(value.trim())) {
      return 'يرجى إدخال بريد جامعي صالح (@st.aabu.edu.jo)';
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
