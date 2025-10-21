# Active Context

## Current Status
**Project: Day 0 - Foundation Complete + Auth Ready**
**Sprint Timeline: 7 Days Total**
**Curriculum: GauntletAI**

Foundation phase is complete! We have:
- ✅ Flutter project structure with clean architecture
- ✅ Firebase integration (dev environment: message-ai)
- ✅ Environment configuration (dev/prod flavors working on iOS & Android)
- ✅ Comprehensive testing infrastructure (238 tests passing)
- ✅ Drift database with complete DAOs (75+ methods)
- ✅ Riverpod 3.0 state management setup
- ✅ Core error handling infrastructure (Crashlytics integration)
- ✅ Network connectivity monitoring
- ✅ **Firebase Authentication (Email + Phone)**
  - Email auth: Sign up/in, password reset, verification
  - Phone auth: Ready for device testing
  - 29 comprehensive tests (all passing)
  - Works perfectly in emulators

**Ready for**: Task 27 - Repository layer (message/conversation/user)

## Current Work Focus

### Sprint Timeline
- **MVP Deadline**: 24 hours (Tuesday)
- **Early Submission**: 4 days (Friday)
- **Final Submission**: 7 days (Sunday 10:59 PM CT)

### Immediate Next Steps (Day 0 → Day 1 MVP)
1. **Set up Flutter project** with basic structure
2. **Initialize Firebase** (single project for now, can add environments later)
3. **Configure authentication** (phone or email - whatever's fastest)
4. **Build basic messaging UI** (chat screen, conversation list)
5. **Implement real-time sync** (Firestore listeners)
6. **Add local persistence** (drift or simpler solution)
7. **Create group chat** (3+ users)
8. **Add read receipts** and delivery states
9. **Test on 2 devices** (real-time messaging working)

### MVP Requirements (Must Have in 24 Hours)
- [ ] One-on-one chat functionality
- [ ] Real-time message delivery between 2+ users
- [ ] Message persistence (survives app restarts)
- [ ] Optimistic UI updates
- [ ] Online/offline status indicators
- [ ] Message timestamps
- [ ] User authentication
- [ ] Basic group chat (3+ users)
- [ ] Message read receipts
- [ ] Push notifications (foreground at minimum)
- [ ] Deployed backend + running on emulator

## Recent Changes
- **2024-10-21**: **Email authentication added** - Sign up/in, password reset, verification (29 tests)
- **2024-10-21**: Task 15 completed - Firebase Authentication (Email + Phone) with full exception mapping
- **2024-10-21**: Task 13 completed - Network connectivity monitoring (19 tests)
- **2024-10-21**: Task 26 completed - Conversation entity/model (46 tests)
- **2024-10-21**: Task 25 completed - Message entity/model (20 tests)
- **2024-10-21**: Task 12 completed - Core error handling (exceptions, failures, mapper, logger, 55 tests)
- **2024-10-21**: Task 11 completed - Riverpod providers (8 tests)
- **2024-10-21**: Tasks 8-10 completed - DAOs with 75+ methods (85 tests)
- **2024-10-21**: Tasks 4-7 completed - Drift database fully implemented and tested (65 tests)
- **2024-10-21**: Tasks 1-3 completed - Flutter project structure, Firebase, flavors working
- **2024-10-21**: Created Drift and Dart/Flutter MCP documentation rules
- **2024-10-21**: Dependency updates - All Firebase packages updated to latest versions
- **2024-10-21**: Environment simplification - Removed staging, using dev/prod only
- **2024-10-21**: Taskmaster-ai initialization - 120 atomic tasks generated
- **2024-10-21**: Memory Bank initialized and PRD documented

## Active Decisions

### Architecture Decisions Made
✅ **Persona**: International Communicator (language barriers, translation, cultural context)
✅ **Platform**: Flutter (cross-platform)
✅ **Database**: Cloud Firestore (real-time sync + offline support)
✅ **State Management**: Riverpod 3.0 (compile-time safety, streams)
✅ **Local Storage**: drift (type-safe SQL ORM)
✅ **AI Model**: OpenAI GPT-4o-mini (via Cloud Functions)
✅ **Architecture**: Clean Architecture with feature-first (but simplified for 7-day sprint)
✅ **Auth Method**: Email (emulator testing) + Phone (device testing) via Firebase Auth

### Pending Decisions
❓ **Translation Service**: Google Cloud Translation vs. DeepL vs. GPT-4o-mini for translation
❓ **Advanced AI Feature**: Context-aware smart replies OR intelligent data extraction (must choose 1)
❓ **Navigation**: go_router vs. simple Navigator (keep it simple for now)

## Key Considerations

### For 7-Day Sprint
- **Vertical Slices**: Finish messaging completely before adding AI features
- **Real Device Testing**: Test on physical devices, not just simulators
- **Firebase First**: Use Firebase for quick setup (Firestore, Auth, Functions, FCM)
- **Simplify Where Possible**: Clean Architecture is great but don't over-engineer for 7 days

### Critical Path
Day 1: **Messaging must work** (this is the hard gate)
Days 2-5: **5 Required AI features** for International Communicator
Days 5-6: **1 Advanced AI capability**
Day 7: **Polish, demo video, deployment**

### Technical Debt to Avoid
- Don't skip offline scenarios (offline-first is a requirement)
- Don't hardcode API keys (use Cloud Functions + Secret Manager)
- Don't ignore app lifecycle (background/foreground/force quit must work)
- Don't overbuild for scale (2-10 users is fine, not 1M users)

## Dependencies & Blockers

### Current Blockers
- None (project just starting)

### External Dependencies
- **Firebase account** (free tier is fine)
- **OpenAI API key** (for AI features Days 2+)
- **Physical devices** for testing (iOS + Android or 2x same platform)
- **TestFlight/Google Play** accounts (for final deployment)

## Notes for Future Me

### Important Context
- This is a **7-day curriculum project** for GauntletAI, not a production app
- **MVP in 24 hours** is a hard gate - messaging must work reliably
- **Persona**: International Communicator (focus on translation/language features)
- **5 required AI features + 1 advanced** must be functional
- **Security**: Never expose API keys to client (use Cloud Functions)

### Things to Remember
- **Messaging first**: Don't touch AI until messaging works end-to-end
- **Test scenarios**: 2 devices, offline mode, app lifecycle, rapid messages, group chat
- **Firestore indexes**: Create them as needed for queries
- **Optimistic UI**: Messages appear instantly, then confirm
- **Cloud Functions**: AI proxy for security + cost control

### Watch Out For
- Don't over-engineer for scale (2-10 users is fine)
- iOS push notifications can be tricky (start simple with foreground)
- Test on real devices, not just simulators
- Keep AI costs reasonable during development
- Translation caching helps with costs and speed

## Context for AI Agent

When I return to this project after a memory reset, I should:
1. **Read activeContext.md FIRST** - understand it's a 7-day sprint
2. **Check progress.md** - see what phase we're in (MVP → AI features → Polish)
3. **Review projectbrief.md** - remember the International Communicator persona
4. **Look at systemPatterns.md** - architectural decisions
5. **Reference techContext.md** - technical setup details

**Key Reminder**: This is a **7-day curriculum project**, not a production app for millions of users. Focus on:
- Getting messaging working reliably (MVP = hard gate)
- Implementing 5 required + 1 advanced AI feature
- Keeping it simple enough to finish in 7 days
- Making it deployable (TestFlight/APK/Expo Go)
