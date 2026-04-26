import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/request_service.dart';
import '../../services/chat_service.dart';
import '../../models/request.dart';
import '../../models/chat.dart';
import 'home_screen.dart';
import 'post_screen.dart';
import 'requests_screen.dart';
import 'chats_screen.dart';
import 'rules_screen.dart';
import 'blocked_screen.dart';
import '../../providers/service_providers.dart';
import '../../providers/book_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/admin_provider.dart';
import '../admin/admin_reports_screen.dart';
import 'system_messages_screen.dart';
import 'package:go_router/go_router.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;
  bool _isSearching = false;
  final _searchController = TextEditingController();

  final List<Widget> _screens = [
    const HomeScreen(),
    const PostScreen(),
    const RequestsScreen(),
    const ChatsScreen(),
    const RulesScreen(),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onNavBarItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showFilterBottomSheeet() {
    final faculties = [
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
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final selectedFaculty = ref.watch(facultyFilterProvider);
            final selectedPostType = ref.watch(postTypeFilterProvider);

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تصفية',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: selectedFaculty,
                      isExpanded: true,
                      hint: const Text('جميع الكليات'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('جميع الكليات'),
                        ),
                        ...faculties.map((faculty) {
                          return DropdownMenuItem(
                            value: faculty,
                            child: Text(faculty, overflow: TextOverflow.ellipsis),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        ref.read(facultyFilterProvider.notifier).setFilter(value);
                      },
                      decoration: InputDecoration(
                        labelText: 'الكلية',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.school_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedPostType,
                      isExpanded: true,
                      hint: const Text('جميع الأنواع'),
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('جميع الأنواع'),
                        ),
                        DropdownMenuItem(
                          value: 'free',
                          child: Text('مجاني'),
                        ),
                        DropdownMenuItem(
                          value: 'exchange',
                          child: Text('للمبادلة'),
                        ),
                        DropdownMenuItem(
                          value: 'request',
                          child: Text('مطلوب'),
                        ),
                      ],
                      onChanged: (value) {
                        ref.read(postTypeFilterProvider.notifier).setFilter(value);
                      },
                      decoration: InputDecoration(
                        labelText: 'نوع المنشور',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.category_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('تطبيق'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).value;

    if (currentUser == null) {
      return _buildMainScaffold(null);
    }

    return StreamBuilder<bool>(
      stream: ref.watch(authServiceProvider).isUserBlocked(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.data == true) {
          return const BlockedScreen();
        }
        
        // Wrap with TabController specifically for RequestsScreen (index 2)
        return DefaultTabController(
          length: 2,
          child: _buildMainScaffold(currentUser),
        );
      },
    );
  }

  AppBar _buildAppBar(dynamic currentUser) {
    final selectedFaculty = ref.watch(facultyFilterProvider);
    
    switch (_selectedIndex) {
      case 0: // Home
        return AppBar(
          title: _isSearching
              ? Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (val) {
                      ref.read(searchQueryProvider.notifier).setQuery(val);
                    },
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'بحث...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                )
              : const Text('الرئيسية'),
          actions: [
            if (currentUser != null)
              StreamBuilder<int>(
                stream: ref.read(systemMessageServiceProvider).getUnreadCount(currentUser.uid),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;
                  return IconButton(
                    icon: Badge(
                      isLabelVisible: unreadCount > 0,
                      label: Text(unreadCount.toString()),
                      child: const Icon(Icons.notifications_outlined),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SystemMessagesScreen()),
                      );
                    },
                  );
                },
              ),
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  if (_isSearching) {
                    _isSearching = false;
                    _searchController.clear();
                    ref.read(searchQueryProvider.notifier).setQuery('');
                  } else {
                    _isSearching = true;
                  }
                });
              },
            ),
            IconButton(
              icon: Icon(
                (selectedFaculty == null && ref.watch(postTypeFilterProvider) == null) 
                    ? Icons.filter_alt_outlined 
                    : Icons.filter_alt,
                color: (selectedFaculty == null && ref.watch(postTypeFilterProvider) == null) 
                    ? null 
                    : Colors.green,
              ),
              onPressed: _showFilterBottomSheeet,
            ),
          ],
        );
      case 1: // Post
        return AppBar(title: const Text('نشر كتاب'));
      case 2: // Requests
        return AppBar(
          title: const Text('الطلبات'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'المستلمة'),
              Tab(text: 'المرسلة'),
            ],
          ),
        );
      case 3: // Chats
        return AppBar(
          title: const Text('محادثاتي'),
          actions: [
            Consumer(
              builder: (context, ref, _) {
                final archivedAsync = ref.watch(archivedChatsProvider);
                final hasUnreadInArchive = archivedAsync.maybeWhen(
                  data: (chats) => chats.any((chat) {
                    final lastSeen = chat.lastSeenAt[currentUser.uid];
                    return lastSeen == null || chat.updatedAt.isAfter(lastSeen);
                  }),
                  orElse: () => false,
                );
                return IconButton(
                  onPressed: () => context.push('/archived-chats'),
                  icon: Badge(
                    isLabelVisible: hasUnreadInArchive,
                    backgroundColor: Colors.red,
                    smallSize: 8,
                    child: const Icon(Icons.archive_outlined),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        );
      case 4: // Rules
        return AppBar(title: const Text('الإرشادات'));
      default:
        return AppBar(title: const Text('MBYB'));
    }
  }

  Widget _buildDrawer(dynamic currentUser) {
    if (currentUser == null) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // Premium Airy Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
            decoration: BoxDecoration(
              color: isDark ? Colors.teal.withValues(alpha: 0.1) : Colors.green[50]?.withValues(alpha: 0.5),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: isDark ? Colors.teal[900] : Colors.green[100],
                  child: Icon(Icons.person, color: isDark ? Colors.teal[200] : Colors.green[700], size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مرحباً بك',
                        style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey, fontSize: 12),
                      ),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          currentUser.email ?? 'مستخدم',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Navigation Items
          _buildDrawerItem(
            icon: Icons.home_rounded,
            label: 'الرئيسية',
            color: Colors.teal,
            isSelected: false,
            showBackground: false,
            onTap: () {
              Navigator.pop(context);
              if (_selectedIndex != 0) {
                setState(() => _selectedIndex = 0);
              }
            },
          ),
          _buildDrawerItem(
            icon: Icons.collections_bookmark_rounded,
            label: 'منشوراتي',
            color: Colors.teal,
            isSelected: false,
            showBackground: false,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyPostsScreen()),
              );
            },
          ),
          if (ref.watch(isAdminProvider))
            _buildDrawerItem(
              icon: Icons.admin_panel_settings_rounded,
              label: 'إدارة التقارير',
              color: Colors.teal,
              isSelected: false,
              showBackground: false,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminReportsScreen()),
                );
              },
            ),
          
          const Spacer(),

          // Dark Mode Toggle - Option 1: Bottom of Drawer
          Divider(color: isDark ? Colors.grey[800] : Colors.grey[100], height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListTile(
              leading: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: isDark ? Colors.teal[300] : Colors.orange[400],
              ),
              title: Text(
                'الوضع الليلي',
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              trailing: Switch.adaptive(
                value: isDark,
                activeColor: Colors.teal[300],
                onChanged: (val) {
                  ref.read(themeModeProvider.notifier).toggleTheme(val);
                },
              ),
            ),
          ),

          // Logout Section
          Divider(color: isDark ? Colors.grey[800] : Colors.grey[100], height: 1),
          _buildDrawerItem(
            icon: Icons.logout_rounded,
            label: 'تسجيل الخروج',
            color: Colors.red,
            isSelected: false,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: AlertDialog(
                    title: const Text('تسجيل الخروج'),
                    content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('إلغاء'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('خروج', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              );
              
              if (confirm == true) {
                await ref.read(authServiceProvider).logOut();
                if (context.mounted) context.go('/login');
              }
            },
          ),
          const SizedBox(height: 10),
          Text(
            'MBYB v2.0.0', // Updated version to celebrate UI 2.0
            style: TextStyle(color: isDark ? Colors.grey[700] : Colors.grey[300], fontSize: 10),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required Color color,
    bool isSelected = false,
    bool showBackground = true,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: showBackground ? color.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? color : (isDark ? Colors.white : Colors.black87),
          ),
        ),
        selected: isSelected,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
  Widget _buildMainScaffold(dynamic currentUser) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: _buildAppBar(currentUser),
        drawer: _selectedIndex == 0 ? _buildDrawer(currentUser) : null,
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onNavBarItemTapped,
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'الرئيسية',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              label: 'نشر',
            ),
            BottomNavigationBarItem(
              icon: currentUser == null
                  ? const Icon(Icons.notifications)
                  : StreamBuilder<List<RequestModel>>(
                      stream: RequestService().getIncomingRequests(
                        currentUser.uid,
                      ),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.length ?? 0;
                        return Badge(
                          isLabelVisible: count > 0,
                          label: Text(count.toString()),
                          backgroundColor: Colors.red,
                          child: const Icon(Icons.notifications),
                        );
                      },
                    ),
              label: 'الطلبات',
            ),
            BottomNavigationBarItem(
              icon: currentUser == null
                  ? const Icon(Icons.chat)
                  : StreamBuilder<List<ChatModel>>(
                      stream: ChatService().getActiveChats(currentUser.uid),
                      builder: (context, snapshot) {
                        final unreadCount = snapshot.hasData 
                            ? snapshot.data!.where((chat) {
                                final lastSeen = chat.lastSeenAt[currentUser.uid];
                                if (lastSeen == null) return true;
                                return chat.updatedAt.isAfter(lastSeen);
                              }).length
                            : 0;

                        return Badge(
                          isLabelVisible: unreadCount > 0,
                          label: Text(unreadCount.toString()),
                          backgroundColor: Colors.red,
                          child: const Icon(Icons.chat),
                        );
                      },
                    ),
              label: 'المحادثات',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.info),
              label: 'الإرشادات',
            ),
          ],
        ),
      ),
    );
  }
}
