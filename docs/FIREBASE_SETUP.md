# Firebase Setup Guide

This guide walks you through setting up Firebase for the MessageAI project. We'll create **three Firebase projects** for different environments.

## 📋 Prerequisites

- Google/Firebase account
- Access to [Firebase Console](https://console.firebase.google.com)
- Flutter installed and working

---

## 🎯 Step 1: Create Firebase Projects

### For 7-Day Sprint: Start with DEV Project

For the curriculum project timeline, **start with dev** and add prod later:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click **"Add project"**
3. **Project name**: `message-ai`
4. Click **Continue**
5. **Google Analytics**: Enable (recommended)
6. Select or create Analytics account
7. Click **Create project**
8. Wait for project creation (~30 seconds)
9. Click **Continue**

**Note**: We'll create `message-ai-prod` later before final deployment.

### For Production (Optional - Later):

If you want separate environments:
- **Development**: `message-ai`
- **Production**: `message-ai-prod`

---

## ⚙️ Step 2: Enable Firebase Services

For **each project**, enable the following services:

### 2.1 Authentication

1. In Firebase Console, click **Authentication** (left sidebar)
2. Click **Get started**
3. Select **Sign-in methods** tab
4. Enable **Email/Password**:
   - Click on **Email/Password**
   - Toggle **Enable**
   - Toggle **Email link (passwordless sign-in)** if desired
   - Click **Save**
5. *(Optional)* Enable **Phone** authentication if needed for MVP

### 2.2 Firestore Database

1. Click **Firestore Database** (left sidebar)
2. Click **Create database**
3. **Start mode**: Select **Test mode** (for development)
   - ⚠️ Note: Change to production rules before launch
4. **Location**: Choose closest to your users (e.g., `us-central1`)
5. Click **Enable**
6. Wait for provisioning (~1 minute)

### 2.3 Cloud Storage

1. Click **Storage** (left sidebar)
2. Click **Get started**
3. **Security rules**: Start in **Test mode**
4. **Location**: Same as Firestore
5. Click **Done**

### 2.4 Cloud Functions

1. Click **Functions** (left sidebar)
2. Click **Get started**
3. **Note**: Functions will be deployed later via CLI
4. Upgrade to **Blaze (Pay as you go)** plan if needed for production
   - ⚠️ For dev: Free tier is sufficient initially

### 2.5 Cloud Messaging (FCM)

1. Click **Cloud Messaging** (left sidebar)
2. Click **Get started**
3. **Note**: Configuration will be added when setting up apps

### 2.6 Crashlytics

1. Click **Crashlytics** (left sidebar)
2. Click **Get started**
3. **Note**: SDK configuration comes next

---

## 📱 Step 3: Register Apps

### For Android

1. In Firebase Console, click **Project Overview** (top left)
2. Click **Android** icon (🤖)
3. **Package name**: `com.gauntlet.message_ai` (or your package name)
   - Find in: `android/app/build.gradle.kts` → `namespace`
4. **App nickname**: `MessageAI (Dev)`
5. **Debug signing certificate** (optional for now)
6. Click **Register app**
7. **Download** `google-services.json`
8. Click **Next** → **Next** → **Continue to console**

### For iOS

1. In Firebase Console, click **Project Overview**
2. Click **iOS** icon (🍎)
3. **Bundle ID**: `com.gauntlet.messageAi` (or your bundle ID)
   - Find in: `ios/Runner.xcodeproj/project.pbxproj`
4. **App nickname**: `MessageAI (Dev)`
5. **App Store ID**: (leave blank for now)
6. Click **Register app**
7. **Download** `GoogleService-Info.plist`
8. Click **Next** → **Next** → **Continue to console**

---

## 📂 Step 4: Save Configuration Files

### Save to Project

After downloading the config files:

```bash
# For Development environment
cp ~/Downloads/google-services.json ./firebase/dev/
cp ~/Downloads/GoogleService-Info.plist ./firebase/dev/

# For Production (if created later)
# cp google-services-prod.json ./firebase/prod/google-services.json
# cp GoogleService-Info-prod.plist ./firebase/prod/GoogleService-Info.plist
```

---

## 🔧 Step 5: Configure Android

### 5.1 Add google-services.json

```bash
# Copy to Android app directory
cp firebase/dev/google-services.json android/app/
```

### 5.2 Update android/build.gradle.kts

I'll handle this in the code - you don't need to do anything here.

### 5.3 Update android/app/build.gradle.kts

I'll handle this in the code - you don't need to do anything here.

---

## 🍎 Step 6: Configure iOS

### 6.1 Add GoogleService-Info.plist

**Important**: Must be done via Xcode for proper bundling.

1. Open Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. In Xcode:
   - Right-click on **Runner** folder (in left sidebar)
   - Select **Add Files to "Runner"...**
   - Navigate to `firebase/dev/GoogleService-Info.plist`
   - **Check**: ☑️ Copy items if needed
   - **Check**: ☑️ Add to target: Runner
   - Click **Add**

3. Verify in Xcode:
   - Select **Runner** in left sidebar
   - Click **Build Phases** tab
   - Expand **Copy Bundle Resources**
   - Verify `GoogleService-Info.plist` is listed

---

## ✅ Step 7: Install Dependencies

After you've completed the Firebase Console setup:

```bash
# Get Flutter packages
flutter pub get

# For iOS (run from project root)
cd ios && pod install && cd ..
```

---

## 🧪 Step 8: Verify Setup

After I configure the code, we'll verify with:

```bash
flutter run
```

The app should initialize Firebase without errors.

---

## 📝 What You Need to Provide

Once you've completed the Firebase Console setup, let me know and provide:

1. ✅ Confirmation that Firebase project(s) are created
2. ✅ Confirmation that all services are enabled
3. ✅ Confirmation that `google-services.json` is in `firebase/dev/`
4. ✅ Confirmation that `GoogleService-Info.plist` is in `firebase/dev/`
5. ✅ Your Firebase project ID: `message-ai` (for functions deployment later)

---

## 🎯 For 7-Day Sprint

**Recommended minimal setup:**
1. ✅ One Firebase project (`message-ai`)
2. ✅ Enable: Authentication (Email), Firestore, Storage, Messaging
3. ✅ Register both Android and iOS apps
4. ✅ Download config files

**Skip for now** (can add later):
- Multiple environments (staging/prod)
- Phone authentication
- Cloud Functions setup (will do when implementing AI features)
- Crashlytics (add during polish phase)

---

## 🚀 Next Steps

After you complete the Firebase Console setup:
1. I'll configure the Android gradle files
2. I'll configure the iOS project settings
3. I'll update `main.dart` with Firebase initialization
4. We'll test the setup
5. Move to Task 3: Flutter flavors (optional for MVP)

---

## 📚 References

- [Firebase Console](https://console.firebase.google.com)
- [FlutterFire Documentation](https://firebase.flutter.dev)
- [Firebase Setup for Flutter](https://firebase.google.com/docs/flutter/setup)

---

## ⚠️ Important Notes

1. **Never commit** `google-services.json` or `GoogleService-Info.plist` to public repos
2. Add to `.gitignore` if planning to open source
3. For the 7-day sprint, keep it simple: one project is fine
4. Blaze plan needed for Cloud Functions (has free tier)

---

**Ready?** Let me know when you've completed Steps 1-4, and I'll handle the rest! 🚀

