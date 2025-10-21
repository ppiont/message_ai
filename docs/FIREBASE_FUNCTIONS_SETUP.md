# Firebase Functions Setup Guide

## Overview

Firebase Functions will serve as the secure proxy layer for AI features, keeping API keys safe and implementing rate limiting.

---

## 🚀 Step 1: Run Firebase Init

Run this command from your project root:

```bash
firebase init
```

### What to Select During Init:

#### 1. Which Firebase features do you want to set up?
Select (use spacebar to select, enter to confirm):
- ☑️ **Functions**: Configure a Cloud Functions directory and files
- ☐ Firestore (skip - we'll do manually later)
- ☐ Storage (skip - we'll do manually later)
- ☐ Hosting (skip - not needed)
- ☐ Other services (skip for now)

#### 2. Please select an option:
- ✅ **Use an existing project**
- Select your `message-ai` project

#### 3. What language would you like to use?
- ✅ **JavaScript** (easier for 7-day sprint)
- ☐ TypeScript (more type safety but slower to write)

#### 4. Do you want to use ESLint?
- ✅ **Yes** (recommended)

#### 5. Do you want to install dependencies now?
- ✅ **Yes** (will run npm install)

---

## 📁 Expected Result

After `firebase init`, you should have:

```
functions/
├── .eslintrc.js
├── .gitignore
├── index.js              # Your Cloud Functions
├── package.json
└── node_modules/
```

---

## 🔧 Step 2: Configure Functions

After init completes, I'll help you:
1. Add OpenAI SDK to functions
2. Set up Secret Manager
3. Implement the AI proxy functions
4. Configure CORS and security

---

## 📦 Step 3: Install OpenAI SDK

After `firebase init` completes, run:

```bash
cd functions
npm install openai @google-cloud/secret-manager
cd ..
```

---

## 🚀 Step 4: Deploy Functions

**Don't deploy yet!** We'll deploy after implementing the functions. But when ready:

```bash
firebase deploy --only functions
```

---

## 💡 Important Notes

### Billing Requirement

⚠️ **Cloud Functions require the Blaze (Pay as you go) plan**

To upgrade:
1. Go to Firebase Console
2. Click Settings (⚙️) → Usage and billing
3. Click "Modify plan"
4. Select "Blaze plan"

**Don't worry about costs:**
- Free tier includes 2M invocations/month
- 400K GB-seconds compute time/month free
- For 7-day sprint, costs will be minimal ($0-$5)

### Firebase CLI

If you don't have Firebase CLI installed:
```bash
npm install -g firebase-tools
firebase login
```

---

## 🎯 After Init

Once `firebase init` completes, let me know and I'll:
1. ✅ Set up the initial functions structure
2. ✅ Add OpenAI integration
3. ✅ Configure Secret Manager
4. ✅ Implement rate limiting
5. ✅ Create the AI proxy functions

---

## 📝 Firebase Functions We'll Implement

For **International Communicator** persona:

### Translation Functions
1. `translateMessage` - Real-time translation
2. `detectLanguage` - Language detection
3. `detectFormality` - Formality level analysis
4. `explainIdiom` - Slang/idiom explanations

### Smart Reply
5. `generateSmartReplies` - Context-aware smart replies

### Supporting Functions
6. `processAIRequest` - Generic AI proxy with rate limiting
7. `getCulturalContext` - Cultural hints for translations

---

**Run `firebase init` now and let me know when it's complete!** 🚀

