class ChatModel {
  final String id;
  final List<String> participantIds;
  final String? lastMessage;
  final DateTime updatedAt;
  final String bookId;
  final bool isClosed;
  final String? closedByStudentId;
  final Map<String, DateTime> lastSeenAt;
  final Map<String, String> participantStudentIds;
  final List<String> archivedBy;

  ChatModel({
    required this.id,
    required this.participantIds,
    this.lastMessage,
    required this.updatedAt,
    required this.bookId,
    this.isClosed = false,
    this.closedByStudentId,
    this.lastSeenAt = const {},
    this.participantStudentIds = const {},
    this.archivedBy = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'participantIds': participantIds,
      'lastMessage': lastMessage,
      'updatedAt': updatedAt,
      'bookId': bookId,
      'isClosed': isClosed,
      'closedByStudentId': closedByStudentId,
      'lastSeenAt': lastSeenAt.map((k, v) => MapEntry(k, v)),
      'participantStudentIds': participantStudentIds,
      'archivedBy': archivedBy,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map, String docId) {
    return ChatModel(
      id: docId,
      participantIds: List<String>.from(map['participantIds'] ?? []),
      lastMessage: map['lastMessage'],
      updatedAt: (map['updatedAt'] as dynamic)?.toDate() ?? DateTime.now(),
      bookId: map['bookId'] ?? '',
      isClosed: map['isClosed'] ?? false,
      closedByStudentId: map['closedByStudentId'],
      lastSeenAt: (() {
        final raw = map['lastSeenAt'];
        if (raw == null || raw is! Map) return <String, DateTime>{};
        return raw.map<String, DateTime>(
          (k, v) => MapEntry(k.toString(), (v as dynamic).toDate()),
        );
      })(),
      participantStudentIds: (() {
        final raw = map['participantStudentIds'];
        if (raw == null || raw is! Map) return <String, String>{};
        return raw.map<String, String>(
          (k, v) => MapEntry(k.toString(), v.toString()),
        );
      })(),
      archivedBy: List<String>.from(map['archivedBy'] ?? []),
    );
  }
}
