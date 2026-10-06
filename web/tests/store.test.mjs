// Ports of GymWorkoutTests/*.swift. Run with: node --test web/tests
import { test } from "node:test";
import assert from "node:assert/strict";
import { existsSync } from "node:fs";
import * as store from "../store.js";
import { seedWorkouts } from "../seed.js";

class MemoryStorage {
  #data = new Map();
  getItem(key) { return this.#data.get(key) ?? null; }
  setItem(key, value) { this.#data.set(key, String(value)); }
}

const makeWorkout = (count = 3) => {
  const workout = store.addWorkout([], "Test");
  for (let i = 0; i < count; i++) store.upsertExercise(workout, { name: `E${i}` });
  return workout;
};

test("session without saved position starts at first exercise", () => {
  const w = makeWorkout();
  assert.equal(store.currentPosition(w), 0);
  assert.equal(store.currentExercise(w).name, "E0");
});

test("completing an exercise updates progress", () => {
  const w = makeWorkout();
  store.toggleCompletion(w, w.exercises[0]);
  assert.equal(store.completedCount(w), 1);
  assert.ok(store.isCompleted(w, w.exercises[0]));
});

test("next does not mark exercise complete", () => {
  const w = makeWorkout();
  store.goNext(w);
  assert.equal(store.currentPosition(w), 1);
  assert.equal(store.completedCount(w), 0);
});

test("navigation clamps at first and last exercises", () => {
  const w = makeWorkout();
  store.goPrevious(w);
  assert.equal(store.currentPosition(w), 0);
  for (let i = 0; i < 5; i++) store.goNext(w);
  assert.equal(store.currentPosition(w), 2);
});

test("start new workout clears completion and returns to first exercise", () => {
  const w = makeWorkout();
  store.goNext(w);
  w.exercises.forEach((e) => store.toggleCompletion(w, e));
  assert.ok(w.session.isFinished);
  store.startNewWorkout(w);
  assert.equal(store.completedCount(w), 0);
  assert.equal(store.currentPosition(w), 0);
  assert.equal(w.session.isFinished, false);
});

test("session is finished only when every exercise is complete; uncompleting clears it", () => {
  const w = makeWorkout();
  store.toggleCompletion(w, w.exercises[0]);
  store.toggleCompletion(w, w.exercises[1]);
  assert.equal(w.session.isFinished, false);
  store.toggleCompletion(w, w.exercises[2]);
  assert.equal(w.session.isFinished, true);
  store.toggleCompletion(w, w.exercises[2]);
  assert.equal(w.session.isFinished, false);
});

test("deleting an exercise removes it from session progress", () => {
  const w = makeWorkout();
  store.toggleCompletion(w, w.exercises[1]);
  store.deleteExercise(w, w.exercises[1].id);
  assert.equal(w.exercises.length, 2);
  assert.equal(store.completedCount(w), 0);
});

test("moving an exercise reorders and ignores out-of-range moves", () => {
  const w = makeWorkout();
  store.moveExercise(w, 2, 0);
  assert.deepEqual(w.exercises.map((e) => e.name), ["E2", "E0", "E1"]);
  store.moveExercise(w, 0, -1);
  assert.deepEqual(w.exercises.map((e) => e.name), ["E2", "E0", "E1"]);
});

test("mutations persist and reload", () => {
  const storage = new MemoryStorage();
  const workouts = store.loadWorkouts(storage);
  store.toggleCompletion(workouts[0], workouts[0].exercises[0]);
  workouts[0].name = "Edited";
  store.saveWorkouts(workouts, storage);
  const reloaded = store.loadWorkouts(storage);
  assert.equal(reloaded[0].name, "Edited");
  assert.equal(store.completedCount(reloaded[0]), 1);
});

test("seed creates fourteen ordered exercises with prescriptions and notes", () => {
  const [w] = seedWorkouts();
  assert.equal(w.name, "Workout A");
  assert.equal(w.exercises.length, 14);
  assert.equal(w.exercises[0].name, "Cross trainer");
  assert.equal(w.exercises[0].notes, "10 mins");
  const legPress = w.exercises[5];
  assert.deepEqual([legPress.name, legPress.setsText, legPress.repsText, legPress.weightText, legPress.notes],
    ["Leg Press", "3", "10", "86", "Machine; seat 3"]);
  assert.equal(w.exercises[13].name, "Dumbbell curls");
});

test("seed assigns each exercise a bundled photo that exists", () => {
  for (const e of seedWorkouts()[0].exercises) {
    assert.ok(existsSync(new URL(`../images/${e.bundledPhotoName}.jpg`, import.meta.url)), e.bundledPhotoName);
  }
});

test("seed does not overwrite edited workouts", () => {
  const storage = new MemoryStorage();
  store.saveWorkouts([{ id: "x", name: "Mine", exercises: [], session: store.emptySession() }], storage);
  assert.equal(store.loadWorkouts(storage)[0].name, "Mine");
});
