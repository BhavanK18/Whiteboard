# Firebase Configuration Guide

This document provides detailed instructions for setting up Firebase for the Collaborative Whiteboard application.

## Creating a Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter a project name (e.g., "Collaborative Whiteboard")
4. Choose whether to enable Google Analytics (recommended)
5. Click "Create project"

## Android Configuration

1. In the Firebase Console, click the Android icon to add an Android app
2. Enter your app's package name (found in `android/app/build.gradle` under `applicationId`)
3. Enter a nickname for your app (optional)
4. Click "Register app"
5. Download the `google-services.json` file
6. Place this file in the `android/app/` directory
7. Follow the remaining setup instructions in the Firebase Console

## iOS Configuration

1. In the Firebase Console, click the iOS icon to add an iOS app
2. Enter your app's bundle ID (found in Xcode under the "General" tab of your project settings)
3. Enter a nickname for your app (optional)
4. Click "Register app"
5. Download the `GoogleService-Info.plist` file
6. Place this file in the `ios/Runner/` directory
7. Follow the remaining setup instructions in the Firebase Console

## Enabling Authentication

1. In the Firebase Console, navigate to "Authentication" from the left sidebar
2. Click "Get started"
3. Enable the sign-in methods:
   - Email/Password: Click "Email/Password", toggle the switch to enable, and click "Save"
   - Google Sign-In: Click "Google", toggle the switch to enable, configure the OAuth consent screen if prompted, and click "Save"

## Setting up Realtime Database

1. In the Firebase Console, navigate to "Realtime Database" from the left sidebar
2. Click "Create database"
3. Choose a location for your database
4. Start in test mode (for development) or locked mode (for production)
5. Click "Enable"

## Security Rules

If you started in test mode, update your Realtime Database security rules with the following:

```json
{
  "rules": {
    "sessions": {
      ".read": "auth != null",
      ".write": "auth != null",
      "$sessionId": {
        ".read": "auth != null",
        ".write": "auth != null",
        "participants": {
          "$uid": {
            ".write": "auth != null && auth.uid == $uid"
          }
        },
        "elements": {
          ".read": "auth != null",
          ".write": "auth != null"
        }
      }
    },
    "users": {
      "$uid": {
        ".read": "auth != null && auth.uid == $uid",
        ".write": "auth != null && auth.uid == $uid"
      }
    }
  }
}
```

## Setting up Firestore Database

1. In the Firebase Console, navigate to "Firestore Database" from the left sidebar
2. Click "Create database"
3. Choose a location for your database
4. Start in test mode (for development) or production mode
5. Click "Enable"

## Firestore Security Rules

Update your Firestore security rules with the following:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /sessions/{sessionId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
                             (resource.data.createdBy == request.auth.uid || 
                             request.resource.data.createdBy == request.auth.uid);
      
      match /participants/{userId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

## Environment Variables

Create a `.env` file in the root of your project with the following variables:

```
FIREBASE_WEB_API_KEY=your_api_key
FIREBASE_APP_ID=your_app_id
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_STORAGE_BUCKET=your_storage_bucket
FIREBASE_DATABASE_URL=your_database_url
```

Replace the placeholders with the actual values from your Firebase project.