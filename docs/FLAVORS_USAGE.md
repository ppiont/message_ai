# Flutter Flavors Usage Guide

## 🎯 Quick Reference

MessageAI supports **two flavors**: `dev` and `prod`

---

## 🚀 Running the App

### Development Flavor

```bash
# Run on connected device/emulator
flutter run --flavor dev -t lib/main_dev.dart

# Run on specific device
flutter run --flavor dev -t lib/main_dev.dart -d <device-id>

# Run in profile mode (performance testing)
flutter run --flavor dev -t lib/main_dev.dart --profile
```

### Production Flavor

```bash
# Run on connected device/emulator
flutter run --flavor prod -t lib/main_prod.dart

# Run on specific device
flutter run --flavor prod -t lib/main_prod.dart -d <device-id>
```

---

## 📦 Building the App

### Android

```bash
# Dev - Debug APK
flutter build apk --flavor dev -t lib/main_dev.dart

# Dev - Release APK
flutter build apk --release --flavor dev -t lib/main_dev.dart

# Prod - Release APK
flutter build apk --release --flavor prod -t lib/main_prod.dart

# Prod - App Bundle (for Play Store)
flutter build appbundle --release --flavor prod -t lib/main_prod.dart
```

### iOS

```bash
# Dev - Debug build
flutter build ios --flavor dev -t lib/main_dev.dart

# Prod - Release build
flutter build ios --release --flavor prod -t lib/main_prod.dart
```

**Note:** iOS requires Xcode schemes to be configured. See `docs/IOS_FLAVORS_SETUP.md` for details.

---

## 🎨 VS Code Launch Configurations

If you're using VS Code, launch configurations are already set up! Just:

1. Open **Run and Debug** panel (Cmd/Ctrl + Shift + D)
2. Select a configuration from the dropdown:
   - **Dev (main_dev.dart)** - Run dev flavor
   - **Prod (main_prod.dart)** - Run prod flavor
   - **Dev (Profile Mode)** - Performance testing
   - **Prod (Profile Mode)** - Performance testing
3. Press **F5** or click the green play button

---

## 🔍 Flavor Differences

| Feature | Dev Flavor | Prod Flavor |
|---------|-----------|-------------|
| **App Name** | MessageAI (Dev) | MessageAI |
| **Android ID** | com.gauntlet.message_ai.dev | com.gauntlet.message_ai |
| **iOS Bundle ID** | com.gauntlet.messageAi.dev | com.gauntlet.messageAi |
| **Firebase Project** | message-ai | message-ai-prod |
| **Debug Logging** | ✅ Enabled | ❌ Disabled |
| **Analytics** | ❌ Disabled | ✅ Enabled |
| **Crashlytics** | ❌ Disabled | ✅ Enabled |

---

## 📱 Installing Multiple Flavors

Because dev and prod have different app IDs, you can install **both flavors simultaneously** on the same device!

```bash
# Install dev
flutter install --flavor dev -t lib/main_dev.dart

# Install prod (won't overwrite dev!)
flutter install --flavor prod -t lib/main_prod.dart
```

Now you have both MessageAI (Dev) and MessageAI apps on your device.

---

## 🧪 Testing

```bash
# Run tests (uses default config)
flutter test

# Run tests with specific flavor context
flutter test --dart-define=FLAVOR=dev
flutter test --dart-define=FLAVOR=prod
```

---

## 🐛 Debugging

### Check Current Environment

The app displays environment info on the home screen:
- **App Name**: Shows "(Dev)" suffix for dev builds
- **Environment**: Shows "dev" or "prod"
- **Firebase Project**: Shows which Firebase project is being used

### Debug Prints (Dev Only)

In development, you'll see debug logs:
```
🚀 Starting MessageAI in dev mode
📱 App name: MessageAI (Dev)
🔥 Firebase project: message-ai
📊 Analytics enabled: false
🐛 Debug logging: true
```

Production builds don't show these logs.

---

## 📋 Common Commands Cheat Sheet

```bash
# Quick dev run
flutter run --flavor dev -t lib/main_dev.dart

# Quick prod run  
flutter run --flavor prod -t lib/main_prod.dart

# Build release APK (dev)
flutter build apk --release --flavor dev -t lib/main_dev.dart

# Build release APK (prod)
flutter build apk --release --flavor prod -t lib/main_prod.dart

# List devices
flutter devices

# Run on specific device
flutter run --flavor dev -t lib/main_dev.dart -d chrome
```

---

## 🎯 Recommended Workflow

### During Development
1. **Always use dev flavor**: `flutter run --flavor dev -t lib/main_dev.dart`
2. Test against dev Firebase project
3. Debug logging helps catch issues early
4. No analytics pollution

### Before Release
1. **Test prod flavor**: `flutter run --flavor prod -t lib/main_prod.dart`
2. Verify Firebase connection to prod project
3. Check analytics and crashlytics setup
4. Test release builds

### For Deployment
1. Build prod release: `flutter build apk --release --flavor prod -t lib/main_prod.dart`
2. Test the release build thoroughly
3. Submit to Play Store / App Store

---

## 🔧 Troubleshooting

### "Flavor not found" Error
Make sure you're using both `--flavor` AND `-t` together:
```bash
# ✅ Correct
flutter run --flavor dev -t lib/main_dev.dart

# ❌ Wrong (missing -t)
flutter run --flavor dev
```

### Android Build Fails
Try cleaning and rebuilding:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run --flavor dev -t lib/main_dev.dart
```

### iOS Scheme Not Found
See `docs/IOS_FLAVORS_SETUP.md` for Xcode scheme configuration.

---

## 📚 Additional Resources

- **Environment Config**: `lib/config/env_config.dart`
- **Android Flavors**: `android/app/build.gradle.kts`
- **iOS Config**: `ios/Flutter/Dev.xcconfig` and `ios/Flutter/Prod.xcconfig`
- **iOS Setup Guide**: `docs/IOS_FLAVORS_SETUP.md`
- **Launch Configurations**: `.vscode/launch.json`

---

Happy coding! 🚀

