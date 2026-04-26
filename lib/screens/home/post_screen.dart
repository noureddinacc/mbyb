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
  String _bookType = 'free'; // 'free' or 'exchange' or 'request'
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

  Widget _buildTypeSelector(String type, String label, Color selectedColor) {
    final isSelected = _bookType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _bookType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? selectedColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : (isDark ? Colors.grey[500] : Colors.grey[600]),
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hintText, {String? helperText}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      filled: true,
      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
      hintText: hintText,
      hintStyle: TextStyle(color: isDark ? Colors.grey[700] : Colors.grey[400], fontSize: 14),
      helperText: helperText,
      helperStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[500], fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: isDark ? Colors.teal[700]! : Colors.blue[300]!, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red[300]!, width: 1.5),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool isRequired = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.red[900]!.withValues(alpha: 0.2) : Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: isDark ? Colors.red[300] : Colors.red[700]),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    _buildSectionTitle('نوع المنشور', isRequired: true),
                    Row(
                      children: [
                        _buildTypeSelector('free', 'مجاني', isDark ? Colors.green[900]! : Colors.green[600]!),
                        _buildTypeSelector('exchange', 'تبادل', isDark ? Colors.blue[900]! : Colors.blue[600]!),
                        _buildTypeSelector('request', 'مطلوب', isDark ? Colors.purple[900]! : Colors.purple[600]!),
                      ],
                    ),
                    const SizedBox(height: 28),

                    _buildSectionTitle('الكلية', isRequired: true),
                    DropdownButtonFormField(
                      value: _selectedFaculty,
                      isExpanded: true,
                      dropdownColor: isDark ? const Color(0xFF1A1D1E) : Colors.white,
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                      items: faculties.map((faculty) {
                        return DropdownMenuItem(
                          value: faculty,
                          child: Text(
                            faculty, 
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedFaculty = value;
                        });
                      },
                      decoration: _buildInputDecoration('اختر الكلية'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى اختيار الكلية';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    _buildSectionTitle('عنوان الكتاب', isRequired: true),
                    TextFormField(
                      controller: _titleController,
                      maxLength: _titleMaxLength,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: _buildInputDecoration(
                        'مثال: كتاب التفاضل والتكامل 101',
                        helperText: 'الحد الأقصى $_titleMaxLength حرفاً',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'العنوان مطلوب';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildSectionTitle('المؤلف (اختياري)'),
                    TextFormField(
                      controller: _authorController,
                      maxLength: _authorMaxLength,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: _buildInputDecoration(
                        'اسم مؤلف الكتاب',
                        helperText: 'الحد الأقصى $_authorMaxLength حرفاً',
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildSectionTitle('وصف الكتاب (اختياري)'),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      maxLength: 150,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: _buildInputDecoration(
                        'أضف أي تفاصيل أخرى عن الكتاب...',
                        helperText: 'الحد الأقصى 150 حرفاً',
                      ),
                    ),
                    
                    if (_bookType != 'request') ...[
                      const SizedBox(height: 16),
                      _buildSectionTitle('حالة الكتاب', isRequired: true),
                      DropdownButtonFormField(
                        value: _conditionController.text.isEmpty
                            ? null
                            : _conditionController.text,
                        dropdownColor: isDark ? const Color(0xFF1A1D1E) : Colors.white,
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                        items: _conditions.map((condition) {
                          return DropdownMenuItem(
                            value: condition,
                            child: Row(
                              children: [
                                Icon(
                                  BookIcons.getConditionIcon(condition),
                                  size: 18,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  condition,
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _conditionController.text = value ?? '';
                          });
                        },
                        decoration: _buildInputDecoration('اختر حالة الكتاب'),
                        validator: (value) {
                          if (_bookType != 'request' && (value == null || value.isEmpty)) {
                            return 'يرجى اختيار حالة الكتاب';
                          }
                          return null;
                        },
                      ),
                    ],

                    if (_bookType == 'exchange') ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.blue[900]!.withValues(alpha: 0.2) : Colors.blue[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? Colors.blue[800]! : Colors.blue[100]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.swap_horiz, color: isDark ? Colors.blue[300] : Colors.blue[700], size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'تفاصيل المبادلة',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.blue[200] : Colors.blue[900],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _exchangeDetailsController,
                              maxLength: _exchangeDetailsMaxLength,
                              maxLines: 2,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                                hintText: 'ما الكتاب الذي تريده في المقابل؟',
                                hintStyle: TextStyle(color: isDark ? Colors.grey[700] : Colors.grey[400], fontSize: 13),
                                contentPadding: const EdgeInsets.all(12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: isDark ? Colors.blue[900]! : Colors.blue[200]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: isDark ? Colors.blue[700]! : Colors.blue[400]!, width: 1.5),
                                ),
                              ),
                              validator: (value) {
                                if (_bookType == 'exchange' &&
                                    (value == null || value.trim().isEmpty)) {
                                  return 'يرجى تحديد ما تريده في المقابل';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 40),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _onPostBook,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.green[900] : Colors.green[600],
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading 
                            ? const SizedBox(
                                height: 24, 
                                width: 24, 
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                              )
                            : const Text(
                                'نشر الكتاب',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
    );
  }
}
