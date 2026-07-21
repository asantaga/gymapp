# Offline Workout Player Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native offline iPhone workout player seeded from Angelo’s Workout A spreadsheet, with editable exercises and offline photos.

**Architecture:** A SwiftUI app stores the editable workout and active session in SwiftData. A `SeedWorkoutFactory` imports the fixed initial 14-exercise routine exactly once; the player uses an observable session store for navigation and completion state. Seeded exercise photos live in the asset catalog, while images chosen through `PhotosPicker` are copied into Application Support and referenced by filename.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, PhotosUI, XCTest, iOS 18+, Xcode 26.6.

## Global Constraints

- Target iPhone only, installed initially through Xcode/TestFlight.
- The app must work without any network request or account.
- Start from the 14 Workout A exercises, in their spreadsheet order, with sets, reps, kg, and notes preserved.
- Bundle a photo for every seeded exercise; copy user-selected library photos into private on-device storage.
- Completion stays visible until the user taps Start New Workout; that action resets the session.
- Support Dynamic Type, VoiceOver labels, adequate contrast, and a non-colour-only completion state.
- Do not add rest timers, per-set tracking, workout history, additional workout plans, syncing, or Apple Health.

---

## File structure

```text
GymWorkout/
  GymWorkoutApp.swift                 App launch and SwiftData container
  Models/Exercise.swift               Persistent editable exercise model
  Models/WorkoutSession.swift         Persistent active-session model
  Data/SeedWorkoutFactory.swift       First-launch Workout A seed data
  Services/ExercisePhotoStore.swift   Save/load/delete library image files
  ViewModels/WorkoutSessionStore.swift Player navigation and completion rules
  Views/HomeView.swift                Start, resume, and edit entry point
  Views/WorkoutPlayerView.swift       Single-exercise player screen
  Views/ExerciseDetailCard.swift      Photo, prescription, and note display
  Views/CompletionSummaryView.swift   Finished-workout presentation
  Views/EditWorkoutView.swift         Ordered editable exercise list
  Views/ExerciseEditorView.swift      Add/edit form and PhotosPicker
  Assets.xcassets/                    Fourteen seeded exercise photo assets
GymWorkoutTests/
  SeedWorkoutFactoryTests.swift
  WorkoutSessionStoreTests.swift
  ExercisePhotoStoreTests.swift
```

### Task 1: Create the SwiftUI project and persistent models

**Files:**
- Create: `GymWorkout/GymWorkoutApp.swift`
- Create: `GymWorkout/Models/Exercise.swift`
- Create: `GymWorkout/Models/WorkoutSession.swift`
- Create: `GymWorkoutTests/ExerciseModelTests.swift`

**Interfaces:**
- Produces `Exercise`, with `id: UUID`, `position: Int`, `name: String`, `setsText: String`, `repsText: String`, `weightText: String`, `notes: String`, `bundledPhotoName: String?`, and `userPhotoFilename: String?`.
- Produces `WorkoutSession`, with `id: UUID`, `currentExerciseID: UUID?`, `completedExerciseIDs: [UUID]`, and `isFinished: Bool`.

- [ ] **Step 1: Create an iOS App project named `GymWorkout`**

In Xcode, choose **File → New → Project → iOS App** and set:

```text
Product Name: GymWorkout
Interface: SwiftUI
Storage: SwiftData
Tests: XCTest
Deployment Target: iOS 18.0
```

- [ ] **Step 2: Write the model persistence test**

