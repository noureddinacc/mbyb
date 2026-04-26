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

    final mapped = chat.participantStudentIds[otherUid];
    if (mapped != null && mapped.isNotEmpty) {
      if (mounted && _otherStudentId != mapped) {
        setState(() => _otherStudentId = mapped);
      }
      return;
    }

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
          ..showSnackBar(SnackBar(content: Text('فشل إرسال الرسالة: $e')));
      }
    }
  }

  void _showReportDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
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
                decoration: InputDecoration(
                  hintText: 'أدخل التقرير...',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
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
                if (reason.isEmpty) return;
                
                final currentUser = _authService.currentUser;
                if (currentUser == null) return;

                try {
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إرسال التقرير بنجاح.')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('فشل إرسال التقرير: $e')),
                    );
                  }
                }
              },
              child: const Text(
                'إرسال',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _closeTrade() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إغلاق المبادلة'),
          content: const Text(
            'هل أنت متأكد؟ لن يتمكن أي طرف من إرسال رسائل بعد ذلك.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('تراجع'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'إغلاق',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      try {
        final currentStudentId = await _chatService.getStudentId(
          currentUser.uid,
        );
        await _chatService.closeChat(widget.chat.id, currentStudentId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('فشل إغلاق المبادلة: $e')));
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
        final isClosed = chat.isClosed;
        final otherUid = chat.participantIds.firstWhere(
          (id) => id != currentUser.uid,
          orElse: () => '',
        );
        final displayId =
            chat.participantStudentIds[otherUid] ?? _otherStudentId;

        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayId, style: const TextStyle(fontSize: 16)),
                  Text(
                    chat.bookTitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
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
                            Icon(
                              Icons.lock_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'إغلاق المبادلة',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    if (displayId != 'solosoulacc')
                      const PopupMenuItem(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(
                              Icons.flag_outlined,
                              color: Colors.orange,
                              size: 20,
                            ),
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
                // Modern Safety Note - Now in Green
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[100]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.green[700],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'يرجى التحلي بالاحترام واتباع الإرشادات. يمكنك إغلاق المبادلة عند الإنتهاء من قائمة النقاط الثلاث أعلاه.',
                          style: TextStyle(
                            color: Colors.green[900],
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<ChatMessage>>(
                    stream: _chatService.getChatMessages(widget.chat.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final messages = snapshot.data ?? [];
                      if (messages.isEmpty) {
                        return Center(
                          child: Text(
                            'قل مرحباً لـ $displayId!',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        );
                      }
                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
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
                if (isClosed)
                  _buildClosedNotice(chat.closedByStudentId)
                else
                  _buildMessageInput(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClosedNotice(String? closedBy) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Center(
        child: Text(
          'تم إغلاق المبادلة بواسطة ${closedBy ?? 'مستخدم'}',
          style: TextStyle(
            color: Colors.grey[600],
            fontStyle: ui.FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF2E7D32) : const Color(0xFFF1F1F1),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              DateFormat('h:mm a').format(message.sentAt),
              style: TextStyle(color: Colors.grey[400], fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F1F1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'اكتب رسالة...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF8F8F8),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF2E7D32),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
