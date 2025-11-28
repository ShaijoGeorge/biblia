import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';

void main() {
  // ProviderScope is the entry point of Riverpod. It stores the state of all providers.
  runApp(const ProviderScope(child: BibliaApp()));
}

class BibliaApp extends StatelessWidget {
  const BibliaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biblia',
      debugShowCheckedModeBanner: false,
      
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      
      // Use system setting to toggle light/dark mode
      themeMode: ThemeMode.system,
      
      // Temp placeholder until build Router
      home: const Scaffold(
        body: Center(
          child: Text('Biblia: Ready for Development'),
        ),
      ),
    );
  }
}