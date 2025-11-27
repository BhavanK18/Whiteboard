// platform_config_io.dart
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

void initializeDatabase() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Initialize FFI for desktop platforms
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    debugPrint('Initialized FFI database factory for desktop');
  }
  // For Android and iOS, the default SQLite implementation is used
}