import 'package:flutter/material.dart';

class BookIcons {
  static IconData getConditionIcon(String condition) {
    switch (condition) {
      case 'جديد بحالة ممتازة':
        return Icons.star;
      case 'جيد':
        return Icons.thumb_up;
      case 'مقبول':
        return Icons.warning;
      case 'سيء':
        return Icons.heart_broken_rounded;
      default:
        return Icons.menu_book;
    }
  }
}
