// platform_config_web.dart
import 'package:flutter/foundation.dart';

void initializeDatabase() {
  // On web, we use an in-memory solution instead of SQLite
  debugPrint('Using in-memory database for web platform');
}