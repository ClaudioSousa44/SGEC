import 'package:flutter/material.dart';
import 'screens/auth_check_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SGEC - Sistema de Gestão de Entrada e Controle',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2196F3)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const AuthCheckScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
