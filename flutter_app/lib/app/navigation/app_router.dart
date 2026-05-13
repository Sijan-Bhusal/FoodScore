import 'package:flutter/material.dart';

import '../../screens/placeholders/history_screen.dart';

class AppRouter {
  static void goToHistory(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const HistoryScreen()));
  }
}