```swift
func testExerciseStoresEditablePrescription() throws {
    let exercise = Exercise(
        position: 1, name: "Cable row", setsText: "3", repsText: "8",
        weightText: "52", notes: "Machine", bundledPhotoName: "cable-row"
    )

    XCTAssertEqual(exercise.name, "Cable row")
    XCTAssertEqual(exercise.weightText, "52")
    XCTAssertEqual(exercise.bundledPhotoName, "cable-row")
    XCTAssertNil(exercise.userPhotoFilename)
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `xcodebuild test -scheme GymWorkout -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GymWorkoutTests/ExerciseModelTests`

Expected: FAIL because `Exercise` does not exist.

- [ ] **Step 4: Implement the two SwiftData models and app container**

```swift
@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var position: Int
    var name: String
    var setsText: String
    var repsText: String
    var weightText: String
    var notes: String
    var bundledPhotoName: String?
    var userPhotoFilename: String?

    init(position: Int, name: String, setsText: String, repsText: String,
         weightText: String, notes: String, bundledPhotoName: String? = nil,
         userPhotoFilename: String? = nil) {
        self.id = UUID()
        self.position = position
        self.name = name
        self.setsText = setsText
        self.repsText = repsText
        self.weightText = weightText
        self.notes = notes
        self.bundledPhotoName = bundledPhotoName
        self.userPhotoFilename = userPhotoFilename
    }
}
```

Declare `WorkoutSession` as a second `@Model`, and configure `ModelContainer(for: Exercise.self, WorkoutSession.self)` in `GymWorkoutApp`.

- [ ] **Step 5: Run the model test to verify it passes**

Run: `xcodebuild test -scheme GymWorkout -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GymWorkoutTests/ExerciseModelTests`

Expected: PASS.

- [ ] **Step 6: Commit the project foundation**

```bash
git add GymWorkout GymWorkoutTests GymWorkout.xcodeproj
git commit -m "feat: create workout app data models"
```

### Task 2: Seed the exact spreadsheet routine once

**Files:**
- Create: `GymWorkout/Data/SeedWorkoutFactory.swift`
- Create: `GymWorkoutTests/SeedWorkoutFactoryTests.swift`

**Interfaces:**
- Consumes: `[Exercise]` and `ModelContext`.
- Produces: `SeedWorkoutFactory.seedIfNeeded(in: ModelContext) throws`.

- [ ] **Step 1: Write the seeding tests**

```swift
func testSeedCreatesFourteenOrderedExercises() throws {
    try SeedWorkoutFactory.seedIfNeeded(in: context)
    let exercises = try context.fetch(FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.position)]))

    XCTAssertEqual(exercises.count, 14)
    XCTAssertEqual(exercises.first?.name, "Cross trainer")
    XCTAssertEqual(exercises[4].name, "Leg Extension")
    XCTAssertEqual(exercises.last?.name, "Dumbbell curls")
}

