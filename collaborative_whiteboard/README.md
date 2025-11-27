# Flutter Collaborative Whiteboard App

A feature-rich collaborative whiteboard application built with Flutter that allows multiple users to draw, write, and collaborate in real-time.

## ⚠️ DEMO MODE NOTICE

**The app is currently running in DEMO MODE with placeholder Firebase configuration.** 

Authentication and real-time collaboration features are disabled. To enable full functionality, follow the Firebase Setup instructions below.

## Features

- Real-time multi-user collaboration
- Freehand drawing, shapes (line, rectangle, circle), text, and eraser tools
- Live sync across devices using Firebase Realtime Database
- User authentication (email/password and Google sign-in)
- Session management (create/join by ID/link)
- Zoom in/out, pan, undo/redo, and clear board
- Modern UI with customizable color picker and stroke thickness

## Getting Started

### Prerequisites

- Flutter (version 3.35.4 or later)
- Firebase account
- Android Studio / Xcode for mobile development

### Firebase Setup (Required for Full Functionality)

1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add Android and iOS apps to your Firebase project
3. Download and place the `google-services.json` file in the `android/app` directory
4. Download and place the `GoogleService-Info.plist` file in the `ios/Runner` directory
5. Use the FlutterFire CLI to generate the `firebase_options.dart` file:
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
6. Update `lib/utils/firebase_status.dart` to set `isConfigured = true`
7. Enable Authentication in Firebase console:
   - Email/Password
   - Google Sign-In (requires additional OAuth configuration)
8. Enable Realtime Database in Firebase console
9. Set up Firestore database with appropriate security rules

### Installation

1. Clone this repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

## Architecture

The application is structured using a service-based architecture with the following components:

### Screens
- SplashScreen
- LoginScreen
- RegisterScreen
- DashboardScreen
- WhiteboardScreen

### Services
- AuthService: Handles authentication operations
- SessionService: Manages whiteboard sessions
- WhiteboardService: Controls drawing operations and real-time sync

### Models
- Drawing: Defines drawing elements (path, line, rectangle, circle, text)
- Session: Represents whiteboard sessions and users

### Widgets
- DrawingCanvas: Renders the whiteboard elements
- DrawingToolbar: UI for selecting drawing tools
- ColorPickerDialog: Color selection interface
- ParticipantList: Shows users in the current session

## State Management

This application uses Provider for state management. The main providers are:
- AuthProvider: Manages authentication state
- SessionProvider: Manages whiteboard session state
- WhiteboardProvider: Manages drawing state and tool selection

## Dependencies

- firebase_core: ^2.27.2
- firebase_auth: ^4.17.6
- cloud_firestore: ^4.15.7
- firebase_database: ^10.4.7
- google_sign_in: ^6.2.1
- provider: ^6.1.5+1
- uuid: ^4.3.2
- flutter_colorpicker: ^1.0.3
- path_provider: ^2.1.2
- shared_preferences: ^2.2.2

## Troubleshooting

### Common Issues

1. **"Firebase Configuration Error" or "Api-key-not-valid" Errors**
   - This is expected when running in demo mode with placeholder Firebase configuration
   - Follow the Firebase Setup instructions above to properly configure the app
   - After setup, update `lib/utils/firebase_status.dart` to set `isConfigured = true`

2. **Firebase Integration Issues**
   - Ensure you've correctly placed `google-services.json` and `GoogleService-Info.plist` in the right directories
   - Check that your Firebase project has the required services enabled
   - Verify that your Firebase API key is valid and has the necessary permissions

3. **Google Sign-In Not Working**
   - Google Sign-In is temporarily disabled in the current version
   - To enable it, update the implementation in `lib/services/auth_service.dart`
   - Configure OAuth credentials in the Firebase Console

4. **Building for iOS**
   - Run `pod install` in the `ios` directory if you encounter CocoaPods issues
   - Ensure your iOS deployment target is set correctly in Xcode

5. **Realtime Sync Not Working**
   - Check your Firebase Realtime Database rules
   - Ensure your device has a stable internet connection

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

## Screenshots

[Insert app screenshots here]

## Future Improvements

- Add user avatars and profile customization
- Implement image upload functionality
- Add whiteboard templates
- Implement offline mode with local storage
- Add session recording and playback features
