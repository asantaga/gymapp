// Port of the SwiftData models + WorkoutSessionStore.
// Workouts (with their exercises and session) persist as JSON in localStorage.
import { seedWorkouts } from "./seed.js";

const STORAGE_KEY = "gym-workout.v1";

export function loadWorkouts(storage = globalThis.localStorage) {
  try {
    const saved = JSON.parse(storage.getItem(STORAGE_KEY));
    if (Array.isArray(saved)) return saved;
  } catch {
    // Corrupt data: fall through and reseed rather than crash.
  }
  const seeded = seedWorkouts();
  saveWorkouts(seeded, storage);
  return seeded;
}

export function saveWorkouts(workouts, storage = globalThis.localStorage) {
  storage.setItem(STORAGE_KEY, JSON.stringify(workouts));
}

export function emptySession() {
  return { currentExerciseId: null, completedExerciseIds: [], isFinished: false };
}

// --- Session (player) logic -------------------------------------------------

export function currentPosition(workout) {
  const index = workout.exercises.findIndex((e) => e.id === workout.session.currentExerciseId);
  return index === -1 ? 0 : index;
}

export function currentExercise(workout) {
  return workout.exercises[currentPosition(workout)] ?? null;
}

// Only counts IDs that still belong to the workout (exercises may have been deleted).
export function completedCount(workout) {
  return workout.exercises.filter((e) => isCompleted(workout, e)).length;
}

export function isCompleted(workout, exercise) {
  return workout.session.completedExerciseIds.includes(exercise.id);
}

export function toggleCompletion(workout, exercise) {
  const ids = workout.session.completedExerciseIds;
  const index = ids.indexOf(exercise.id);
  if (index === -1) ids.push(exercise.id);
  else ids.splice(index, 1);
  workout.session.isFinished =
    workout.exercises.length > 0 && completedCount(workout) === workout.exercises.length;
}

export function goNext(workout) {
  moveTo(workout, Math.min(currentPosition(workout) + 1, workout.exercises.length - 1));
}

export function goPrevious(workout) {
  moveTo(workout, Math.max(currentPosition(workout) - 1, 0));
}

export function startNewWorkout(workout) {
  workout.session = emptySession();
  workout.session.currentExerciseId = workout.exercises[0]?.id ?? null;
}

function moveTo(workout, position) {
  const exercise = workout.exercises[position];
  if (exercise) workout.session.currentExerciseId = exercise.id;
}

// --- Editing ----------------------------------------------------------------

export function addWorkout(workouts, name) {
  const workout = { id: crypto.randomUUID(), name, exercises: [], session: emptySession() };
  workouts.push(workout);
  return workout;
}

export function deleteWorkout(workouts, workoutId) {
  const index = workouts.findIndex((w) => w.id === workoutId);
  return index === -1 ? null : workouts.splice(index, 1)[0];
}

export function upsertExercise(workout, fields, exerciseId = null) {
  let exercise = workout.exercises.find((e) => e.id === exerciseId);
  if (!exercise) {
    exercise = { id: crypto.randomUUID(), bundledPhotoName: null, userPhotoId: null };
    workout.exercises.push(exercise);
  }
  Object.assign(exercise, fields);
  return exercise;
}

export function deleteExercise(workout, exerciseId) {
  const index = workout.exercises.findIndex((e) => e.id === exerciseId);
  if (index === -1) return null;
  const [removed] = workout.exercises.splice(index, 1);
  workout.session.completedExerciseIds = workout.session.completedExerciseIds.filter((id) => id !== exerciseId);
  if (workout.session.currentExerciseId === exerciseId) workout.session.currentExerciseId = null;
  return removed;
}

export function moveExercise(workout, fromIndex, toIndex) {
  if (toIndex < 0 || toIndex >= workout.exercises.length) return;
  const [exercise] = workout.exercises.splice(fromIndex, 1);
  workout.exercises.splice(toIndex, 0, exercise);
}
