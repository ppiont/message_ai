# Task Cleanup Recommendations

**Date**: 2025-10-22
**Reason**: PRD updated to focus on rubric-critical features

---

## TASKS TO CANCEL (Superseded by New Tasks)

### Old AI Feature Tasks (Superseded)
These are superseded by the new rubric-focused tasks (124-148):

**Cancel These**:
- ❌ Task 59: Set up Firebase Cloud Functions → **Superseded by Task 124** (includes setup)
- ❌ Task 60: Thread summarization Cloud Function → **Not in rubric** (out of scope)
- ❌ Task 61: Action item extraction Cloud Function → **Not in rubric** (out of scope)
- ❌ Task 62: Smart search Cloud Function → **Replaced by Task 136** (RAG pipeline)
- ❌ Task 63: Priority detection Cloud Function → **Not in rubric** (out of scope)
- ❌ Task 64: Decision tracking Cloud Function → **Not in rubric** (out of scope)
- ❌ Task 65: Smart replies Cloud Function → **Replaced by Tasks 132, 147** (advanced feature)
- ❌ Task 66: Message indexing Cloud Function → **Replaced by Task 136** (RAG pipeline)
- ❌ Task 67: Create AI feature entities and models → **Replaced by Task 126** (message entity update)
- ❌ Task 68: AI feature remote data source → **Replaced by Tasks 143-147** (services)
- ❌ Task 69: AI feature repository → **Replaced by Tasks 143-147** (services)
- ❌ Task 70: AI feature use cases → **Replaced by Tasks 143-147** (services)
- ❌ Task 71: AI feature providers → **Replaced by Tasks 143-147** (services)
- ❌ Task 72: Smart reply chips widget → **Replaced by Task 132.5** (SmartReplyBar)
- ❌ Task 73: Thread summary card widget → **Not in rubric** (out of scope)
- ❌ Task 74: Action items widget → **Not in rubric** (out of scope)
- ❌ Task 75: Decisions widget → **Not in rubric** (out of scope)
- ❌ Task 76: Smart search in chat UI → **Replaced by Task 136** (RAG pipeline)
- ❌ Task 77: Language detection with ML Kit → **Replaced by Task 125** (detailed version)
- ❌ Task 78: Translation service → **Replaced by Task 143** (Translation UI Controller)
- ❌ Task 79: Translation entities and models → **Replaced by Task 126** (message entity)
- ❌ Task 80: Translation remote data source → **Replaced by Task 124** (Cloud Functions)
- ❌ Task 81: Translation repository → **Replaced by Task 143** (service)
- ❌ Task 82: Translation use cases → **Replaced by Tasks 127-128**
- ❌ Task 83: Translation providers → **Replaced by Task 143** (controller)
- ❌ Task 84: Translation toggle in chat UI → **Replaced by Task 127** (inline UI)
- ❌ Task 85: Language settings UI → **Nice to have** (not critical)
- ❌ Task 86: Formality detection Cloud Function → **Replaced by Task 130** (formality feature)

### Low-Priority Old Tasks (Consider Cancelling)
These aren't critical for rubric scoring:

