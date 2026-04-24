class RequestModel {
  final String id;
  final String bookId;
  final String bookTitle;
  final String requesterId;
  final String requesterStudentId;
  final DateTime timestamp;
  final String? message;
  final String status; // 'pending', 'accepted', 'rejected'
  final String postType;

  RequestModel({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.requesterId,
    required this.requesterStudentId,
    required this.timestamp,
    this.message,
    this.status = 'pending',
    this.postType = 'free',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'requesterId': requesterId,
      'requesterStudentId': requesterStudentId,
      'timestamp': timestamp,
      'message': message,
      'status': status,
      'postType': postType,
    };
  }

  factory RequestModel.fromMap(Map<String, dynamic> map, String docId) {
    return RequestModel(
      id: docId,
      bookId: map['bookId'] ?? '',
      bookTitle: map['bookTitle'] ?? 'Unknown Book',
      requesterId: map['requesterId'] ?? '',
      requesterStudentId: map['requesterStudentId'] ?? 'Unknown Student',
      timestamp: (map['timestamp'] as dynamic)?.toDate() ?? DateTime.now(),
      message: map['message'],
      status: map['status'] ?? 'pending',
      postType: map['postType'] ?? 'free',
    );
  }
}
