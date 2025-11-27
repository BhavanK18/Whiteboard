// platform_config.dart
import 'platform_config_stub.dart'
    if (dart.library.io) 'platform_config_io.dart'
    if (dart.library.html) 'platform_config_web.dart';

// Re-export the initializePlatformDatabase function
void initializePlatformDatabase() => initializeDatabase();