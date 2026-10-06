import * as store from "./store.js";
import { savePhoto, loadPhoto, deletePhoto, resizeImage } from "./db.js";

const app = document.getElementById("app");
let workouts = store.loadWorkouts();

const persist = () => store.saveWorkouts(workouts);
const findWorkout = (id) => workouts.find((w) => w.id === id);
const go = (hash) => (location.hash = hash);

const escapeHtml = (value) =>
  String(value ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);

// --- Icons (inline SVG stand-ins for the SF Symbols the Swift app used) -----

const icon = {
  plus: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 5v14M5 12h14"/></svg>',
  back: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M15 5l-7 7 7 7"/></svg>',
  pencil: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 20h4L19 9l-4-4L4 16v4zM14 6l4 4"/></svg>',
  play: '<svg viewBox="0 0 24 24" aria-hidden="true" class="fill"><path d="M7 5v14l12-7z"/></svg>',
  restart: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M20 12a8 8 0 1 1-2.3-5.6M20 4v5h-5"/></svg>',
  check: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg>',
  up: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M6 15l6-6 6 6"/></svg>',
  down: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M6 9l6 6 6-6"/></svg>',
  dumbbell:
    '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M6 7v10M3 9.5v5M18 7v10M21 9.5v5M6 12h12"/></svg>',
  seal: '<svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="M8 12.5l3 3 5-6"/></svg>',
};

// --- Photos -----------------------------------------------------------------

const photoUrls = new Map();

async function photoUrl(exercise) {
  if (exercise.userPhotoId) {
    if (!photoUrls.has(exercise.userPhotoId)) {
      const blob = await loadPhoto(exercise.userPhotoId).catch(() => null);
      if (blob) photoUrls.set(exercise.userPhotoId, URL.createObjectURL(blob));
    }
    if (photoUrls.has(exercise.userPhotoId)) return photoUrls.get(exercise.userPhotoId);
  }
  return exercise.bundledPhotoName ? `images/${exercise.bundledPhotoName}.jpg` : null;
}

async function removeUserPhoto(exercise) {
  if (!exercise?.userPhotoId) return;
  const url = photoUrls.get(exercise.userPhotoId);
  if (url) URL.revokeObjectURL(url);
  photoUrls.delete(exercise.userPhotoId);
  await deletePhoto(exercise.userPhotoId).catch(() => {});
}

// --- Router -----------------------------------------------------------------

