class BookModel {
  final String id;
  final String publisherId;
  final String universityId;
  final String title;
  final String author;
  final String faculty;
  final String description;
  final String condition; // "Like New", "Good", "Fair", "Poor"
  final String postType; // "free", "exchange", "request"
  final String? exchangeDetails;
  final String status; // "Available" or "Accepted"
  final DateTime createdAt;

  BookModel({
    required this.id,
    required this.publisherId,
    required this.universityId,
    required this.title,
    required this.author,
    required this.faculty,
    required this.description,
    required this.condition,
    this.postType = 'free',
    this.exchangeDetails,
    this.status = 'Available',
    required this.createdAt,
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'publisherId': publisherId,
      'universityId': universityId,
      'title': title,
      'author': author,
      'faculty': faculty,
      'description': description,
      'condition': condition,
      'postType': postType,
      'exchangeDetails': exchangeDetails,
      'status': status,
      'createdAt': createdAt,
    };
  }

  // Create from Firestore document
  factory BookModel.fromMap(Map<String, dynamic> map, String docId) {
    return BookModel(
      id: docId,
      publisherId: map['publisherId'] ?? '',
      universityId: map['universityId'] ?? '',
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      faculty: map['faculty'] ?? '',
      description: map['description'] ?? '',
      condition: map['condition'] ?? 'Good',
      postType: map['postType'] ?? (map['isExchange'] == true ? 'exchange' : 'free'),
      exchangeDetails: map['exchangeDetails'],
      status: map['status'] ?? 'Available',
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }
}
