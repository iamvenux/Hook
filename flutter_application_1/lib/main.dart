import 'package:flutter/material.dart';

import 'package:flutter_application_1/screens/auth/login_screen.dart';

void main() {
  runApp(const HookApp());
}

class HookApp extends StatelessWidget {
  const HookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hook',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A7EF5),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}
