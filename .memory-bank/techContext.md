# Technical Context

## Technology Stack

### Frontend Framework
- **Flutter**: 3.x (stable channel)
- **Language**: Dart 3.x
- **Target Platforms**: iOS, Android, Web

### Backend Services (Firebase)
- **Cloud Firestore**: NoSQL database, real-time sync
- **Firebase Authentication**: Phone auth
- **Firebase Cloud Functions**: Serverless compute (Node.js)
- **Firebase Storage**: Media file storage
- **Firebase Cloud Messaging**: Push notifications
- **Firebase Crashlytics**: Error tracking
- **Google Secret Manager**: API key storage

### State Management & DI
- **flutter_riverpod**: ^2.4.9
- **riverpod_annotation**: ^2.3.3
- **riverpod_generator**: ^2.3.9

### Local Database
- **drift**: ^2.14.0 (type-safe SQLite ORM)
- **sqlite3_flutter_libs**: ^0.5.0

### AI Services
- **OpenAI GPT-4o-mini**: Via Cloud Functions proxy
  - Input tokens: $0.15/1M
  - Output tokens: $0.60/1M
  - 50% prompt caching discount
- **text-embedding-3-small**: For RAG/vector search

### Translation Services
- **Google Cloud Translation API**: Primary translation
- **DeepL API** (optional): For formal/quality translations
- **google_mlkit_language_id**: ^0.10.0 (on-device detection)

### Core Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management (to be added)
  # flutter_riverpod: ^2.4.9
  # riverpod_annotation: ^2.3.3

  # Firebase (latest versions - updated)
  firebase_core: ^4.2.0
  firebase_auth: ^6.1.1
  cloud_firestore: ^6.0.3
  firebase_storage: ^13.0.3
  firebase_messaging: ^16.0.3
  firebase_crashlytics: ^5.0.3
  cloud_functions: ^6.0.3

  # Local Storage (to be added)
  # drift: ^2.14.0
  # sqlite3_flutter_libs: ^0.5.0

  # UI (to be added)
  # cached_network_image: ^3.3.0
  # flutter_cache_manager: ^3.3.1

  # Language (to be added)
  # google_mlkit_language_id: ^0.10.0
  # intl: ^0.18.1

  # Utilities (to be added)
  # uuid: ^4.2.2
  # equatable: ^2.0.5
  # connectivity_plus: ^5.0.2
  # workmanager: ^0.5.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

  # Build tools (to be added)
  # build_runner: ^2.4.6
  # riverpod_generator: ^2.3.9
  # drift_dev: ^2.14.0

  # Testing (latest versions - updated)
  # mocktail: ^1.0.1
  fake_cloud_firestore: ^4.0.0
  firebase_auth_mocks: ^0.15.1
```

## Development Environment

### Required Tools
- **Flutter SDK**: 3.x stable
- **Dart SDK**: 3.x (bundled with Flutter)
- **Xcode**: 15+ (for iOS development)
- **Android Studio**: Latest stable (for Android development)
- **Firebase CLI**: For Cloud Functions deployment
- **Node.js**: 18+ (for Cloud Functions)

### IDE Recommendations
- **VS Code** with Flutter + Dart extensions
- **Android Studio** with Flutter plugin
- **Xcode** for iOS builds

### Firebase Projects
Two environments:
1. **message-ai**: Development/testing
   - **Phone Auth**: Enabled ✅
   - **Test Phone**: +1 650-555-3434 (code: 123456)
2. **message-ai-prod**: Production

### Flutter Flavors & Run Commands
```bash
# Development (Android Emulator)
flutter run --flavor dev -t lib/main_dev.dart -d emulator-5554

# Development (iOS Simulator)
flutter run --flavor dev -t lib/main_dev.dart -d <ios-simulator-id>

