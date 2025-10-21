# MessageAI - Project Architecture

## Overview
MessageAI is a Flutter application following **Clean Architecture** principles with a **feature-first** organization pattern. This document outlines the project structure and architectural decisions.

## Architecture Pattern

### Clean Architecture Layers
1. **Presentation Layer** (`presentation/`)
   - UI components (Pages, Widgets)
   - State management (Riverpod Providers)
   - User interaction handling

2. **Domain Layer** (`domain/`)
   - Business entities
   - Repository interfaces
   - Use cases (business logic)

3. **Data Layer** (`data/`)
   - Repository implementations
   - Data sources (Remote & Local)
   - Data models (DTOs)

### Dependency Rule
**Inner layers never depend on outer layers**. Dependencies always point inward:
```
Presentation → Domain ← Data
```

## Project Structure

```
lib/
├── main.dart                    # Application entry point
├── app.dart                     # Root app widget configuration
│
├── core/                        # Shared/core functionality
│   ├── database/               # drift local database
│   │   ├── app_database.dart  # Database configuration
│   │   ├── tables/            # Table definitions
│   │   └── daos/              # Data Access Objects
│   ├── error/                 # Error handling
│   │   ├── failures.dart
│   │   └── exceptions.dart
│   ├── network/               # Network utilities
│   │   └── network_info.dart
│   ├── constants/             # App-wide constants
│   │   └── api_constants.dart
│   └── utils/                 # Helper utilities
│       ├── date_formatter.dart
│       └── validators.dart
│
├── features/                   # Feature modules (feature-first)
│   ├── authentication/        # User authentication
│   │   ├── data/
│   │   │   ├── datasources/  # Remote (Firebase) & Local data sources
│   │   │   ├── models/       # Data transfer objects
│   │   │   └── repositories/ # Repository implementations
│   │   ├── domain/
│   │   │   ├── entities/     # Business entities
│   │   │   ├── repositories/ # Repository interfaces
│   │   │   └── usecases/     # Business logic
│   │   └── presentation/
│   │       ├── providers/    # Riverpod state providers
│   │       ├── pages/        # Full screen pages
│   │       └── widgets/      # Reusable UI components
│   │
│   ├── messaging/            # Core messaging functionality
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── ai_features/         # AI-powered features
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   └── translation/         # Language translation
│       ├── data/
│       ├── domain/
│       └── presentation/
│
├── config/                   # App-wide configuration
│   ├── routes/              # Navigation/routing
│   │   └── app_router.dart
│   ├── theme/               # Theme configuration
│   │   └── app_theme.dart
│   └── providers.dart       # Global Riverpod providers
│
└── l10n/                    # Internationalization
    ├── intl_en.arb
    ├── intl_es.arb
    └── intl_fr.arb
```

## Tech Stack

### State Management
- **Riverpod 3.0** - Compile-time safe state management with built-in DI

### Backend
- **Firebase Firestore** - Real-time database
- **Firebase Cloud Functions** - Serverless compute for AI features
- **Firebase Auth** - User authentication
- **Firebase Storage** - Media file storage
- **Firebase Cloud Messaging** - Push notifications

### Local Storage
- **drift** - Type-safe SQLite ORM for offline-first functionality

### AI Integration
- **OpenAI GPT-4o-mini** - Via Cloud Functions proxy
- **Google ML Kit** - On-device language detection

## Feature Modules

### 1. Authentication
- Phone/email authentication
- User profile management
- Session handling

### 2. Messaging
- 1-to-1 chat
- Group conversations
- Real-time message sync
- Offline-first with message queue
- Optimistic UI updates

### 3. AI Features (International Communicator)
- Real-time translation
- Language detection
- Cultural context hints
- Formality level adjustment
- Slang/idiom explanations
- Context-aware smart replies

### 4. Translation
- Multi-language support
- Translation memory
- Batch translation for groups

## Development Principles

### 1. Clean Architecture
- Separation of concerns
- Dependency inversion
- Testability

### 2. Feature-First Organization
- Self-contained feature modules
- Easy to locate related code
- Clear module boundaries

### 3. Offline-First
- Local database as source of truth
- Background sync when online
- Optimistic UI updates

### 4. Test-Driven Development
- Unit tests for business logic (90%+ coverage)
- Widget tests for UI components (25-30%)
- Integration tests for critical flows (10-15%)

## Data Flow

### Read Path (Online)
```
UI → Riverpod Provider → Repository →
Remote DataSource (Firestore) → Stream → UI Update
```

### Read Path (Offline)
```
UI → Riverpod Provider → Repository →
Local DataSource (drift) → Stream → UI Update
```

### Write Path
```
UI → Provider Action → Repository →
Local DB (immediate) + Firestore Queue →
Background Sync → Server Response → Update Local
```

## Next Steps

1. ✅ Project structure setup (Task 1)
2. ⏳ Configure Firebase projects - dev and prod (Task 2)
3. ⏳ Set up Flutter flavors - dev and prod (Task 3)
4. ⏳ Implement drift database (Task 4)
5. ⏳ Set up Riverpod (Task 11)

See `.taskmaster/tasks/` for complete task breakdown.

## References

- [Clean Architecture by Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [drift Documentation](https://drift.simonbinder.eu)
- [Firebase Documentation](https://firebase.google.com/docs)
