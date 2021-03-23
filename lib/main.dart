import 'package:flutter/material.dart';
import 'package:MySocial/pages/home.dart';

void main() {
  // Firestore.instance.settings(timestampsInSnapshotsEnabled: true).then((_){});
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light().copyWith(
        primaryColor: Colors.purple[700],
        accentColor: Colors.grey[850],
      ),
      title: 'Instagram',
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}
