# Contributing to Flutter Collaborative Whiteboard

Thank you for your interest in contributing to the Flutter Collaborative Whiteboard project! This document provides guidelines and instructions for contributing.

## Code of Conduct

Please be respectful and considerate of others when contributing to this project. We aim to foster an inclusive and positive community.

## How to Contribute

### Reporting Issues

If you find a bug or have a suggestion for improvement:

1. Check if the issue already exists in the issue tracker
2. If not, create a new issue with:
   - A clear title
   - A detailed description
   - Steps to reproduce (for bugs)
   - Expected and actual behavior
   - Screenshots if applicable
   - Device/environment information

### Pull Requests

1. Fork the repository
2. Create a new branch from `main` with a descriptive name
   ```
   git checkout -b feature/your-feature-name
   ```
3. Make your changes
4. Test your changes thoroughly
5. Commit with clear messages
   ```
   git commit -m "Add feature: description of the changes"
   ```
6. Push to your fork
   ```
   git push origin feature/your-feature-name
   ```
7. Create a pull request to the `main` branch
8. Describe your changes in the PR description

## Development Setup

1. Fork and clone the repository
   ```
   git clone https://github.com/yourusername/collaborative_whiteboard.git
   cd collaborative_whiteboard
   ```
2. Install dependencies
   ```
   flutter pub get
   ```
3. Set up Firebase (see FIREBASE_SETUP.md)
4. Run the app
   ```
   flutter run
   ```

## Coding Style

- Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Write comments for complex logic
- Create unit tests for new features when possible

## Project Structure

```
lib/
├── constants/       # App-wide constants
├── models/          # Data models
├── screens/         # UI screens
├── services/        # Business logic and API communication
├── utils/           # Utility functions
├── widgets/         # Reusable UI components
└── main.dart        # App entry point
```

## Testing

- Write unit tests for services and models
- Write widget tests for UI components
- Test on both Android and iOS devices

## Documentation

- Document public APIs, classes, and functions
- Update README.md when adding new features
- Keep CHANGELOG.md updated

## Feature Requests

Feature requests are welcome! Please create an issue in the issue tracker with:

- A clear title
- A detailed description of the feature
- Any relevant mockups or examples
- Use cases that demonstrate the value of the feature

## Branching Strategy

- `main`: Stable release branch
- `develop`: Development branch
- `feature/*`: Feature branches
- `bugfix/*`: Bug fix branches
- `release/*`: Release preparation branches

Thank you for contributing!