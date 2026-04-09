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
    final selectedFaculty = ref.read(facultyFilterProvider);
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تصفية حسب الكلية',
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
                    Navigator.pop(ctx);
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.school_outlined),
                  ),
                ),
              ],
            ),
          ),
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
                selectedFaculty == null ? Icons.filter_alt_outlined : Icons.filter_alt,
                color: selectedFaculty == null ? null : Colors.green,
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

  Widget _buildMainScaffold(dynamic currentUser) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: _buildAppBar(currentUser),
        drawer: _selectedIndex == 0 ? Drawer(
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 35),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        currentUser?.email ?? 'مستخدم',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('الرئيسية'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedIndex = 0);
                },
              ),
              if (ref.watch(isAdminProvider))
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings, color: Colors.orange),
                  title: const Text('إدارة التقارير', style: TextStyle(color: Colors.orange)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminReportsScreen()),
                    );
                  },
                ),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('تسجيل الخروج'),
                      content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('إلغاء'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('خروج', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirm == true) {
                    await ref.read(authServiceProvider).logOut();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ) : null,
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