func testSeedDoesNotOverwriteEditedWorkout() throws {
    try SeedWorkoutFactory.seedIfNeeded(in: context)
    let exercise = try XCTUnwrap(context.fetch(FetchDescriptor<Exercise>()).first)
    exercise.name = "Custom warm-up"
    try context.save()

    try SeedWorkoutFactory.seedIfNeeded(in: context)
    XCTAssertEqual(try context.fetch(FetchDescriptor<Exercise>()).first?.name, "Custom warm-up")
}
```

- [ ] **Step 2: Run the seed tests to verify they fail**

Run: `xcodebuild test -scheme GymWorkout -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GymWorkoutTests/SeedWorkoutFactoryTests`

Expected: FAIL because `SeedWorkoutFactory` does not exist.

- [ ] **Step 3: Implement the fixed Workout A seed data**

Create one `Exercise` per row with positions 1 through 14. Use these exact strings for the non-empty weight values: `66`, `86`, `45`, `79`, `-23`, `52`, `25`, `45`, `32`, and `12`. Use `N/A` for Cross trainer sets, reps, and weight; use empty strings for absent values on the other bodyweight exercises. Call `seedIfNeeded` from the root view only when no `Exercise` objects exist.

- [ ] **Step 4: Run the seed tests to verify they pass**

Run: `xcodebuild test -scheme GymWorkout -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GymWorkoutTests/SeedWorkoutFactoryTests`

Expected: PASS.

- [ ] **Step 5: Commit the seed routine**

```bash
git add GymWorkout/Data/SeedWorkoutFactory.swift GymWorkoutTests/SeedWorkoutFactoryTests.swift
git commit -m "feat: seed workout A from spreadsheet"
```

### Task 3: Provide and wire the fourteen offline exercise photos

**Files:**
- Create: `GymWorkout/Assets.xcassets/{cross-trainer,wall-angels,shoulder-dislocates,bodyweight-squats,leg-extension,leg-press,seated-leg-curl,calf-press,assisted-chin-up,cable-row,overhead-press,diverging-lat-pulldown,cable-tricep-pulldowns,dumbbell-curls}.imageset/`
- Modify: `GymWorkout/Data/SeedWorkoutFactory.swift`

**Interfaces:**
- Consumes: each exercise’s `bundledPhotoName`.
- Produces: a valid `Image(exercise.bundledPhotoName)` for every seed exercise.

- [ ] **Step 1: Generate or source fourteen legally usable, vertical exercise photographs**

Create one 3:2 vertical photo per named asset. Each photo must clearly show the movement or relevant machine, avoid readable brand logos, and have an uncluttered gym background. Export each image as an optimised HEIC or JPEG at 1200×1800 pixels.

- [ ] **Step 2: Import the assets with the exact catalog names**

In Xcode, drag each photo into the correspondingly named `.imageset`; set **Appearances** to Any, Any, **Scales** to Single Scale, and ensure target membership includes GymWorkout.

- [ ] **Step 3: Set the correct `bundledPhotoName` for every seeded exercise**

Map the fourteen seed exercises to the fourteen asset names in the order stated in the Files section. Do not use an online URL or `AsyncImage`.

- [ ] **Step 4: Build and verify all images resolve**

Run: `xcodebuild build -scheme GymWorkout -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`

Expected: `** BUILD SUCCEEDED **`. Launch the app and inspect all 14 exercises; none may show the fallback image.

- [ ] **Step 5: Commit the offline photo assets**

```bash
git add GymWorkout/Assets.xcassets GymWorkout/Data/SeedWorkoutFactory.swift
git commit -m "feat: bundle workout exercise photos"
```

### Task 4: Build and test session state rules

**Files:**
- Create: `GymWorkout/ViewModels/WorkoutSessionStore.swift`
- Create: `GymWorkoutTests/WorkoutSessionStoreTests.swift`

**Interfaces:**
- Consumes: ordered `[Exercise]` and one `WorkoutSession`.
- Produces: `currentExercise`, `currentPosition`, `completedCount`, `toggleCompletion(for:)`, `goNext()`, `goPrevious()`, `startNewWorkout()`, and `finishIfComplete()`.

- [ ] **Step 1: Write focused session tests**

```swift
func testCompletingExerciseUpdatesProgress() {
    store.toggleCompletion(for: exercises[0])
    XCTAssertEqual(store.completedCount, 1)
    XCTAssertTrue(store.isCompleted(exercises[0]))
}

func testNextDoesNotMarkExerciseComplete() {
    store.goNext()
    XCTAssertEqual(store.currentExercise?.id, exercises[1].id)
    XCTAssertEqual(store.completedCount, 0)
}

