# Project Taxonomy — Kaia (SwiftUI + SwiftData)

## 1) Purpose & Version
Defines shared language for entities, screens/modules, state ownership, events, and naming. Used to keep Cursor prompts deterministic and implementations consistent.

**Version:** v0.1  
**Last Updated:** 2025-11-03

---

## 2) Domain Entities (authoritative)
| Entity | One‑line definition | Key fields | Relations |
|---|---|---|---|
| Person | A human in the story (baby, parent, family member) | id, role, name, birthDate, avatarAssetId | Person ↔ ShareCircle (many‑to‑many); Person ↔ Memory (author) |
| Memory | Atomic journal item (text/photo/video/audio) | id, createdAt, kind, text, mediaAssetIds, tags | Memory → MediaAsset (0..n); Memory ↔ Timeline |
| Milestone | Notable event (e.g., "first smile") | id, date, title, notes, mediaAssetIds | Milestone → MediaAsset (0..n); Milestone ↔ Timeline |
| MediaAsset | Photo/video/audio blob + metadata | id, type, url/localId, createdAt, exif, duration | Referenced by Memory/Milestone/Person |
| EntryPrompt | Bite‑sized prompt that yields a Memory | id, text, category, suggestedKind | EntryPrompt → Memory (0..n) |
| Timeline | Ordered feed of Memory + Milestone | id, ownerPersonId, itemIds, sort | Aggregates Memory/Milestone |
| ShareCircle | People authorized to view | id, name, memberPersonIds | ShareCircle ↔ Person |
| BookProject | Curated content for export | id, title, selectedItemIds, layoutStyle | References Memory/Milestone/MediaAsset |

Notes: keep entities stable; prefer additive changes. New fields are OK; rename only with a migration.

---

## 3) Screen & Module Map
| Module/Screen | Primary entity | State owner | Key actions |
|---|---|---|---|
| Onboarding | Person | OnboardingViewModel | createBaby, addParents, importMedia |
| Composer | Memory/MediaAsset | ComposerViewModel | attachMedia, recordAudio, saveDraft, publish |
| MilestonePicker | Milestone | MilestoneViewModel | addMilestone, attachMedia |
| TimelineView | Timeline | TimelineViewModel | paginate, filter, openDetail |
| DetailView | Memory/Milestone | DetailViewModel | edit, share, favorite, delete |
| People & Sharing | Person/ShareCircle | ShareViewModel | invite, revoke, setRole |
| Book Builder | BookProject | BookBuilderViewModel | curate, layoutPreview, export |
| Settings | Person | SettingsViewModel | backup, restore, featureFlags |

---

## 4) State Ownership (single source of truth)
- **TimelineState** → `TimelineViewModel`; reads paged Memory/Milestone; filters/sorts.
- **ComposerState** → `ComposerViewModel`; owns draft Memory + transient MediaAsset until publish.
- **MilestoneState** → `MilestoneViewModel`; maintains catalog + add‑flow.
- **ShareState** → `ShareViewModel`; keeps ShareCircle members + pending invites.
- **BookState** → `BookBuilderViewModel`; holds selection, layout options, export job.
- **Session** → `AppSession`; current baby/profile, auth, feature flags.

Rules: Views never mutate models directly; all mutations via their view model. Derived UI state (filters, selection) is local to the feature VM.

---

## 5) Data Model (SwiftData‑friendly v0)
| Type | Fields (primary → …) | Indexes/Uniqueness | Notes |
|---|---|---|---|
| Person | id(UUID), role(enum), name, birthDate?, avatarAssetId? | idx(role) | role ∈ {baby, parent, familyMember} |
| MediaAsset | id(UUID), type(enum), localUrl, createdAt, exif(json)?, duration? | idx(createdAt) | Store small thumbs; large blobs via URL |
| Memory | id(UUID), createdAt, kind(enum), text?, mediaAssetIds([UUID]), authorPersonId | idx(createdAt, kind) | kind ∈ {text, photo, video, audio, mixed} |
| Milestone | id(UUID), date, title, notes?, mediaAssetIds([UUID]) | idx(date) | title from controlled vocab + freeform |
| Timeline | id(UUID), ownerPersonId, itemRefs([ItemRef]) | idx(ownerPersonId) | ItemRef = {type, id} |
| EntryPrompt | id(UUID), text, category, suggestedKind | idx(category) | Small controlled set |
| BookProject | id(UUID), title, selectedItemRefs([ItemRef]), layoutStyle(enum) | idx(title) unique | Export job metadata separate |

Conventions: prefer immutable creation dates; keep computed/derived fields out of storage when possible.

---

## 6) Events & Triggers (reusable names)
- `memoryCaptured`, `memoryPublished`, `memoryEdited`, `memoryDeleted`
- `milestoneAdded`, `milestoneEdited`, `milestoneDeleted`
- `mediaImported`, `mediaFailed`, `thumbnailGenerated`
- `shareInvited`, `shareRevoked`, `shareAccepted`
- `bookExportRequested`, `bookExportCompleted`, `bookExportFailed`
- `syncStarted`, `syncCompleted`, `backupRestored`
- `onboardingFinished`

---

## 7) Naming & Conventions
- **Swift types**: `PascalCase` (e.g., `TimelineViewModel`), **vars**: `camelCase`, **files**: one type per file.
- **Folders** mirror Xcode groups. No orphan groups.
- **UI**: Titles are sentence case; accessibility identifiers = `feature.element.action` (e.g., `timeline.item.open`).
- **Design tokens**: `ColorTokens.primary`, `Spacing.m`
- **Good**: `TimelineGridView`, `ComposerViewModel`, `BookBuilderViewModel`
- **Bad**: `TLView2`, `VmCapture`, `Kaia_BookV1`

---

## 8) Sample Fixtures (for previews)
```swift
let sampleBaby = Person(id: UUID(), role: .baby, name: "Kaia", birthDate: ISODate("2025-10-17"), avatarAssetId: nil)
let samplePhoto = MediaAsset(id: UUID(), type: .photo, localUrl: "asset://sample/kaia1.jpg", createdAt: now())
let sampleMemory1 = Memory(id: UUID(), createdAt: now(-2.days), kind: .photo, text: "First bath", mediaAssetIds: [samplePhoto.id], authorPersonId: sampleBaby.id)
let sampleMilestone = Milestone(id: UUID(), date: today(-5.days), title: "First smile", notes: "Morning after nap", mediaAssetIds: [])
let sampleTimeline = Timeline(id: UUID(), ownerPersonId: sampleBaby.id, itemRefs: [.memory(sampleMemory1.id), .milestone(sampleMilestone.id)])
```
Guideline: every preview compiles with fixtures only; no network/storage.

---

## 9) Non‑Goals (v0)
- Multi‑family accounts and cross‑household sharing controls
- Collaborative editing / realtime cursors
- AI summarization of timelines
- Advanced book layout templating or print vendor integration
- Offline conflict resolution beyond last‑write‑wins

---

## 10) Open Questions (for v0.2)
1. Minimal backup/restore: iCloud container vs. local export?
2. Dedupe strategy for burst photos and live photos?
3. Best UX for mixing Memory + Milestone in one capture flow?
4. Share model: link‑based viewing vs. member‑only?
5. Media storage policy (full‑res vs. optimized cache)?
6. Tagging model: free tags vs. controlled vocab?
7. Local‑only mode toggle—needed?
8. Accessibility baseline (Dynamic Type, VoiceOver priorities)?

---

## 11) Change Log
- **v0.1** — Initial taxonomy (entities, screens, state, data model, events, fixtures)

