import 'package:flutter/material.dart';

void main() {
  runApp(const BibliaApp());
}

class BibliaApp extends StatelessWidget {
  const BibliaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biblia',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Biblia Setup'),
        ),
      ),
    );
  }
}