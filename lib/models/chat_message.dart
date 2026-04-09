class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime sentAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
  });

  Map<String, dynamic> toMap() {
    return {'senderId': senderId, 'text': text, 'sentAt': sentAt};
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map, String docId) {
    return ChatMessage(
      id: docId,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      sentAt: (map['sentAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }
}
