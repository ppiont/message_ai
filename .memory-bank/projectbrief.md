# Project Brief: WhatsApp Clone with AI Features

## Project Vision
Build a **functional messaging platform** for international communicators with advanced AI capabilities as part of the GauntletAI curriculum (7-day sprint).

## Core Objectives
1. **Real-time messaging** with offline-first architecture
2. **International communication** with automatic translation and language detection
3. **AI-powered features** - 5 required features + 1 advanced capability
4. **Solid infrastructure** with proper testing and clean code
5. **Deployable app** ready for TestFlight/APK/Expo Go

## Target Users (Persona: International Communicator)
- **International communicators** who frequently chat across language barriers
- People with friends/family/colleagues speaking different languages
- Users facing: language barriers, translation nuances, copy-paste overhead, learning difficulty

## Technical Foundation
- **Platform**: Flutter (cross-platform mobile app)
- **Backend**: Firebase (Firestore + Cloud Functions + Storage)
- **State Management**: Riverpod 3.0
- **Local Storage**: drift (SQLite ORM)
- **AI**: OpenAI GPT-4o-mini via Firebase Cloud Functions

## Key Constraints
- **7-day sprint**: MVP in 24 hours, final submission in 7 days
- Must support **offline-first** operation
- **Security**: API keys never exposed to clients (Cloud Functions proxy)
- **Performance**: Smooth UI, responsive AI features
- **Testing**: Core functionality well-tested
- **Cost**: Reasonable AI costs during development

## Success Metrics (Curriculum Requirements)
- Real-time messaging between 2+ devices working reliably
- Offline scenarios handled gracefully
- All 5 required AI features functional
- 1 advanced AI capability implemented
- Deployable to TestFlight/APK/Expo Go

## Development Phases
1. **MVP (24 hours)**: Core messaging + group chat + authentication
2. **AI Integration (Days 2-5)**: 5 required AI features
3. **Advanced Feature (Days 5-6)**: 1 advanced AI capability
4. **Polish & Deploy (Day 7)**: Testing, video, deployment

## Non-Goals (Out of Scope for 7-Day Sprint)
- Voice/video calls (messaging only)
- Stories or status features
- Payment integration
- Complex UI animations (focus on functionality)
- Production-scale optimization (1M+ users)
- Extensive test coverage (focus on core paths)

