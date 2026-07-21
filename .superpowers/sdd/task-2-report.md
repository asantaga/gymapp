# Task 2 Report: Seed Workout A Once

## Outcome

Added `SeedWorkoutFactory.seedIfNeeded(in:)` to create the exact 14-row Workout A routine only when the persistent store has no `Exercise` records. The existing root placeholder checks for an empty query before it invokes the factory; the factory repeats the count guard as the persistence-level protection against duplicate imports or overwriting user edits.

## TDD evidence

### RED

Command:

```bash
xcodebuild test -scheme GymWorkout -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GymWorkoutTests/SeedWorkoutFactoryTests
```

Result: exit 65 / `** TEST FAILED **` before the factory was implemented, with the expected compiler diagnostic:

```text
SeedWorkoutFactoryTests.swift:21:13: error: cannot find 'SeedWorkoutFactory' in scope
```

The first sandboxed attempt could not connect to CoreSimulatorService; the same prescribed command was then rerun with access to the local simulator service and reached the expected missing-symbol failure.

### GREEN

Command:

```bash
xcodebuild test -quiet -scheme GymWorkout -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:GymWorkoutTests/SeedWorkoutFactoryTests
```

Result: exit 0. Xcode completed the focused XCTest operation successfully after the factory was added.

## Full suite verification

Command:

```bash
xcodebuild test -quiet -scheme GymWorkout -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Result: exit 0; all five XCTest cases passed:

- `SeedWorkoutFactoryTests`: 3 passed.
- `ExerciseModelTests`: 2 passed.

## Changed files

- `GymWorkout/Data/SeedWorkoutFactory.swift`
- `GymWorkoutTests/SeedWorkoutFactoryTests.swift`
- `GymWorkout/GymWorkoutApp.swift`
- `GymWorkout.xcodeproj/project.pbxproj`

## Self-review

- The seeded array preserves all 14 spreadsheet positions, exact exercise names, sets, reps, weights, and notes. Cross trainer uses `N/A`; the three bodyweight warm-up rows use empty weight text.
- The tests validate order/count, every prescription and note, and that a saved user edit remains unchanged after a second seed call.
- The factory fetch-count guard happens before any insertion and saves only after the complete initial routine is inserted.
- No network, account, photo, session-player, or later-task behavior was added.
- `git diff --check` completed without whitespace errors.

## Concerns

- Xcode 26.6 emits the pre-existing `IDERunDestination: Supported platforms for the buildables in the current scheme is empty` diagnostic even while it resolves the iPhone 17 Pro simulator and completes the tests successfully.