**Consider Cancelling**:
- ⚠️ Task 14: Utility functions → **Low impact** (can implement as needed)
- ⚠️ Task 45: WorkManager → **Not needed** (sync service handles background)
- ⚠️ Task 47: Image compression → **Nice to have** (not critical)
- ⚠️ Task 48: cached_network_image → **Covered in Task 134** (performance)
- ⚠️ Task 87: Internationalization → **Low priority** (focus on AI)
- ⚠️ Task 88: App theme → **Nice to have** (default theme is fine)
- ⚠️ Task 89: App routing → **Already working** (routes exist)
- ⚠️ Task 90: Crashlytics → **Nice to have** (not critical)
- ⚠️ Task 94: CI/CD GitHub Actions → **Nice to have** (not graded)
- ⚠️ Task 95: Fastlane iOS → **Nice to have** (manual deploy OK)
- ⚠️ Task 96: Fastlane Android → **Nice to have** (manual deploy OK)
- ⚠️ Task 97: Firestore pagination → **Already works** (limit queries exist)
- ⚠️ Task 98: Firestore offline persistence → **Already enabled** (working)
- ⚠️ Task 99: Denormalization → **Already done** (lastMessage exists)
- ⚠️ Task 100: Optimize listeners → **Covered in Task 134** (performance)
- ⚠️ Task 101: OpenAI caching → **Covered in Task 124** (caching built-in)
- ⚠️ Task 102: Batch API OpenAI → **Not needed** (real-time is fine)
- ⚠️ Task 103: Token limiting OpenAI → **Low priority** (costs are low)
- ⚠️ Task 104: PII detection → **Covered in Task 137.4** (security)
- ⚠️ Task 105: Rate limiting Cloud Functions → **Covered in Task 137.2** (security)
- ⚠️ Task 106: Secret Manager → **Covered in Task 124.2** (translation setup)
- ⚠️ Task 107: Vector search indexing → **Covered in Task 136** (RAG pipeline)
- ⚠️ Task 108: Translation memory → **Nice to have** (caching is enough)
- ⚠️ Task 109: Batch translation → **Covered in Task 128** (auto-translate)
- ⚠️ Task 110: Translation optimization → **Covered in Task 124** (caching)
- ⚠️ Task 111: Performance monitoring → **Nice to have** (DevTools is enough)
- ⚠️ Task 112: Error boundary widget → **Nice to have** (not critical)
- ⚠️ Task 113: Animations → **Nice to have** (not graded heavily)
- ⚠️ Task 114: Deep linking → **Already works** (notification tap works)
- ⚠️ Task 115: Analytics → **Nice to have** (not graded)
- ⚠️ Task 116: A/B testing → **Not needed** (out of scope)
- ⚠️ Task 117: App review prompts → **Not needed** (out of scope)
- ⚠️ Task 118: Security audit → **Replaced by Task 137** (security hardening)
- ⚠️ Task 119: Load testing → **Not critical** (performance testing is enough)
- ⚠️ Task 120: App store submission → **Not graded** (demo video is enough)

---

## TASKS TO KEEP (Still Relevant)

### Critical for Rubric
- ✅ Task 91: Firebase App Check → **Covered in Task 137.3** (keep for reference)
- ✅ Task 92: Firestore security rules → **Covered in Task 137.1** (keep for reference)
- ✅ Task 93: Storage security rules → **Covered in Task 137.1** (keep for reference)

### New Priority Tasks (124-148)
All new tasks generated from the final PRD should be kept as they're aligned with rubric requirements.

---

## RECOMMENDED ACTIONS

### Bulk Cancel Superseded Tasks
```bash
task-master set-status --id=59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86 --status=cancelled
```

### Bulk Cancel Low-Priority Tasks
```bash
task-master set-status --id=14,45,47,48,87,88,89,90,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120 --status=cancelled
```

### Or Review Individually
```bash
# View specific task to decide
task-master show 59
task-master show 60
# ... etc

# Cancel individually
task-master set-status --id=59 --status=cancelled
```

---

## RATIONALE

### Why Cancel Old Tasks?
1. **Focus**: New tasks (124-148) are more detailed and rubric-aligned
2. **Clarity**: Reduces noise in task list (from 148 → ~90 tasks)
3. **Efficiency**: Easier to find next critical task
4. **Accuracy**: Old tasks don't reflect updated PRD requirements

### Why Keep Some Tasks?
- Still relevant for production quality
- Not superseded by new tasks
- Provide useful reference
- Low overhead to keep

---

## AFTER CLEANUP

### Expected Task Count
- **Before**: 148 tasks (91 pending)
- **After**: ~90 tasks (~30 pending)
- **Focus**: 25 critical AI + polish tasks

### Cleaner View
```bash
# See only critical tasks
task-master list --status=pending

# Should show mostly tasks 124-148 (AI features, polish, deliverables)
```

---

**Recommendation**: Cancel all superseded tasks to focus on rubric-critical work.

**Command**:
```bash
task-master set-status --id=59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,14,45,47,48,87,88,89,90,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120 --status=cancelled
```

Then focus on: **Tasks 124-148** (AI features + polish + deliverables)
