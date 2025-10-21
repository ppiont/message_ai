# Environment Configuration

## Overview

MessageAI uses **two environments** for streamlined development and deployment:

1. **Development** (`dev`)
2. **Production** (`prod`)

This two-environment approach is optimal for the 7-day sprint timeline, eliminating unnecessary complexity while maintaining proper separation between development and production.

---

## Environment Details

### Development Environment

**Purpose**: Active development, testing, and iteration

**Firebase Project**: `message-ai`

**Configuration Files**:
- Android: `firebase/dev/google-services.json`
- iOS: `firebase/dev/GoogleService-Info.plist`

**App Identifier**:
- Android: `com.gauntlet.message_ai.dev`
- iOS: `com.gauntlet.messageAi.dev`

**Features**:
- ✅ All Firebase services in test mode
- ✅ Debug logging enabled
- ✅ Hot reload/restart during development
- ✅ Relaxed security rules for rapid iteration

**Build Commands**:
```bash
# Run on device/emulator
flutter run --flavor dev -t lib/main_dev.dart

# Build APK
flutter build apk --flavor dev -t lib/main_dev.dart

# Build iOS
flutter build ios --flavor dev -t lib/main_dev.dart
```

---

### Production Environment

**Purpose**: Final deployment, real users, app store releases

**Firebase Project**: `message-ai-prod`

**Configuration Files**:
- Android: `firebase/prod/google-services.json`
- iOS: `firebase/prod/GoogleService-Info.plist`

**App Identifier**:
- Android: `com.gauntlet.message_ai`
- iOS: `com.gauntlet.messageAi`

**Features**:
- ✅ Production Firebase security rules
- ✅ Minimal logging
- ✅ Performance optimizations enabled
- ✅ Proper error reporting to Crashlytics

**Build Commands**:
```bash
# Build release APK
flutter build apk --release --flavor prod -t lib/main_prod.dart

# Build iOS for App Store
flutter build ios --release --flavor prod -t lib/main_prod.dart
```

---

## Why Two Environments?

### ✅ Benefits

1. **Simplicity**: Fewer configurations to manage
2. **Cost-Effective**: Only 2 Firebase projects to maintain
3. **Clear Separation**: Dev for testing, prod for users
4. **Faster Iteration**: Less overhead switching between environments
5. **Sprint-Friendly**: Aligns with 7-day timeline

### 🚫 Why No Staging?

For a 7-day sprint project:
- Staging adds complexity without proportional value
- Dev environment serves the testing/validation purpose
- Can add staging later if project scales significantly
- Most bugs caught in dev before prod deployment
- Direct dev → prod flow is common for small teams/MVPs

---

## Environment Variables

Each environment has access to different configurations via `lib/config/env_config.dart`:

```dart
abstract class EnvConfig {
  String get apiBaseUrl;
  bool get enableDebugLogging;
  bool get enableAnalytics;
  String get firebaseProjectId;
}

class DevConfig implements EnvConfig {
  @override
  String get apiBaseUrl => 'https://dev-api.messageai.app';
  
  @override
  bool get enableDebugLogging => true;
  
  @override
  bool get enableAnalytics => false;
  
  @override
  String get firebaseProjectId => 'message-ai';
}

class ProdConfig implements EnvConfig {
  @override
  String get apiBaseUrl => 'https://api.messageai.app';
  
  @override
  bool get enableDebugLogging => false;
  
  @override
  bool get enableAnalytics => true;
  
  @override
  String get firebaseProjectId => 'message-ai-prod';
}
```

---

## Firebase Services by Environment

### Development
- **Firestore**: Test mode, relaxed rules
- **Storage**: Test mode, 30-day data retention
- **Authentication**: Email/password, test users
- **Functions**: Emulator support for local testing
- **Messaging**: Test FCM tokens

### Production
- **Firestore**: Production rules, strict access control
- **Storage**: Backup enabled, permanent retention
- **Authentication**: Production users only
- **Functions**: Deployed to Firebase, monitored
- **Messaging**: Production FCM with proper certificates

---

## Security Rules

### Development (Firestore)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Relaxed for testing
    match /{document=**} {
      allow read, write: if request.time < timestamp.date(2025, 12, 31);
    }
  }
}
```

### Production (Firestore)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Strict rules
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    match /conversations/{conversationId} {
      allow read: if request.auth.uid in resource.data.participantIds;
      allow write: if request.auth.uid in request.resource.data.participantIds;
    }
    
    match /conversations/{conversationId}/messages/{messageId} {
      allow read: if request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participantIds;
      allow create: if request.auth.uid == request.resource.data.senderId;
    }
  }
}
```

---

## Deployment Checklist

### Before Deploying to Production

- [ ] All tests passing in dev
- [ ] Security rules updated and tested
- [ ] API keys configured in Secret Manager
- [ ] Crashlytics enabled and tested
- [ ] Analytics tracking verified
- [ ] Performance benchmarks met
- [ ] Production Firebase project created
- [ ] Production config files in place
- [ ] App signing configured (Android keystore, iOS certificates)

---

## Future: Adding Staging (If Needed)

If the project scales and staging becomes necessary:

1. Create `message-ai-staging` Firebase project
2. Add `firebase/staging/` directory
3. Create `main_staging.dart`
4. Update Android/iOS flavor configs
5. Add staging security rules
6. Document staging-specific workflows

**Decision Point**: Add staging when:
- Team size > 5 developers
- User base > 10,000 active users
- Multiple releases per day
- Complex QA/UAT processes required

---

## Environment Switching

### For Developers

During development, easily switch between environments:

```bash
# Quick dev testing
flutter run --flavor dev -t lib/main_dev.dart

# Test prod configuration locally
flutter run --flavor prod -t lib/main_prod.dart
```

### VS Code Launch Configurations

Add to `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Dev",
      "request": "launch",
      "type": "dart",
      "program": "lib/main_dev.dart",
      "args": [
        "--flavor",
        "dev"
      ]
    },
    {
      "name": "Prod",
      "request": "launch",
      "type": "dart",
      "program": "lib/main_prod.dart",
      "args": [
        "--flavor",
        "prod"
      ]
    }
  ]
}
```

---

## Summary

**Dev Environment**: Fast iteration, testing, debugging  
**Prod Environment**: Real users, app store releases, monitored

This two-environment strategy provides the right balance of simplicity and separation for a successful 7-day sprint and beyond.

