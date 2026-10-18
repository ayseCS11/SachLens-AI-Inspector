import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() => runApp(const SachLensApp());

class SachLensApp extends StatelessWidget {
  const SachLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SachLens',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1B6B5A),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}