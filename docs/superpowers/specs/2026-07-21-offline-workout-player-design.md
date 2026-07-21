# Offline Workout Player — Design

## Goal

Create a simple native iPhone app that guides Angelo through the **Workout A (Strength)** routine from `Angelo GYM.xlsx`. It presents one exercise at a time and works fully offline at the gym.

## Scope

- iPhone app built with SwiftUI and installed initially through Xcode/TestFlight.
- One editable workout: **Workout A**, initially seeded with the 14 exercises in spreadsheet order.
- A focused, one-exercise workout-player screen.
- A locally bundled exercise photo for every seeded exercise, plus a user-selected photo from the iPhone photo library for added or edited exercises.
- Local, on-device workout progress only. No account, backend, internet connection, or health-data integration.

## User flow

1. The home screen shows Workout A, **Start new workout**, and **Edit workout** actions.
2. Starting a workout clears prior completion state and opens the first exercise.
3. The player displays a progress indicator, exercise photo, exercise name, sets, reps, weight in kg, notes, **Mark complete**, and Previous/Next controls.
4. Marking an exercise complete is reversible and updates both its control and overall progress.
5. Previous/Next lets the user move freely through the routine without changing completion automatically.
6. On the final completed exercise, the app presents a concise completion summary and returns to the home screen. A finished session remains visible until the user taps **Start new workout**.
7. **Edit workout** opens an ordered list of exercises. The user can add, edit, reorder, or delete exercises, adjust their prescription and notes, and choose a replacement photo from the iPhone photo library.

## Workout data

The app ships with the following routine, transcribed from the spreadsheet tab `Workout A (Strength)`:

| # | Exercise | Sets | Reps | Weight (kg) | Notes |
|---:|---|---:|---:|---:|---|
| 1 | Cross trainer | N/A | N/A | N/A | 10 mins |
| 2 | Wall Agents | 2 | 12 | — | — |
| 3 | Shoulder dislocates (with band or bar) | 2 | 12 | — | — |
| 4 | Body weight squats | 2 | 12 | — | — |
| 5 | Leg Extension | 4 | 6 | 66 | Machine; backrest 3 |
| 6 | Leg Press | 3 | 10 | 86 | Machine; seat 3 |
| 7 | Seated Leg Curl | 2 | 10 | 45 | Machine; backrest 3, 1, 2 |
| 8 | Calf press | 3 | 6 | 79 | Either standing, seated, or machine |
| 9 | Assisted chin-up | 3 | 8 | -23 | Machine |
| 10 | Cable row | 3 | 8 | 52 | Machine |
| 11 | Overhead Press | 2 | 10 | 25 | Small barbells |
| 12 | Diverging lat pulldown | 2 | 12 | 45 | Machine |
| 13 | Cable tricep pulldowns | 1 | 12 | 32 | Machine |
| 14 | Dumbbell curls | 2 | 6 | 12 | Free dumbbells |

## Interface

The approved player layout uses a calm green palette and large, gym-readable type. It has:

- Workout name and `current of total` status in the top bar.
- A slim progress bar.
- A large photo card above the exercise details.
- Three compact prescription values for sets, reps, and weight.
- A prominent completion control, followed by equal-size Previous and Next buttons.

The app uses system controls and supports Dynamic Type, VoiceOver labels, and sufficient contrast. The active completion state is visually clear without relying on color alone.

The Edit Workout screen is a standard editable list: an Add Exercise action, Edit controls for every row, drag handles for reordering, and a delete control. The exercise editor has fields for name, sets, reps, weight, notes, and a photo-library picker. If a chosen photo is unavailable, the editor presents a visible fallback image instead of losing the exercise data.

## Architecture and data

- `Exercise`: mutable local data containing its name, prescription, notes, and either a bundled-image name or saved user-photo file reference.
- `Workout`: ordered collection of exercises stored on the device.
- `WorkoutSession`: current index and set of completed exercise identifiers, persisted with `UserDefaults`.
- SwiftUI views: `HomeView`, `WorkoutPlayerView`, `ExerciseDetailCard`, `CompletionSummaryView`.
- A small view model owns session transitions, including reset, previous/next navigation, and completion calculations.

On the first launch, the app copies the spreadsheet routine into local storage. It never overwrites later user edits. Bundled seeded-photo assets live in the app bundle; selected photo-library images are copied into the app's private storage so they still work offline. If an image cannot be loaded, the app shows a clear fallback state rather than crashing; release verification requires all 14 seeded images to be present.

## Testing

- Unit tests for session reset, navigation boundaries, completion toggling, and progress calculation.
- Verify the source routine has 14 ordered exercises and no missing prescriptions.
- Simulator test: start a workout, navigate, complete/reopen exercises, finish, close/reopen the app, and start a fresh workout.
- Simulator test: edit a seeded exercise, add, reorder, and delete exercises, and verify those changes persist after relaunch. Test the photo-library selection flow on a physical iPhone.
- Accessibility check for VoiceOver labels and large text.

## Out of scope for version one

- Rest timers, per-set tracking, workout history, multiple workout plans, accounts, syncing, Apple Health, and online image loading.