func testStartNewWorkoutClearsCompletionAndReturnsToFirstExercise() {
    store.toggleCompletion(for: exercises[0])
    store.goNext()
    store.startNewWorkout()

    XCTAssertEqual(store.completedCount, 0)
    XCTAssertEqual(store.currentExercise?.id, exercises[0].id)
}
```

- [ ] **Step 2: Run the session tests to verify they fail**

Run: `xcodebuild test -scheme GymWorkout -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GymWorkoutTests/WorkoutSessionStoreTests`

Expected: FAIL because `WorkoutSessionStore` does not exist.

- [ ] **Step 3: Implement session persistence and navigation boundaries**

Use the exercise `id` values in `completedExerciseIDs`. Clamp navigation at the first and last indices. Persist each mutation with `modelContext.save()`. Set `isFinished` only when all current exercises are complete; an incomplete final exercise may still be viewed without showing the completion summary.

- [ ] **Step 4: Run the session tests to verify they pass**

Run: `xcodebuild test -scheme GymWorkout -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GymWorkoutTests/WorkoutSessionStoreTests`

Expected: PASS.

- [ ] **Step 5: Commit session state**

```bash
git add GymWorkout/ViewModels/WorkoutSessionStore.swift GymWorkoutTests/WorkoutSessionStoreTests.swift
git commit -m "feat: persist workout progress"
```

### Task 5: Implement the accessible workout player and completion summary

**Files:**
- Create: `GymWorkout/Views/HomeView.swift`
- Create: `GymWorkout/Views/WorkoutPlayerView.swift`
- Create: `GymWorkout/Views/ExerciseDetailCard.swift`
- Create: `GymWorkout/Views/CompletionSummaryView.swift`
- Create: `GymWorkout/Views/WorkoutPlayerCopy.swift`
- Create: `GymWorkoutTests/WorkoutPlayerViewTests.swift`
- Modify: `GymWorkout/GymWorkoutApp.swift`

**Interfaces:**
- Consumes: `WorkoutSessionStore` and a sorted `[Exercise]` query.
- Produces: a home entry point, player, and summary sheet.

- [ ] **Step 1: Write the UI behaviour tests**

```swift
func testCompleteButtonUsesNonColourCompletionCopy() {
    XCTAssertEqual(WorkoutPlayerCopy.completeButton(isComplete: false), "Mark complete")
    XCTAssertEqual(WorkoutPlayerCopy.completeButton(isComplete: true), "Completed")
}

func testProgressCopyIncludesCurrentPositionAndTotal() {
    XCTAssertEqual(WorkoutPlayerCopy.progress(position: 3, total: 14), "Exercise 3 of 14")
}
```

- [ ] **Step 2: Run the UI behaviour tests to verify they fail**

Run: `xcodebuild test -scheme GymWorkout -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GymWorkoutTests/WorkoutPlayerViewTests`

Expected: FAIL because the player components do not exist.

- [ ] **Step 3: Implement the home screen and player UI**

Create `WorkoutPlayerCopy` with `static func completeButton(isComplete: Bool) -> String` and `static func progress(position: Int, total: Int) -> String`. Use a dark green navigation area, a slim linear progress bar, a large 3:2 photo region, three value tiles for sets/reps/kg, notes, a full-width completion button, and equal-width Previous/Next buttons. Disable Previous at the first item and Next at the last. Add `accessibilityLabel` and `accessibilityHint` values for photo, progress, completion, and navigation controls. Use `.dynamicTypeSize(...DynamicTypeSize.accessibility3)` without clipping text.

- [ ] **Step 4: Implement completion summary behaviour**

Present `CompletionSummaryView` when `isFinished` becomes true. Show `14 of 14 exercises completed`, a Done action that returns home without resetting, and a Start New Workout action that invokes `startNewWorkout()`.

- [ ] **Step 5: Run tests and exercise the flow in Simulator**

Run: `xcodebuild test -scheme GymWorkout -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`

Expected: PASS. Then run the GymWorkout scheme in Simulator and verify start, previous/next, complete/uncomplete, summary, relaunch persistence, and reset.

- [ ] **Step 6: Commit the player experience**

```bash
git add GymWorkout/GymWorkoutApp.swift GymWorkout/Views GymWorkoutTests/WorkoutPlayerViewTests.swift
git commit -m "feat: add offline workout player"
```

### Task 6: Build offline editing and photo-library selection

**Files:**
- Create: `GymWorkout/Services/ExercisePhotoStore.swift`
- Create: `GymWorkout/Views/EditWorkoutView.swift`
- Create: `GymWorkout/Views/ExerciseEditorView.swift`
- Create: `GymWorkoutTests/ExercisePhotoStoreTests.swift`
- Modify: `GymWorkout/Views/HomeView.swift`

**Interfaces:**
- Consumes: `PhotosPickerItem`, `Exercise`, `ModelContext`.
- Produces: `ExercisePhotoStore.save(data: Data, for: UUID) throws -> String`, `imageData(named: String) -> Data?`, and `delete(named: String) throws`.

- [ ] **Step 1: Write photo-store and edit-persistence tests**

```swift
func testPhotoStoreRoundTripsImageData() throws {
    let filename = try store.save(data: Data([0xFF, 0xD8, 0xFF]), for: UUID())
    XCTAssertEqual(store.imageData(named: filename), Data([0xFF, 0xD8, 0xFF]))
}

