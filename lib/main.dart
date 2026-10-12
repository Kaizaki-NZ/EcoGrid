import 'package:flutter/material.dart';

import 'pages/home_page.dart';

/// Entry point aplikasi EcoGrid Desa.
void main() => runApp(const EcoGridApp());

/// Aplikasi simulasi microgrid energi terbarukan (SDG 7).
class EcoGridApp extends StatelessWidget {
  const EcoGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoGrid Desa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        scaffoldBackgroundColor: const Color(0xFFF1F8F4),
      ),
      home: const HomePage(),
    );
  }
}
