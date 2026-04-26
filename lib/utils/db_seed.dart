import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseSeed {
  static Future<void> seedUniversities() async {
    final firestore = FirebaseFirestore.instance;
    
    final aabu = {
      'name': 'جامعة آل البيت',
      'emailDomain': 'st.aabu.edu.jo',
      'adminEmails': ['solosoulacc@tutamail.com'], // Add more admin emails here
      'logoUrl': '',
    };

    // Add AABU
    await firestore.collection('Universities').doc('aabu').set(aabu);
    
    print('✅ Database seeded with AABU!');
  }
}
