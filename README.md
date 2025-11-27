# Collaborative Whiteboard Application

A real-time collaborative whiteboard application built with Flutter and Node.js.

## Features

- Real-time collaborative drawing with multiple users
- Various drawing tools: pen, line, rectangle, circle, text, eraser
- Session sharing via unique codes
- Chat functionality during collaboration
- Cross-platform support (Web, iOS, Android, Desktop)
- Offline mode with local storage
- User authentication
- Whiteboard saving and management

## Architecture

### Frontend (Flutter)

- **User Interface**: Flutter framework for cross-platform UI
- **State Management**: Provider pattern for application state
- **Drawing Canvas**: Custom Flutter widgets for rendering
- **Real-time Communication**: Socket.IO client for real-time updates
- **Local Storage**: SQLite for mobile/desktop, In-memory storage for web

### Backend (Node.js)

- **Server**: Express.js web server
- **Real-time Communication**: Socket.IO for WebSocket connections
- **Database**: MongoDB for storing whiteboard data
- **API**: RESTful endpoints for user, session and whiteboard management

## Setup and Running

### Backend Setup

1. Navigate to the backend directory:
   ```
   cd backend
   ```

2. Install dependencies:
   ```
   npm install
   ```

3. Configure MongoDB:
   - Create a MongoDB database (local or Atlas)
   - Update the `.env` file with your MongoDB connection string

4. Start the server:
   ```
   npm run dev
   ```
   
The backend server will run on http://localhost:3000 by default.

### Flutter Setup

1. Make sure you have Flutter installed and configured
2. Navigate to the Flutter project directory:
   ```
   cd collaborative_whiteboard
   ```

3. Install dependencies:
   ```
   flutter pub get
   ```

4. Run the application:
   ```
   flutter run -d chrome  # For web
   flutter run            # For mobile/desktop
   ```

## Usage Guide

### Creating a Whiteboard

1. Launch the application and sign in
2. Create a new whiteboard from the dashboard
3. Use the drawing tools to create content

### Sharing and Collaborating

1. Click on the "Collaborate" button
2. Choose "Create Session"
3. Share the session code with collaborators
4. Others can join using the session code

### Chat during Collaboration

1. Click on the chat icon in the app bar
2. Type your message and press send
3. All participants will see the chat messages

## Deployment

### Backend Deployment

- Deploy the Node.js backend to a service like Heroku, Azure, or AWS
- Set up a MongoDB database (MongoDB Atlas recommended for production)
- Configure environment variables on your hosting platform

### Flutter Web Deployment

- Build the Flutter web app:
  ```
  flutter build web
  ```
- Deploy the contents of the `build/web` directory to a static hosting service like Firebase Hosting, Netlify, or GitHub Pages

## License

This project is licensed under the MIT License - see the LICENSE file for details.