// Port of SeedWorkoutFactory.swift: the workout created on first launch.
const workoutA = [
  ["Cross trainer", "N/A", "N/A", "N/A", "10 mins", "cross-trainer"],
  ["Wall Agents", "2", "12", "", "", "wall-angels"],
  ["Shoulder dislocates (with band or bar)", "2", "12", "", "", "shoulder-dislocates"],
  ["Body weight squats", "2", "12", "", "", "bodyweight-squats"],
  ["Leg Extension", "4", "6", "66", "Machine; backrest 3", "leg-extension"],
  ["Leg Press", "3", "10", "86", "Machine; seat 3", "leg-press"],
  ["Seated Leg Curl", "2", "10", "45", "Machine; backrest 3, 1, 2", "seated-leg-curl"],
  ["Calf press", "3", "6", "79", "Either standing, seated, or machine", "calf-press"],
  ["Assisted chin-up", "3", "8", "-23", "Machine", "assisted-chin-up"],
  ["Cable row", "3", "8", "52", "Machine", "cable-row"],
  ["Overhead Press", "2", "10", "25", "Small barbells", "overhead-press"],
  ["Diverging lat pulldown", "2", "12", "45", "Machine", "diverging-lat-pulldown"],
  ["Cable tricep pulldowns", "1", "12", "32", "Machine", "cable-tricep-pulldowns"],
  ["Dumbbell curls", "2", "6", "12", "Free dumbbells", "dumbbell-curls"],
];

export function seedWorkouts() {
  return [
    {
      id: crypto.randomUUID(),
      name: "Workout A",
      exercises: workoutA.map(([name, setsText, repsText, weightText, notes, bundledPhotoName]) => ({
        id: crypto.randomUUID(),
        name,
        setsText,
        repsText,
        weightText,
        notes,
        bundledPhotoName,
        userPhotoId: null,
      })),
      session: { currentExerciseId: null, completedExerciseIds: [], isFinished: false },
    },
  ];
}
