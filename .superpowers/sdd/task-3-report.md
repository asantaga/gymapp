# Task 3 report — offline exercise photos

## Delivered

- Split the supplied 4×4 contact sheet into the first fourteen occupied cells, in row order. Each JPEG is 1200×1800 and stored in its matching `Assets.xcassets` image set.
- Added valid single-scale, universal image-set metadata and attached `Assets.xcassets` to the `GymWorkout` target resources.
- Set every seed exercise's `bundledPhotoName`; the visible exercise name remains `Wall Agents` while its asset is `wall-angels`.
- Added a seed factory test that asserts all fourteen bundled photo asset names in order.
- Removed the stale `AppIcon` build setting because there is no AppIcon set; that setting blocks asset compilation once the catalog is introduced.

## Verification

- Visually inspected a reassembled 14-cell crop sheet: all exercise cells are in the intended order with no black grid gutters or blank cells imported.
- Confirmed all fourteen source files are 1200×1800 JPEGs.
- Ran `xcodebuild build -quiet -scheme GymWorkout -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` successfully. The built `Assets.car` contains all fourteen asset names.
- Ran `git diff --check` successfully.

## Corrective follow-up — recropped exercise assets

- The supplied contact sheet uses uneven row boundaries (`398–404`, `765–771`, and `1138–1144`) rather than four fixed 384-pixel rows. The prior fixed-grid split could therefore include black divider pixels and adjacent-cell slivers.
- Rebuilt all fourteen named JPEGs from the supplied source with a consistent 240×360 inner crop for every detected cell, then resampled each to 1200×1800. The uniform inner crop stays inside every cell boundary and excludes the black rails.
- Visually inspected the complete reassembled 14-cell grid. It preserves the intended row-order exercise mapping with no contact-sheet gutters or neighbouring imagery; the installed asset files byte-match that inspected grid's inputs.

## Corrective verification

- Confirmed all fourteen installed JPEGs are 1200×1800.
- Ran `xcodebuild build -quiet -project GymWorkout.xcodeproj -scheme GymWorkout -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/GymWorkout-task3-recrop-deriveddata CODE_SIGNING_ALLOWED=NO` successfully.
- Ran `xcodebuild test -quiet -project GymWorkout.xcodeproj -scheme GymWorkout -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath /tmp/GymWorkout-task3-recrop-deriveddata CODE_SIGNING_ALLOWED=NO` successfully. The run emitted existing main-actor isolation warnings in `WorkoutSessionStoreTests.swift`.
