import 'package:flutter/foundation.dart';

// Simple global navigation index for the app shell (avoids Riverpod provider mismatch)
final ValueNotifier<int> navIndex = ValueNotifier<int>(0);
