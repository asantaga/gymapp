enum WorkoutPlayerCopy {
    static func completeButton(isComplete: Bool) -> String {
        isComplete ? "Completed" : "Mark complete"
    }

    static func progress(position: Int, total: Int) -> String {
        "Exercise \(position) of \(total)"
    }
}
