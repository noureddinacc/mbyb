import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/book_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/rounded_button.dart';
import '../../utils/book_icons.dart';

const List<String> faculties = [
  'كلية الآداب والعلوم الإنسانية',
  'كلية العلوم',
  'كلية الشريعة',
  'كلية الهندسة',
  'كلية الأمير الحسين بن عبدالله لتكنولوجيا المعلومات',
  'كلية الاقتصاد والعلوم الإدارية',
  'كلية الحقوق',
  'كلية العلوم التربوية',
  'كلية الأميرة سلمى للتمريض',
  'كلية اللغات الأجنبية',
  'كلية علوم الطيران',
  'كلية التربية البدنية وعلوم الرياضة',
  'كلية العلوم الطبية التطبيقية',
  'كلية التعليم الفني',
];

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _conditionController = TextEditingController();
  final _exchangeDetailsController = TextEditingController();

  final _bookService = BookService();
  final _authService = AuthService();

  String? _selectedFaculty;
  String _bookType = 'free'; // 'free' or 'exchange'
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _conditions = ['جديد بحالة ممتازة', 'جيد', 'مقبول', 'سيء', 'غير محدد'];
  final int _titleMaxLength = 50;
  final int _authorMaxLength = 50;
  final int _exchangeDetailsMaxLength = 150;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _conditionController.dispose();
    _exchangeDetailsController.dispose();
    super.dispose();
  }

  void _onPostBook() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final userId = _authService.currentUser?.uid;
        if (userId == null) {
          throw Exception('المستخدم غير مصدق');
        }

        await _bookService.uploadBook(
          publisherId: userId,
          title: _titleController.text.trim(),
          author: _authorController.text.trim(),
          faculty: _selectedFaculty!,
          description: _descriptionController.text.trim(),
          condition: _bookType == 'request' ? 'غير محدد' : _conditionController.text,
          postType: _bookType,
          exchangeDetails: _bookType == 'exchange'
              ? _exchangeDetailsController.text.trim()
              : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('تم نشر الكتاب بنجاح!'),
                backgroundColor: Colors.green,
              ),
            );
          _titleController.clear();
          _authorController.clear();
          _descriptionController.clear();
          _conditionController.clear();
          _exchangeDetailsController.clear();
          setState(() {
            _selectedFaculty = null;
            _bookType = 'free';
          });
          // Navigate to home screen
          context.go('/home');
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
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
                    const Text(
                      'نوع المنشور',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    RadioListTile<String>(
                      title: const Text('أعرض كتاباً مجانياً'),
                      value: 'free',
                      groupValue: _bookType,
                      onChanged: (value) {
                        setState(() {
                          _bookType = value ?? 'free';
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<String>(
                      title: const Text('أعرض كتاباً للمبادلة'),
                      value: 'exchange',
                      groupValue: _bookType,
                      onChanged: (value) {
                        setState(() {
                          _bookType = value ?? 'free';
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<String>(
                      title: const Text('أطلب كتاباً'),
                      value: 'request',
                      groupValue: _bookType,
                      onChanged: (value) {
                        setState(() {
                          _bookType = value ?? 'free';
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField(
                      initialValue: _selectedFaculty,
                      isExpanded: true,
                      items: faculties.map((faculty) {
                        return DropdownMenuItem(
                          value: faculty,
                          child: Text(faculty, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedFaculty = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'اختر الكلية',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى اختيار الكلية';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      maxLength: _titleMaxLength,
                      decoration: InputDecoration(
                        labelText: 'عنوان الكتاب',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        helperText: 'الحد الأقصى $_titleMaxLength حرفاً',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'العنوان مطلوب';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _authorController,
                      maxLength: _authorMaxLength,
                      decoration: InputDecoration(
                        labelText: 'المؤلف (اختياري)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        helperText: 'الحد الأقصى $_authorMaxLength حرفاً',
                      ),
                      validator: (value) {
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      maxLength: 150,
                      decoration: InputDecoration(
                        labelText: 'وصف الكتاب (اختياري)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        helperText: 'الحد الأقصى 150 حرفاً',
                      ),
                      validator: (value) {
                        return null;
                      },
                    ),
                    if (_bookType != 'request') ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField(
                        initialValue: _conditionController.text.isEmpty
                            ? null
                            : _conditionController.text,
                        items: _conditions.map((condition) {
                          return DropdownMenuItem(
                            value: condition,
                            child: Row(
                              children: [
                                Icon(
                                  BookIcons.getConditionIcon(condition),
                                  size: 18,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(width: 8),
                                Text(condition),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _conditionController.text = value ?? '';
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'حالة الكتاب',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        validator: (value) {
                          if (_bookType != 'request' && (value == null || value.isEmpty)) {
                            return 'يرجى اختيار حالة الكتاب';
                          }
                          return null;
                        },
                      ),
                    ],

                    if (_bookType == 'exchange') ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _exchangeDetailsController,
                        maxLength: _exchangeDetailsMaxLength,
                        decoration: InputDecoration(
                          labelText: 'ما الكتاب الذي تريده في المقابل؟',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          helperText:
                              'الحد الأقصى $_exchangeDetailsMaxLength حرفاً',
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (_bookType == 'exchange' &&
                              (value == null || value.isEmpty)) {
                            return 'يرجى تحديد ما تريده في المقابل';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: RoundedButton(
                        text: _isLoading ? 'جاري الرفع...' : 'نشر الكتاب',
                        onPressed: _isLoading ? () {} : _onPostBook,
                        enabled: !_isLoading,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    );
  }
}
