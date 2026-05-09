import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'screens/driving_mode_hud.dart';

void main() {
  runApp(
    const ProviderScope(
      child: ZentryApp(),
    ),
  );
}

class ZentryApp extends StatelessWidget {
  const ZentryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zentry Voice App',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.cyanAccent,
        ),
      ),
      home: const DrivingModeHud(),
      debugShowCheckedModeBanner: false,
    );
  }
}
