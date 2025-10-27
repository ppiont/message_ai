# MessageAI

A Flutter messaging application with real-time translation, AI-powered formality adjustment, and Firebase backend integration. Built with Clean Architecture and offline-first capabilities.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Firebase Setup](#firebase-setup)
- [Running the App](#running-the-app)
- [Building for Production](#building-for-production)
- [Project Structure](#project-structure)
- [Development Workflow](#development-workflow)
- [Cloud Functions](#cloud-functions)
- [Troubleshooting](#troubleshooting)

## Features

### Core Messaging
- **Real-time messaging** with Firebase Firestore
- **Offline-first architecture** using Drift (SQLite) for local caching
- **Group conversations** with multiple participants
- **Push notifications** via Firebase Cloud Messaging
- **Presence indicators** (online/offline, last seen)
- **Typing indicators** in real-time

### AI-Powered Features
- **Automatic translation** using Google Translate API
  - On-device language detection with ML Kit (<50ms)
  - Cloud-based translation via Firebase Functions
  - Toggle between original and translated messages
- **Formality adjustment** using GPT-4o-mini
  - Three levels: Casual, Neutral, Formal
  - Rate limiting and caching for cost optimization

### Technical Highlights
- **Clean Architecture** with feature-based organization
- **Offline-first** with automatic sync
- **Dual storage** (Firestore + Drift) for optimal performance
- **Riverpod** for state management with code generation
- **Firebase Realtime Database** for ephemeral data (presence, typing)
- **Firebase Firestore** for persistent data (messages, users)

## Prerequisites

### Required Software

1. **Flutter SDK** (3.0.0 or higher)
   ```bash
   # Check Flutter installation
   flutter doctor
   ```

2. **Dart SDK** (3.0.0 or higher, comes with Flutter)

3. **Firebase CLI**
   ```bash
   npm install -g firebase-tools
   firebase login
   ```

4. **Platform-Specific Requirements**

   **iOS:**
   - Xcode 14.0 or higher
   - CocoaPods
   ```bash
   sudo gem install cocoapods
   ```

   **Android:**
   - Android Studio
   - Android SDK (API level 21 or higher)
   - Java Development Kit (JDK) 11 or higher

### Required Accounts

1. **Firebase Project**
   - Create a project at [Firebase Console](https://console.firebase.google.com)
   - Enable Authentication (Email/Password)
   - Enable Firestore Database
   - Enable Realtime Database
   - Enable Cloud Functions
   - Enable Cloud Storage

2. **API Keys** (for Cloud Functions)
   - Google Cloud Translation API key
   - OpenAI API key (for formality adjustment)

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/message_ai.git
cd message_ai
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Run Code Generation

This project uses code generation for Riverpod providers and Drift database tables:

```bash
dart run build_runner build --delete-conflicting-outputs
```

**Note:** Run this command whenever you modify:
- Riverpod providers (files using `@riverpod`)
- Drift database tables (files extending `Table`)

### 4. Install iOS Dependencies (iOS only)

```bash
cd ios
pod install
cd ..
```

## Firebase Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add project"
3. Follow the setup wizard
4. Enable Google Analytics (optional)

### 2. Configure Firebase for Flutter

Install FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
```

Configure your app (run from project root):

```bash
flutterfire configure
```

This will:
- Create Firebase apps for iOS and Android
- Download configuration files (`google-services.json`, `GoogleService-Info.plist`)
- Generate `firebase_options.dart`

### 3. Enable Firebase Services

In the [Firebase Console](https://console.firebase.google.com), enable:

**Authentication:**
1. Go to Authentication → Sign-in method
2. Enable "Email/Password"

**Firestore Database:**
1. Go to Firestore Database → Create database
2. Choose production mode
3. Select a location (e.g., `us-central1`)

**Realtime Database:**
1. Go to Realtime Database → Create database
2. Choose locked mode (will be configured via rules)
3. Select same location as Firestore

**Cloud Storage:**
1. Go to Storage → Get started
2. Use default security rules

### 4. Deploy Security Rules

Deploy Firestore rules:
```bash
firebase deploy --only firestore:rules
```

Deploy Realtime Database rules:
```bash
firebase deploy --only database
```

### 5. Setup Cloud Functions

Navigate to functions directory and install dependencies:

```bash
cd functions
pip install -r requirements.txt
cd ..
```

Configure API keys using Firebase Secret Manager:

```bash
# Set Google Translate API key
firebase functions:secrets:set TRANSLATION_API_KEY_SECRET

# Set OpenAI API key
firebase functions:secrets:set OPENAI_API_KEY_SECRET
```

Deploy functions:

```bash
firebase deploy --only functions
```

**Available Functions:**
- `translate_message` - Real-time message translation
- `adjust_formality` - AI-powered formality adjustment
- `on_message_created` - Push notification trigger
- `on_user_profile_updated` - Display name propagation

## Running the App

### Check Available Devices

```bash
flutter devices
```

### Run on Specific Device

```bash
# Run on iOS simulator
flutter run -d iPhone

# Run on Android emulator
flutter run -d emulator-5554

# Run on physical device (connected via USB)
flutter run -d <device-id>

# Run in release mode
flutter run --release
```

### Hot Reload

While the app is running:
- Press `r` in terminal for **hot reload** (quick UI updates)
- Press `R` in terminal for **hot restart** (full app restart)
- Press `q` to quit

### Launch iOS Simulator

```bash
open -a Simulator

# Or use Flutter
flutter emulators --launch apple_ios_simulator
```

### Launch Android Emulator

```bash
# List available emulators
flutter emulators

# Launch specific emulator
flutter emulators --launch <emulator-id>
```

## Building for Production

### iOS Build

**1. Configure Xcode Project**

Open `ios/Runner.xcworkspace` in Xcode:

```bash
open ios/Runner.xcworkspace
```

Configure:
- Bundle Identifier
- Team (Apple Developer account)
- Signing certificates

**2. Build IPA**

```bash
# Build for App Store
flutter build ipa --release

# Output: build/ios/ipa/message_ai.ipa
```

**3. Upload to App Store**

Use Xcode or Transporter app to upload the IPA to App Store Connect.

### Android Build

**1. Configure Signing**

Create `android/key.properties`:

```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=<your-key-alias>
storeFile=<path-to-keystore-file>
```

**2. Generate Keystore** (first time only)

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

**3. Build APK**

```bash
# Build release APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

**4. Build App Bundle** (recommended for Play Store)

```bash
# Build release app bundle
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

**5. Upload to Play Store**

Upload the `.aab` file to Google Play Console.

### Build for Web

```bash
flutter build web --release

# Output: build/web/
```

Deploy to Firebase Hosting:

```bash
firebase deploy --only hosting
```

## Project Structure

```
lib/
├── core/                           # Shared infrastructure
│   ├── database/                  # Drift database setup, DAOs
│   │   ├── app_database.dart     # Main database class
│   │   └── daos/                 # Data Access Objects
│   ├── error/                    # Failure classes
│   ├── network/                  # Connectivity checking
│   └── providers/                # Core Riverpod providers
│
├── features/                      # Feature modules (Clean Architecture)
│   ├── authentication/
│   │   ├── data/                # Data sources, models, repositories
│   │   ├── domain/              # Entities, repository interfaces, use cases
│   │   └── presentation/        # Pages, widgets, providers
│   │
│   ├── messaging/
│   │   ├── data/
│   │   │   ├── datasources/    # Firestore & Drift data sources
│   │   │   ├── models/         # DTOs for serialization
│   │   │   ├── repositories/   # Repository implementations
│   │   │   └── services/       # Presence, typing, sync services
│   │   ├── domain/
│   │   │   ├── entities/       # Message, Conversation entities
│   │   │   ├── repositories/   # Repository interfaces
│   │   │   └── usecases/       # Business logic
│   │   └── presentation/
│   │       ├── pages/          # Chat screens
│   │       ├── providers/      # State management
│   │       └── widgets/        # Reusable components
│   │
│   ├── translation/             # Translation feature
│   └── formality_adjustment/    # Formality adjustment feature
│
├── config/                       # App-wide configuration
│   ├── routes/                  # Navigation setup
│   └── theme/                   # Theming
│
└── main.dart                    # App entry point

functions/                        # Firebase Cloud Functions (Python)
├── main.py                      # Function definitions
└── requirements.txt             # Python dependencies

firestore.rules                  # Firestore security rules
database.rules.json              # Realtime Database security rules
```

## Development Workflow

### Code Generation

Run code generation whenever you modify:

```bash
# One-time build
dart run build_runner build --delete-conflicting-outputs

# Watch mode (auto-rebuild on changes)
dart run build_runner watch --delete-conflicting-outputs
```

### Code Analysis

```bash
# Analyze Dart code for issues
dart analyze

# Auto-fix issues
dart fix --apply

# Format code
dart format lib/
```

### Adding a New Feature

1. **Create feature directory** under `lib/features/`
2. **Define domain layer:**
   - Entities (business objects)
   - Repository interfaces
   - Use cases (business logic)
3. **Implement data layer:**
   - Models (DTOs)
   - Data sources (Firestore, Drift)
   - Repository implementations
4. **Build presentation layer:**
   - Pages (screens)
   - Widgets (UI components)
   - Providers (state management)
5. **Run code generation:**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
6. **Test manually** (this project does not use automated tests)

### State Management with Riverpod

All providers use code generation:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_providers.g.dart';  // Generated file

@riverpod
MyService myService(Ref ref) {
  return MyService(ref.watch(dependencyProvider));
}
```

After modifying providers, run build_runner.

### Database Changes with Drift

When modifying database tables:

1. Update table definitions in `lib/core/database/`
2. Run code generation
3. Handle migrations in `app_database.dart`
4. Test with app restart (hot reload won't work)

## Cloud Functions

### Local Testing

```bash
# Install Firebase emulator suite
firebase init emulators

# Start emulators
firebase emulators:start
```

Configure Flutter app to use emulators (development only):

```dart
// In main.dart
if (kDebugMode) {
  FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
}
```

### Deploying Functions

```bash
# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:translate_message

# View logs
firebase functions:log
```

### Function Environment Variables

Functions use Firebase Secret Manager:

```bash
# List secrets
firebase functions:secrets:access TRANSLATION_API_KEY_SECRET

# Update secret
firebase functions:secrets:set TRANSLATION_API_KEY_SECRET
```

## Troubleshooting

### Common Issues

**Build runner errors:**
```bash
# Clean generated files and rebuild
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

**Hot reload not working:**
- Use hot restart (press `R` in terminal)
- Provider structure changes require full restart
- Database schema changes require app reinstall

**Firebase connection issues:**
```bash
# Reconfigure Firebase
flutterfire configure

# Check Firebase initialization in main.dart
```

**iOS build errors:**
```bash
# Clean iOS build
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
```

**Android build errors:**
```bash
# Clean Android build
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

**Drift database errors:**
- Delete app and reinstall (clears local database)
- Check migration logic in `app_database.dart`
- Verify table definitions have correct syntax: `text()()`

**Provider errors:**
```bash
# Regenerate provider files
dart run build_runner build --delete-conflicting-outputs

# Check for circular dependencies
# Verify all providers have proper @riverpod annotation
```

### Getting Help

- **Firebase**: [Firebase Documentation](https://firebase.google.com/docs)
- **Flutter**: [Flutter Documentation](https://flutter.dev/docs)
- **Riverpod**: [Riverpod Documentation](https://riverpod.dev)
- **Drift**: [Drift Documentation](https://drift.simonbinder.eu)

### Debug Logging

Enable verbose logging:

```bash
# Run with verbose output
flutter run -v

# View device logs (iOS)
flutter logs

# View device logs (Android)
adb logcat
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

**Note:** This project does not use automated testing. All changes should be manually tested.

## License

[Add your license here]

## Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Riverpod for state management
- ML Kit for on-device language detection
- OpenAI for GPT-4o-mini API
