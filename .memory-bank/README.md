# Memory Bank README

## Purpose
This Memory Bank serves as my persistent knowledge base across sessions. After each memory reset, I rely **entirely** on these files to understand the project and continue work effectively.

## Core Files (Read in Order)

### 1. projectbrief.md - Start Here
**What**: Foundation document defining the project
**Contains**: Vision, objectives, constraints, success metrics
**Read when**: Every session start, before any work

### 2. productContext.md - The "Why"
**What**: Product rationale and user experience goals
**Contains**: Problems solved, user flows, feature priorities
**Read when**: Understanding user needs, designing features

### 3. systemPatterns.md - The "How"
**What**: Architecture and design patterns
**Contains**: Technical decisions, data flows, component relationships
**Read when**: Implementing features, making architectural decisions

### 4. techContext.md - The "What"
**What**: Technology stack and setup
**Contains**: Dependencies, tools, build processes, constraints
**Read when**: Setting up environment, adding dependencies

### 5. activeContext.md - Current Focus
**What**: What's happening right now
**Contains**: Current phase, active decisions, next steps, blockers
**Read when**: Every session start, planning next actions

### 6. progress.md - Status Tracking
**What**: What's done and what's left
**Contains**: Completed features, known issues, milestones
**Read when**: Assessing project state, planning work

## Update Triggers

### When to Update
1. **After completing a phase or milestone**
2. **When discovering new patterns or insights**
3. **When making architectural decisions**
4. **User explicitly requests: "update memory bank"**
5. **When context needs clarification**

### What to Update
- **activeContext.md**: Every significant change (current phase, decisions, next steps)
- **progress.md**: After completing features or milestones
- **systemPatterns.md**: When implementing new patterns or refactoring
- **techContext.md**: When adding dependencies or changing setup
- **productContext.md**: Rarely (only if requirements change)
- **projectbrief.md**: Very rarely (only if core vision changes)

### Full Review Process
When user says **"update memory bank"**:
1. Read ALL 6 core files
2. Update relevant sections based on recent work
3. Focus especially on activeContext.md and progress.md
4. Document any new patterns or decisions
5. Update .cursor/rules/ if new patterns emerged

## File Hierarchy
```
projectbrief.md ─┬─> productContext.md ───┐
                 ├─> systemPatterns.md ────┤
                 └─> techContext.md ────────┤
                                            ├─> activeContext.md ─> progress.md
```

## Session Workflow

### Starting a New Session
```
1. Read projectbrief.md (understand the project)
2. Read activeContext.md (understand current focus)
3. Read progress.md (see what's done)
4. Read relevant detailed files (system/tech/product)
5. Begin work
```

### Ending a Session (if significant progress)
```
1. Update activeContext.md (new current state)
2. Update progress.md (mark completed items)
3. Document any new patterns in systemPatterns.md
4. Note any new decisions or blockers
```

## Quick Reference

### Project Type
**GauntletAI Curriculum Project** - 7-day sprint
Flutter mobile app (WhatsApp clone with AI features)

### Key Technologies
- **Frontend**: Flutter + Riverpod 3.0
- **Backend**: Firebase (Firestore + Cloud Functions)
- **Local DB**: drift
- **AI**: OpenAI GPT-4o-mini

### Architecture
Clean Architecture with feature-first organization (simplified for 7-day sprint), offline-first design

### Timeline
- **MVP**: 24 hours (Tuesday) - HARD GATE
- **AI Features**: Days 2-5
- **Advanced Feature**: Days 5-6
- **Final Submission**: Day 7 (Sunday 10:59 PM CT)

### Persona
**International Communicator** - Focus on translation, language detection, cultural context

### Critical Constraints
- 7-day sprint timeline
- MVP must pass in 24 hours
- 5 required AI features + 1 advanced
- Offline-first (not optional)
- API keys never exposed to client
- Keep scope realistic (2-10 users, not 1M users)

## Additional Context Files
As the project grows, create additional files in `.memory-bank/` for:
- Complex feature documentation
- Integration specifications
- API documentation
- Deployment procedures
- Testing strategies

Organize in subdirectories as needed:
```
.memory-bank/
├── README.md (this file)
├── [6 core files]
├── features/
│   ├── messaging-deep-dive.md
│   ├── ai-integration-details.md
│   └── translation-system.md
├── integrations/
│   ├── firebase-setup.md
│   └── openai-configuration.md
└── deployment/
    ├── ci-cd-pipeline.md
    └── release-process.md
```

## Remember
**After every memory reset, I begin completely fresh.** These files are my **only** connection to the project. They must be:
- **Accurate**: Reflect current reality
- **Complete**: Cover all critical context
- **Clear**: Understandable without prior knowledge
- **Updated**: Keep current as project evolves

This is not documentation for users—it's documentation **for future me**.