const routes = [
  [/^#?\/?$/, renderHome],
  [/^#\/play\/([^/]+)$/, renderPlayer],
  [/^#\/done\/([^/]+)$/, renderSummary],
  [/^#\/new-workout$/, () => renderWorkoutEdit(null)],
  [/^#\/workout\/([^/]+)$/, renderManage],
  [/^#\/workout\/([^/]+)\/rename$/, renderWorkoutEdit],
  [/^#\/workout\/([^/]+)\/exercise\/([^/]+)$/, renderExerciseEdit],
];

function route() {
  for (const [pattern, render] of routes) {
    const match = location.hash.match(pattern);
    if (match) {
      window.scrollTo(0, 0);
      return render(...match.slice(1));
    }
  }
  go("#/");
}

window.addEventListener("hashchange", route);

// --- Home (HomeView.swift) --------------------------------------------------

function renderHome() {
  const count = workouts.length;
  app.innerHTML = `
    <header class="hero">
      <div>
        <p class="eyebrow">GYM WORKOUT</p>
        <h1>Your Workouts</h1>
        <p class="hero-sub">${count} workout${count === 1 ? "" : "s"}</p>
      </div>
      <a class="round-button light" href="#/new-workout" aria-label="Add workout">${icon.plus}</a>
    </header>
    <section class="stack">
      ${workouts.map(workoutCard).join("") || '<p class="empty">No workouts yet. Tap + to add one.</p>'}
    </section>`;

  app.querySelectorAll("[data-start]").forEach((button) =>
    button.addEventListener("click", () => {
      const workout = findWorkout(button.dataset.start);
      store.startNewWorkout(workout);
      persist();
      go(`#/play/${workout.id}`);
    })
  );
}

function workoutCard(workout) {
  const total = workout.exercises.length;
  const done = store.completedCount(workout);
  const finished = workout.session.isFinished;
  const active = !finished && done > 0;
  const percent = total ? (done / total) * 100 : 0;

  const actions =
    total === 0
      ? '<p class="muted small">No exercises yet. Tap the pencil to add some.</p>'
      : `${active ? `<a class="button primary" href="#/play/${workout.id}">${icon.play} Resume workout</a>` : ""}
         <button class="button ${active ? "outline" : "primary"}" data-start="${workout.id}">${icon.restart} Start New Workout</button>`;

  return `
    <article class="card workout-card">
      <div class="row">
        <span class="card-icon">${finished ? icon.seal : icon.dumbbell}</span>
        <div class="grow">
          <h2>${escapeHtml(workout.name)}</h2>
          <p class="muted">${done} of ${total} exercises completed</p>
        </div>
        <a class="icon-link" href="#/workout/${workout.id}" aria-label="Manage exercises for ${escapeHtml(workout.name)}">${icon.pencil}</a>
      </div>
      <div class="progress" role="progressbar" aria-label="Workout completion" aria-valuenow="${done}" aria-valuemax="${total}">
        <span style="width:${percent}%"></span>
      </div>
      ${actions}
    </article>`;
}

// --- Player (WorkoutPlayerView.swift + ExerciseDetailCard.swift) ------------

function renderPlayer(workoutId) {
  const workout = findWorkout(workoutId);
  if (!workout) return go("#/");

  const exercise = store.currentExercise(workout);
  if (!exercise) {
    app.innerHTML = `
      <div class="empty-state">
        ${icon.dumbbell}
        <h2>No exercises</h2>
        <p class="muted">Return home and start a workout after adding an exercise.</p>
        <a class="button primary" href="#/">Return home</a>
      </div>`;
    return;
  }

  const position = store.currentPosition(workout) + 1;
  const total = workout.exercises.length;
  const completed = store.isCompleted(workout, exercise);

  app.innerHTML = `
    <div class="player">
      <header class="player-header">
        <div class="row">
          <a class="round-button dark" href="#/" aria-label="Return to home">${icon.back}</a>
          <div class="grow">
            <h1 class="player-title">${escapeHtml(workout.name)}</h1>
            <p class="hero-sub small">Exercise ${position} of ${total}</p>
          </div>
          <span class="pill" aria-hidden="true">${position}/${total}</span>
        </div>
        <div class="progress light" role="progressbar" aria-label="Workout progress" aria-valuenow="${position}" aria-valuemax="${total}">
          <span style="width:${(position / total) * 100}%"></span>
        </div>
      </header>

      <article class="card exercise-card" id="exercise-card">
        <div class="photo" role="img" aria-label="${escapeHtml(exercise.name)} exercise photo">
          <div class="photo-placeholder">${icon.dumbbell}</div>
        </div>
        <h2 class="exercise-name">${escapeHtml(exercise.name)}</h2>
        <div class="tiles">
          ${tile("Sets", exercise.setsText)}${tile("Reps", exercise.repsText)}${tile("kg", exercise.weightText)}
        </div>
        <div>
          <h3>Notes</h3>
          <p class="muted">${escapeHtml(exercise.notes) || "No additional notes."}</p>
        </div>
        <button class="button ${completed ? "primary" : "outline"}" id="toggle-complete" aria-pressed="${completed}">
          ${completed ? `${icon.check} Completed` : "Mark complete"}
        </button>
        <p class="swipe-hint muted small">Swipe left or right to change exercise</p>
      </article>
    </div>`;

  photoUrl(exercise).then((url) => {
    if (!url) return;
    const img = new Image();
    img.alt = "";
    img.src = url;
    img.onload = () => app.querySelector(".photo")?.replaceChildren(img);
  });

  app.querySelector("#toggle-complete").addEventListener("click", () => {
    store.toggleCompletion(workout, exercise);
    persist();
    if (workout.session.isFinished) go(`#/done/${workout.id}`);
    else if (store.isCompleted(workout, exercise) && position < total) {
      store.goNext(workout);
      persist();
      renderPlayer(workoutId);
    } else renderPlayer(workoutId);
  });

  attachSwipe(app.querySelector(".player"), (direction) => {
    if (direction === "left") store.goNext(workout);
    else store.goPrevious(workout);
    persist();
    renderPlayer(workoutId);
  });
}

function tile(label, value) {
  return `
    <div class="tile" aria-label="${label}, ${value ? escapeHtml(value) : "not specified"}">
      <strong>${escapeHtml(value) || "—"}</strong>
      <span>${label.toUpperCase()}</span>
    </div>`;
}

// Horizontal swipe only, mirroring handleSwipe() in WorkoutPlayerView.swift.
function attachSwipe(element, onSwipe) {
  let startX = 0;
  let startY = 0;
  element.addEventListener("touchstart", (e) => {
    startX = e.touches[0].clientX;
    startY = e.touches[0].clientY;
  }, { passive: true });
  element.addEventListener("touchend", (e) => {
    const dx = e.changedTouches[0].clientX - startX;
    const dy = e.changedTouches[0].clientY - startY;
    if (Math.abs(dx) < 30 || Math.abs(dx) <= Math.abs(dy)) return;
    onSwipe(dx < 0 ? "left" : "right");
  });
}

// --- Completion summary (CompletionSummaryView.swift) -----------------------

function renderSummary(workoutId) {
  const workout = findWorkout(workoutId);
  if (!workout) return go("#/");
  app.innerHTML = `
    <div class="empty-state summary">
      <span class="summary-icon">${icon.seal}</span>
      <h1>Workout complete</h1>
      <p class="lead">${store.completedCount(workout)} of ${workout.exercises.length} exercises completed</p>
      <p class="muted">Strong work. Your completed workout stays saved until you start a new one.</p>
      <a class="button primary" href="#/">Done</a>
      <button class="button outline" id="start-new">Start New Workout</button>
    </div>`;
  app.querySelector("#start-new").addEventListener("click", () => {
    store.startNewWorkout(workout);
    persist();
    go(`#/play/${workout.id}`);
  });
}

// --- Manage exercises (ManageExercisesView.swift) ---------------------------

function renderManage(workoutId) {
  const workout = findWorkout(workoutId);
  if (!workout) return go("#/");
  const last = workout.exercises.length - 1;

  app.innerHTML = `
    ${navBar(escapeHtml(workout.name), `<a href="#/">${icon.back} Workouts</a>`,
      `<a href="#/workout/${workout.id}/exercise/new" aria-label="Add exercise">${icon.plus}</a>`)}
    <section class="list">
      ${workout.exercises
        .map(
          (e, i) => `
        <div class="list-row">
          <a class="grow" href="#/workout/${workout.id}/exercise/${e.id}">
            <span>${escapeHtml(e.name)}</span>
            <small>Sets ${escapeHtml(e.setsText)} • Reps ${escapeHtml(e.repsText)} • ${escapeHtml(e.weightText)}</small>
          </a>
          <button class="icon-button" data-move="${i}" data-to="${i - 1}" ${i === 0 ? "disabled" : ""} aria-label="Move ${escapeHtml(e.name)} up">${icon.up}</button>
          <button class="icon-button" data-move="${i}" data-to="${i + 1}" ${i === last ? "disabled" : ""} aria-label="Move ${escapeHtml(e.name)} down">${icon.down}</button>
        </div>`
        )
        .join("") || '<p class="empty">No exercises yet. Tap + to add one.</p>'}
    </section>
    <section class="list">
      <a class="list-row link" href="#/workout/${workout.id}/rename">Rename or delete workout</a>
    </section>`;

  app.querySelectorAll("[data-move]").forEach((button) =>
    button.addEventListener("click", () => {
      store.moveExercise(workout, Number(button.dataset.move), Number(button.dataset.to));
      persist();
      renderManage(workoutId);
    })
  );
}

function navBar(title, left = "", right = "") {
  return `
    <nav class="nav-bar">
      <div class="nav-left">${left}</div>
      <h1>${title}</h1>
      <div class="nav-right">${right}</div>
    </nav>`;
}

// --- Workout edit (WorkoutEditView.swift) -----------------------------------

function renderWorkoutEdit(workoutId) {
  const workout = workoutId ? findWorkout(workoutId) : null;
  if (workoutId && !workout) return go("#/");
  const cancelHref = workout ? `#/workout/${workout.id}` : "#/";

  app.innerHTML = `
    <form id="form">
      ${navBar(workout ? "Rename Workout" : "New Workout", `<a href="${cancelHref}">Cancel</a>`,
        '<button type="submit" class="nav-action">Save</button>')}
      <fieldset>
        <legend>Name</legend>
        <div class="group">
        <input name="name" required placeholder="Workout name" value="${escapeHtml(workout?.name)}" autocomplete="off">
        </div>
      </fieldset>
      ${workout ? '<button type="button" class="button danger" id="delete">Delete Workout</button>' : ""}
    </form>`;

  const form = app.querySelector("#form");
  bindRequiredSave(form);
  form.addEventListener("submit", (e) => {
    e.preventDefault();
    const name = form.name.value.trim();
    if (!name) return;
    if (workout) {
      workout.name = name;
      persist();
      go(cancelHref);
    } else {
      const created = store.addWorkout(workouts, name);
      persist();
      go(`#/workout/${created.id}`);
    }
  });

  app.querySelector("#delete")?.addEventListener("click", async () => {
    if (!confirm(`Delete “${workout.name}” and all its exercises?`)) return;
    store.deleteWorkout(workouts, workout.id);
    persist();
    await Promise.all(workout.exercises.map(removeUserPhoto));
    go("#/");
  });
}

// --- Exercise edit (ExerciseEditView.swift) ---------------------------------

function renderExerciseEdit(workoutId, exerciseId) {
  const workout = findWorkout(workoutId);
  if (!workout) return go("#/");
  const exercise = exerciseId === "new" ? null : workout.exercises.find((e) => e.id === exerciseId);
  if (exerciseId !== "new" && !exercise) return go(`#/workout/${workoutId}`);
  const backHref = `#/workout/${workoutId}`;

  let pendingPhoto = null; // Blob chosen in this edit
  let clearedPhoto = false;

  app.innerHTML = `
    <form id="form">
      ${navBar(exercise ? "Edit Exercise" : "New Exercise", `<a href="${backHref}">Cancel</a>`,
        '<button type="submit" class="nav-action">Save</button>')}
      <fieldset>
        <legend>Name</legend>
        <div class="group">
        <input name="name" required placeholder="Exercise name" value="${escapeHtml(exercise?.name)}" autocomplete="off">
        </div>
      </fieldset>
      <fieldset>
        <legend>Sets, Reps &amp; Weight</legend>
        <div class="group">
        <input name="setsText" placeholder="Sets" value="${escapeHtml(exercise?.setsText)}" inputmode="numeric">
        <input name="repsText" placeholder="Reps" value="${escapeHtml(exercise?.repsText)}" inputmode="numeric">
        <input name="weightText" placeholder="Weight" value="${escapeHtml(exercise?.weightText)}" inputmode="decimal">
        </div>
      </fieldset>
      <fieldset>
        <legend>Notes</legend>
        <div class="group">
        <textarea name="notes" rows="3" placeholder="Notes">${escapeHtml(exercise?.notes)}</textarea>
        </div>
      </fieldset>
      <fieldset>
        <legend>Photo</legend>
        <div class="group">
        <div id="preview" class="preview"></div>
        <label class="file-button">Choose Photo<input type="file" accept="image/*" id="photo" hidden></label>
        <button type="button" class="link-danger" id="remove-photo" hidden>Remove Photo</button>
        </div>
      </fieldset>
      ${exercise ? '<button type="button" class="button danger" id="delete">Delete Exercise</button>' : ""}
    </form>`;

  const form = app.querySelector("#form");
  const preview = app.querySelector("#preview");
  const removeButton = app.querySelector("#remove-photo");
  bindRequiredSave(form);

  const showPreview = async () => {
    let url = null;
    if (pendingPhoto) url = URL.createObjectURL(pendingPhoto);
    else if (!clearedPhoto && exercise?.userPhotoId) url = await photoUrl(exercise);
    preview.innerHTML = url ? `<img src="${url}" alt="Exercise photo preview">` : "";
    removeButton.hidden = !url;
  };
  showPreview();

  app.querySelector("#photo").addEventListener("change", async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    pendingPhoto = await resizeImage(file).catch(() => file);
    clearedPhoto = false;
    showPreview();
  });

  removeButton.addEventListener("click", () => {
    pendingPhoto = null;
    clearedPhoto = true;
    showPreview();
  });

  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    const name = form.name.value.trim();
    if (!name) return;
    const fields = {
      name,
      setsText: form.setsText.value,
      repsText: form.repsText.value,
      weightText: form.weightText.value,
      notes: form.notes.value,
    };
    const target = store.upsertExercise(workout, fields, exercise?.id);

    if (pendingPhoto || clearedPhoto) {
      await removeUserPhoto(target);
      target.userPhotoId = null;
      if (pendingPhoto) {
        try {
          target.userPhotoId = await savePhoto(pendingPhoto);
        } catch {
          alert("Couldn't save the photo. The rest of the exercise was saved.");
        }
      }
    }
    persist();
    go(backHref);
  });

  app.querySelector("#delete")?.addEventListener("click", async () => {
    if (!confirm(`Delete “${exercise.name}”?`)) return;
    store.deleteExercise(workout, exercise.id);
    persist();
    await removeUserPhoto(exercise);
    go(backHref);
  });
}

// Mirrors the disabled Save button for a blank name.
function bindRequiredSave(form) {
  const save = form.querySelector(".nav-action");
  const update = () => (save.disabled = !form.name.value.trim());
  form.name.addEventListener("input", update);
  update();
}

// --- Boot -------------------------------------------------------------------

if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("sw.js").catch(() => {});
}
// Ask the browser not to evict our data under storage pressure.
navigator.storage?.persist?.().catch(() => {});

route();
