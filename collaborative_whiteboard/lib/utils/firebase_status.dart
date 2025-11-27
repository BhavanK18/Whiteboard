// This utility class helps identify Firebase configuration status
// throughout the application.

class FirebaseStatus {
  // Firebase is now properly configured
  static const bool isConfigured = true;
  
  // Convenience property to check if app is in demo mode (opposite of isConfigured)
  static bool get isDemoMode => !isConfigured;
  
  // Message to show when Firebase features are attempted
  static const String configurationMessage = '''
This app is running in demo mode with placeholder Firebase credentials.

To enable Firebase features (authentication, realtime data):
1. Create a Firebase project at https://console.firebase.google.com/
2. Register this app in the Firebase console
3. Download the configuration files (google-services.json for Android, GoogleService-Info.plist for iOS)
4. Use the Firebase CLI to generate firebase_options.dart with proper values
5. Set FirebaseStatus.isConfigured to true

You can continue exploring the UI in demo mode, but authentication and data
storage features will not function.
''';
}