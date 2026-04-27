import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mbyb/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final snapshot = await FirebaseFirestore.instance.collection('Universities').get();
  for (var doc in snapshot.docs) {
    print('Uni: ${doc.data()['name']} - LogoUrl: ${doc.data()['logoUrl']}');
  }
}
