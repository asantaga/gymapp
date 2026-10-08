# Gym Workout

My personal gym app: step through a workout one exercise at a time, with a photo, sets, reps, weight and notes for each, and track which exercises are done.

It comes in two versions:

| Folder | What it is |
| --- | --- |
| `web/` | Progressive Web App (plain HTML/CSS/JS). Installs on an iPhone from Safari and works offline. See [`web/README.md`](web/README.md). |
| `GymWorkout/` | The original native SwiftUI iOS app (Xcode project `GymWorkout.xcodeproj`). |

## Using the web app

Live at **https://asantaga.github.io/gymapp/** once GitHub Pages is enabled (Settings → Pages → Source: GitHub Actions).

On an iPhone: open the link in Safari → Share → **Add to Home Screen**.

## Running locally

```sh
cd web && python3 -m http.server 8000      # open http://localhost:8000
node --test web/tests/store.test.mjs       # run the tests
```

Every push to `main` that changes `web/` runs the tests and redeploys the site.
