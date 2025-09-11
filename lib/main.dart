import 'package:flutter/material.dart';
import 'pages/login_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DVWAMobileApp());
}

class DVWAMobileApp extends StatelessWidget {
  const DVWAMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DVWA Mobile',
      theme: ThemeData.dark(useMaterial3: true),
      home: const LoginPage(),
    );
  }
}