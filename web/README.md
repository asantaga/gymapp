# Gym Workout — PWA

A port of the SwiftUI app in `GymWorkout/` to a Progressive Web App you can install on an iPhone
from Safari. It is plain HTML/CSS/JS with no build step, and it works fully offline once loaded.

| Swift                                   | PWA                                  |
| --------------------------------------- | ------------------------------------ |
| SwiftData models + `WorkoutSessionStore` | `store.js` (JSON in `localStorage`)  |
| `SeedWorkoutFactory`                    | `seed.js`                            |
| `ExercisePhotoStore`                    | `db.js` (photo Blobs in IndexedDB)   |
| `Views/*.swift`                         | `app.js` + `styles.css`              |
| `Assets.xcassets`                       | `images/` (resized to 800×1200)      |
| `GymWorkoutTests`                       | `tests/store.test.mjs`               |

## Run locally

```sh
cd web && python3 -m http.server 8000   # then open http://localhost:8000
node --test web/tests/store.test.mjs    # from the repo root
```

## Put it on your iPhone

A PWA must be served over **HTTPS** for the offline service worker to work. Pick one host:

- **GitHub Pages** — `.github/workflows/pages.yml` deploys `web/` on every push to `main`.
  In the repo go to *Settings → Pages → Source* and choose **GitHub Actions**.
  Pages on a **private** repo needs a paid GitHub plan (Pro); otherwise make the repo public
  or use one of the options below.
- **Netlify / Cloudflare Pages / Vercel** (free, private repos fine) — connect the repo,
  set the publish directory to `web`, leave the build command empty.

Then on the iPhone: open the URL in **Safari → Share → Add to Home Screen**. Launch it from the
home-screen icon; it runs full-screen and works offline at the gym.

## Notes

- Your data lives on the phone, inside the installed app. Removing the home-screen icon deletes it.
- After changing any file in `web/`, bump `CACHE_VERSION` in `sw.js` so installed copies update
  (they pick up the new version the next time the app is opened twice with a connection).
