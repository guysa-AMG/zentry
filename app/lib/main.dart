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
        scaffoldBackgroundColor: const Color.fromARGB(255, 18, 18, 19),
        colorScheme: const ColorScheme.dark(
          primary: Color.fromARGB(255, 103, 187, 82),
          secondary: Colors.cyanAccent,
        ),
      ),
      home: const DrivingModeHud(),
      debugShowCheckedModeBanner: false,
    );
  }
}
