import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../../models/chat.dart';
import '../../models/chat_message.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../../services/report_service.dart';

class ChatThreadScreen extends StatefulWidget {
  final ChatModel chat;

  const ChatThreadScreen({super.key, required this.chat});

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _chatService = ChatService();
  final _authService = AuthService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  String _otherStudentId = 'Chat';

  @override
  void initState() {
    super.initState();
    _loadOtherStudentId();
    _markAsSeen();
  }

  Future<void> _updateOtherStudentIdFromChat(ChatModel chat) async {
    final currentUser = _auth_service_currentUser();
    if (currentUser == null) return;

    final otherUid = chat.participantIds.firstWhere(
      (id) => id != currentUser.uid,
      orElse: () => '',
    );

    if (otherUid.isEmpty) return;

    // Prefer the student ID stored on the chat document to avoid extra lookups
    final mapped = chat.participantStudentIds[otherUid];
    if (mapped != null && mapped.isNotEmpty) {
      if (mounted && _otherStudentId != mapped) {
        setState(() => _otherStudentId = mapped);
      }
      return;
    }

    // Fallback: query Users collection
    final studentId = await _chatService.getStudentId(otherUid);
    if (mounted && _otherStudentId != studentId) {
      setState(() => _otherStudentId = studentId);
    }
  }

  User? _auth_service_currentUser() {
    try {
      return _authService.currentUser;
    } catch (_) {
      return null;
    }
  }

  void _markAsSeen() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;
    _chatService.markChatAsSeen(widget.chat.id, currentUser.uid);
  }

  Future<void> _loadOtherStudentId() async {
    // Reuse the mapping-aware update method so we prefer
    // `participantStudentIds` on the chat document and avoid extra lookups.
    await _updateOtherStudentIdFromChat(widget.chat);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    _messageController.clear();

    try {
      await _chatService.sendMessage(widget.chat.id, currentUser.uid, text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
          SnackBar(content: Text('فشل إرسال الرسالة: $e')),
        );
      }
    }
  }

  void _showReportDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('الإبلاغ عن $_otherStudentId'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('يرجى وصف سبب الإبلاغ عن هذا المستخدم:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'أدخل التقرير...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              final reason = controller.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(ctx)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text('يرجى إدخال سبب.')),
                  );
                return;
              }
              
              final currentUser = _authService.currentUser;
              if (currentUser == null) return;

              try {
                // Find the other participant's UID
                final otherUid = widget.chat.participantIds.firstWhere(
                  (id) => id != currentUser.uid,
                  orElse: () => '',
                );

                if (otherUid.isNotEmpty) {
                  await ReportService().submitReport(
                    reporterId: currentUser.uid,
                    targetId: otherUid,
                    targetType: 'user',
                    targetTitle: _otherStudentId,
                    reason: reason,
                    chatId: widget.chat.id,
                  );
                }

                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('تم إرسال التقرير بنجاح.'),
                        backgroundColor: Colors.grey,
                      ),
                    );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text('فشل إرسال التقرير: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                }
              }
            },
            child: const Text(
              'إرسال التقرير',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  void _closeTrade() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إغلاق المبادلة'),
        content: const Text(
          'هل أنت متأكد أنك تريد إغلاق هذه المبادلة؟ لن يتمكن أي طرف من إرسال رسائل بعد ذلك.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إغلاق', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      try {
        final currentStudentId = await _chatService.getStudentId(currentUser.uid);
        await _chatService.closeChat(widget.chat.id, currentStudentId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
            SnackBar(content: Text('فشل إغلاق المبادلة: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    if (currentUser == null) {
      return const Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Scaffold(body: Center(child: Text('خطأ في المصادقة.'))),
      );
    }

    return StreamBuilder<ChatModel>(
      stream: _chatService.watchChat(widget.chat.id),
      initialData: widget.chat,
      builder: (context, chatSnapshot) {
        final chat = chatSnapshot.data ?? widget.chat;

        final lastSeen = chat.lastSeenAt[currentUser.uid];
        if (lastSeen == null || chat.updatedAt.isAfter(lastSeen.add(const Duration(seconds: 1)))) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _markAsSeen());
        }

        final isClosed = chat.isClosed;

        final otherUid = chat.participantIds.firstWhere(
          (id) => id != currentUser.uid,
          orElse: () => '',
        );

        final displayId = chat.participantStudentIds[otherUid] ?? _otherStudentId;

        // If we only have a placeholder, keep trying to load the student ID in background
        if (displayId == 'Chat' || displayId.isEmpty || displayId == otherUid) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateOtherStudentIdFromChat(chat);
          });
        }

        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Scaffold(
            appBar: AppBar(
            title: Text(displayId),
            elevation: 1,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'close') _closeTrade();
                  if (value == 'report') _showReportDialog();
                },
                itemBuilder: (context) => [
                   if (!isClosed)
                    const PopupMenuItem(
                      value: 'close',
                      child: Row(
                        children: [
                          Icon(Icons.close, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'إغلاق المبادلة',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  // Only show report if the other user is NOT the admin
                  if (displayId != 'solosoulacc')
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag_outlined, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            'إبلاغ',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<ChatMessage>>(
                  stream: _chatService.getChatMessages(widget.chat.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'خطأ في تحميل الرسائل: ${snapshot.error}',
                        ),
                      );
                    }

                    final messages = snapshot.data ?? [];

                    if (messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'لا توجد رسائل بعد. قل مرحباً!',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderId == currentUser.uid;
                        return _buildMessageBubble(message, isMe);
                      },
                    );
                  },
                ),
              ),

              // Bottom area: closed notice OR message input
              if (isClosed)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border(
                      top: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'تم إغلاق هذه المبادلة بواسطة ${chat.closedByStudentId ?? 'غير معروف'}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                )
              else
                _buildMessageInput(),
            ],
          ),
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, top: 2),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('h:mm a').format(message.sentAt),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.black54,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'اكتب رسالة...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
