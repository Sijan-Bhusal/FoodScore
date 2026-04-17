import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'theme.dart';

class FoodScoreApp extends StatelessWidget {
  const FoodScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodScore',
      theme: AppTheme.light(),
      home: const AppShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}