# Production
flutter run --flavor prod -t lib/main_prod.dart
```

**⚠️ CRITICAL**: Always use `--flavor dev -t lib/main_dev.dart` for development builds!

## Project Structure

```
lib/
├── main.dart                    # Entry point
├── app.dart                     # App configuration
├── core/
│   ├── database/               # drift database setup
│   ├── error/                  # Error handling
│   ├── network/                # Network utilities
│   ├── constants/              # App constants
│   └── utils/                  # Helper functions
├── features/                   # Feature modules
│   ├── authentication/
│   ├── messaging/
│   ├── ai_features/
│   └── translation/
├── config/
│   ├── routes/                 # Navigation setup
│   ├── theme/                  # App theming
│   └── providers.dart          # Global providers
└── l10n/                       # Internationalization
```

### Feature Module Structure
```
feature_name/
├── data/
│   ├── datasources/           # Remote & local data sources
│   ├── models/                # Data transfer objects
│   └── repositories/          # Repository implementations
├── domain/
│   ├── entities/              # Business objects
│   ├── repositories/          # Repository interfaces
│   └── usecases/              # Business logic
└── presentation/
    ├── providers/             # Riverpod providers
    ├── pages/                 # Full screens
    └── widgets/               # Reusable components
```

## Build & Deployment

### CI/CD Pipeline
- **GitHub Actions**: Automated testing + deployment
- **Fastlane**: iOS/Android build automation
- **TestFlight**: iOS beta distribution
- **Google Play Internal Testing**: Android beta

### Testing Strategy
```
Integration: 10-15%  (e2e flows)
Widget:      25-30%  (UI components)
Unit:        55-65%  (business logic)
```

**Coverage Targets:**
- Overall: 80%+
- Business Logic: 90%+
- Critical Paths: 95%+ (messaging, auth, sync)

### Testing Tools
- **flutter_test**: Unit & widget tests
- **integration_test**: E2E tests
- **mocktail**: Mocking framework
- **fake_cloud_firestore**: Firestore test doubles
- **firebase_auth_mocks**: Auth test doubles

## Technical Constraints

### Performance Requirements (7-Day Sprint)
- **Smooth UI**: No janky scrolling or animations
- **Responsive AI**: Features should feel fast (cache when possible)
- **Optimistic updates**: Messages appear instantly
- **Handles lifecycle**: Works in background/foreground

### Security Requirements
- **Secret Manager**: API keys never in client code
- **Firestore Rules**: Participant-based access control
- **Cloud Functions**: AI proxy layer
- **TLS/HTTPS**: All network communication

### Platform Constraints
- **iOS**: Minimum iOS 12 (for TestFlight)
- **Android**: Minimum API 21 (Android 5.0)
- **Web**: Modern browsers (if deploying web version)

### Development Constraints
- **7-day timeline**: MVP in 24 hours, final in 7 days
- **Cost awareness**: Keep AI costs reasonable during development
- **Focus on functionality**: Core features over polish
- **Real device testing**: Test on physical devices, not just simulators

## Development Setup

### Initial Setup Commands
```bash
# Install Flutter dependencies
flutter pub get

# Generate code (Riverpod, drift)
flutter pub run build_runner build --delete-conflicting-outputs

# Setup Firebase
firebase login
firebase init

# Run development build
flutter run --flavor dev
```

### Code Generation
```bash
# Watch mode for development
flutter pub run build_runner watch

# One-time build
flutter pub run build_runner build --delete-conflicting-outputs
```

### Firebase Emulator
```bash
# Start local Firebase emulators
firebase emulators:start

# Run Flutter app against emulators
flutter run --dart-define=USE_EMULATOR=true
```

## API Integrations

### OpenAI API
- **Endpoint**: Proxied via Cloud Functions
- **Models**: gpt-4o-mini (primary), gpt-4o (fallback)
- **Rate Limits**: Enforced server-side
- **Authentication**: Secret Manager

### Google Cloud Translation
- **Cost**: ~$20/1M characters
- **Optimization**: 70% cache hit rate target
- **Languages**: 50+ supported

### Firebase Cloud Messaging
- **Purpose**: Push notifications
- **Platform**: iOS APNs, Android FCM
- **Types**: New message, priority alerts, action items

## Version Control Strategy
- **Main branch**: Production-ready code
- **Develop branch**: Integration branch
- **Feature branches**: feature/feature-name
- **Release branches**: release/vX.Y.Z

## Monitoring & Analytics
- **Firebase Crashlytics**: Crash reporting
- **Firebase Analytics**: User behavior
- **Cloud Monitoring**: Backend performance
- **Custom metrics**: AI usage, translation hits, cache performance
