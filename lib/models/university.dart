class University {
  final String id;
  final String name;
  final String emailDomain;
  final List<String> adminEmails;
  final String? logoUrl;

  University({
    required this.id,
    required this.name,
    required this.emailDomain,
    required this.adminEmails,
    this.logoUrl,
  });

  factory University.fromMap(String id, Map<String, dynamic> map) {
    return University(
      id: id,
      name: map['name'] ?? '',
      emailDomain: map['emailDomain'] ?? '',
      adminEmails: List<String>.from(map['adminEmails'] ?? []),
      logoUrl: map['logoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'emailDomain': emailDomain,
      'adminEmails': adminEmails,
      'logoUrl': logoUrl,
    };
  }
}
