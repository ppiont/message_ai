# Firebase Setup Status

## ✅ Completed by AI

### 1. Dependencies Added
- ✅ Added Firebase packages to `pubspec.yaml`
- ✅ Ran `flutter pub get` - all dependencies installed

### 2. Android Configuration
- ✅ Added Google Services plugin to `android/settings.gradle.kts`
- ✅ Applied Google Services plugin in `android/app/build.gradle.kts`
- ✅ Updated package name to `com.gauntlet.message_ai`
- ✅ Updated app label to "MessageAI"

### 3. Directory Structure
- ✅ Created `firebase/dev/` directory for config files
- ✅ Created `firebase/prod/` directory (for future use)

### 4. Documentation
- ✅ Created comprehensive setup guide: `docs/FIREBASE_SETUP.md`

---

## 📋 Required: User Actions

### Step 1: Firebase Console Setup

Go to [Firebase Console](https://console.firebase.google.com) and:

1. **Create Firebase Project**
   - Name: `message-ai` (actual project name)
   - Enable Google Analytics (recommended)

2. **Enable Services** (for the project):
   - ☐ Authentication (Email/Password)
   - ☐ Firestore Database (Test mode, location: us-central1)
   - ☐ Cloud Storage (Test mode)
   - ☐ Cloud Messaging (FCM)

3. **Register Android App**:
   - Package name: `com.gauntlet.message_ai`
   - Download `google-services.json`

4. **Register iOS App**:
   - Bundle ID: `com.gauntlet.messageAi` (get from Xcode)
   - Download `GoogleService-Info.plist`

### Step 2: Add Configuration Files

```bash
# Copy Android config
cp ~/Downloads/google-services.json ./firebase/dev/
cp ./firebase/dev/google-services.json ./android/app/

# Copy iOS config to firebase folder
cp ~/Downloads/GoogleService-Info.plist ./firebase/dev/

# For iOS: MUST add via Xcode
open ios/Runner.xcworkspace
# Then: Right-click Runner → Add Files → Select GoogleService-Info.plist
```

### Step 3: Install iOS Dependencies

```bash
cd ios && pod install && cd ..
```

---

## 🔍 Verification Checklist

Before marking Task 2 complete, verify:

- ☐ Firebase project created in console
- ☐ All required services enabled
- ☐ `google-services.json` in `firebase/dev/` and `android/app/`
- ☐ `GoogleService-Info.plist` in `firebase/dev/` and added to Xcode
- ☐ iOS pods installed
- ☐ App builds without errors: `flutter run`

---

## 📱 Package/Bundle Information

Use these when registering apps in Firebase Console:

- **Android Package**: `com.gauntlet.message_ai`
- **iOS Bundle ID**: Check in Xcode or run:
  ```bash
  grep -A 1 "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj | head -1
  ```

---

## 🚨 Troubleshooting

### Build Errors

If you get Gradle errors:
```bash
cd android && ./gradlew clean && cd ..
flutter clean
flutter pub get
```

### iOS Pod Errors

If pod install fails:
```bash
cd ios
pod repo update
pod install
cd ..
```

### Firebase Not Initializing

- Verify `google-services.json` is in `android/app/`
- Verify `GoogleService-Info.plist` is in Xcode's "Copy Bundle Resources"
- Check that app package/bundle ID matches Firebase console

---

## ⏭️ Next Steps

Once setup is complete:
1. AI will update `main.dart` with Firebase initialization code
2. Test Firebase connection
3. Move to Task 3: Flutter flavors (optional for MVP)
4. OR move to Task 4: Set up drift database

---

## 📚 Reference Files

- Setup Guide: `docs/FIREBASE_SETUP.md`
- Android Config: `android/app/build.gradle.kts`
- Android Settings: `android/settings.gradle.kts`
- Package: `pubspec.yaml`

---

**Current Status**: ⏸️ Waiting for user to complete Firebase Console setup