func testEditingExercisePersistsUpdatedNameAndPosition() throws {
    exercise.name = "Incline press"
    exercise.position = 1
    try context.save()
    XCTAssertEqual(try fetchExercise(exercise.id).name, "Incline press")
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `xcodebuild test -scheme GymWorkout -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GymWorkoutTests/ExercisePhotoStoreTests`

Expected: FAIL because `ExercisePhotoStore` does not exist.

- [ ] **Step 3: Implement image storage**

Save each selected image under `Application Support/ExercisePhotos/<UUID>.jpg`, creating `ExercisePhotos` with `.withIntermediateDirectories`. On replacement, save the new file, update `userPhotoFilename`, then delete the previous user-photo file. Do not delete a bundled photo asset. Return `nil` from `imageData` for a missing file so the UI shows its fallback symbol.

- [ ] **Step 4: Implement the editor and ordered list**

Use `List` with `.onMove` and `.onDelete`; after either operation, rewrite every exercise’s `position` to match the new order and save. The form requires a non-empty trimmed name, has text fields for sets, reps, weight, and notes, and uses `PhotosPicker(selection:matching: .images)` to load and save selected data through `ExercisePhotoStore`. Expose **Edit Workout** from HomeView.

- [ ] **Step 5: Run tests and verify on device**

Run: `xcodebuild test -scheme GymWorkout -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`

Expected: PASS. On a physical iPhone, add a custom exercise, select a library photo, relaunch, confirm the photo remains visible offline, then reorder and delete the custom exercise.

- [ ] **Step 6: Commit the editing flow**

```bash
git add GymWorkout/Services GymWorkout/Views/EditWorkoutView.swift GymWorkout/Views/ExerciseEditorView.swift GymWorkout/Views/HomeView.swift GymWorkoutTests/ExercisePhotoStoreTests.swift
git commit -m "feat: edit workouts and import offline photos"
```

### Task 7: Final quality pass and TestFlight archive

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: the completed GymWorkout app.
- Produces: a tested Xcode archive ready for TestFlight upload.

- [ ] **Step 1: Run the full test suite and production build**

Run:

```bash
xcodebuild test -scheme GymWorkout -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
xcodebuild build -scheme GymWorkout -configuration Release -destination 'generic/platform=iOS'
```

Expected: both commands succeed with no test failures.

- [ ] **Step 2: Complete the manual accessibility and offline checklist**

Verify every seeded photo appears, VoiceOver reads the exercise name and completion state, Dynamic Type does not clip controls, completed state contains text/icon as well as green colour, all 14 entries are in order, photo-library images remain after relaunch, and the app remains functional with Airplane Mode enabled.

- [ ] **Step 3: Add local installation instructions**

Add a README section explaining: choose a development team in **Signing & Capabilities**, select an attached iPhone, run the app from Xcode once, archive with **Product → Archive**, then use the Organizer to distribute through TestFlight.

- [ ] **Step 4: Archive for TestFlight**

In Xcode, choose **Any iOS Device (arm64)**, select **Product → Archive**, validate the archive in Organizer, and upload it to App Store Connect. The user must select their own Apple Developer team; no credentials are stored in the repository.

- [ ] **Step 5: Commit final documentation**

```bash
git add README.md
git commit -m "docs: add iPhone and TestFlight setup"
```

## Self-review

- Spreadsheet seed data, player navigation, progress persistence, local photo assets, photo-library imports, editing, accessibility, testing, and TestFlight delivery are each covered by Tasks 1–7.
- The plan has no incomplete work markers or unspecified interfaces.
- `Exercise`, `WorkoutSession`, `SeedWorkoutFactory`, `WorkoutSessionStore`, and `ExercisePhotoStore` names and their data flow remain consistent throughout the plan.
