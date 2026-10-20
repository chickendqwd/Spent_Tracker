import 'package:flutter/material.dart';

import 'core/constants.dart';
import 'ui/app_shell.dart';

/// 应用根组件。
class SpentTrackerApp extends StatelessWidget {
  const SpentTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppConstants.seedColor),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const AppShell(),
    );
  }
}
