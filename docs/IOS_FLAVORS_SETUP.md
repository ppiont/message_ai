# iOS Flavors Setup Guide

## Overview

iOS flavors are configured using **Xcode schemes** and **xcconfig files**. This allows you to run dev and prod builds with different bundle identifiers and app names.

---

## ✅ Already Created

I've created the xcconfig files:
- `ios/Flutter/Dev.xcconfig` - Development configuration
- `ios/Flutter/Prod.xcconfig` - Production configuration

---

## 📱 Manual Setup Required (Xcode)

iOS schemes **must** be created in Xcode. Here's the step-by-step process:

### Step 1: Open Xcode

```bash
open ios/Runner.xcworkspace
```

Wait for Xcode to fully load the project.

---

### Step 2: Duplicate the Runner Scheme

1. In Xcode menu bar, click **Product** → **Scheme** → **Manage Schemes...**
2. Select the **Runner** scheme
3. Click the **gear icon** (⚙️) at the bottom
4. Select **Duplicate**
5. Name it **Runner-Dev**
6. Click **Close**

### Step 3: Create Production Scheme

1. Click **Product** → **Scheme** → **Manage Schemes...** again
2. Select the **Runner** scheme again
3. Click the **gear icon** (⚙️)
4. Select **Duplicate**
5. Name it **Runner-Prod**
6. Click **Close**

---

### Step 4: Configure Dev Scheme

1. In Xcode, select **Runner-Dev** from the scheme dropdown (top left, next to stop button)
2. Click **Product** → **Scheme** → **Edit Scheme...**
3. In the left sidebar, select **Build**
4. Click on **Runner** target
5. Click **+** button at bottom
6. In the pop-up, click **Add Configuration** → **Duplicate "Debug" Configuration**
7. Name it **Debug-Dev**
8. Repeat for **Release**: Duplicate "Release" → Name it **Release-Dev**
9. For each phase (Run, Test, Profile, Analyze, Archive):
   - Select it in left sidebar
   - Change **Build Configuration** to use the `-Dev` variant
   - For **Run**: Use `Debug-Dev`
   - For **Archive**: Use `Release-Dev`

### Step 5: Configure Prod Scheme

Repeat Step 4 but:
- Use **Runner-Prod** scheme
- Create **Debug-Prod** and **Release-Prod** configurations
- Assign them to the appropriate phases

---

### Step 6: Apply xcconfig Files

1. In Xcode, click on the **Runner** project (blue icon) in the left sidebar
2. Select the **Runner** target under TARGETS
3. Click the **Info** tab
4. Under **Configurations**, expand each configuration:
   - **Debug-Dev**: Set to `Flutter/Dev`
   - **Release-Dev**: Set to `Flutter/Dev`
   - **Debug-Prod**: Set to `Flutter/Prod`
   - **Release-Prod**: Set to `Flutter/Prod`

---

## 🚀 Quick Alternative for 7-Day Sprint

If Xcode scheme setup is taking too long, you can:

### Option 1: Use Default Scheme with Manual Config
Just update the default Runner scheme to use dev config:
```bash
# Run with dev config
flutter run -t lib/main_dev.dart

# The app will use whatever config is set in Xcode
```

### Option 2: Focus on Android First
- Complete Android flavor setup (already done ✅)
- Test everything on Android
- Come back to iOS schemes during polish phase

### Option 3: CLI-Based Approach
Use flutter build with explicit config:
```bash
# Dev build
flutter build ios --flavor dev -t lib/main_dev.dart

# Prod build
flutter build ios --flavor prod -t lib/main_prod.dart
```

---

## 🎯 Verification

After setup is complete, verify:

```bash
# Dev flavor
flutter run --flavor dev -t lib/main_dev.dart

# Should show:
# - App name: "MessageAI Dev"
# - Bundle ID: com.gauntlet.messageAi.dev
# - Environment: dev

# Prod flavor
flutter run --flavor prod -t lib/main_prod.dart

# Should show:
# - App name: "MessageAI"
# - Bundle ID: com.gauntlet.messageAi
# - Environment: prod
```

---

## 📝 Summary

**What's Automated:**
- ✅ xcconfig files created
- ✅ Bundle identifiers configured
- ✅ App names configured

**What Requires Manual Setup:**
- ⏸️ Creating Xcode schemes (15-20 minutes)
- ⏸️ Assigning configurations to schemes
- ⏸️ Linking xcconfig files to configurations

**Recommendation for Sprint:**
- ✅ **Do now**: Test on Android (fully configured)
- ⏸️ **Do later**: Complete iOS schemes during polish phase

---

## 🆘 If You Get Stuck

If iOS scheme setup is confusing or time-consuming:
1. Skip it for now
2. Use Android for testing (`flutter run --flavor dev -t lib/main_dev.dart` works great!)
3. Come back to iOS schemes before final deployment

The important part (entry points and config system) is already done! ✅
