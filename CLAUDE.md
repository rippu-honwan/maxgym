# Project Context

- Project: MaxGym — automatic rep counting for strength training on Apple Watch (portfolio / data science project)
- Phase 1: collect wrist sensor data + true rep counts as labelled data for training and evaluating a rep-counting algorithm
- Platforms: watchOS 10+ (target `MaxGymWatch`), iOS 17+ (target `MaxGym`)
- Language: Swift 5, SwiftUI; analysis in Python 3
- Project generation: XcodeGen
  - Edit `project.yml`, then run `xcodegen`.
  - Never edit `MaxGym.xcodeproj` directly; it is generated and gitignored.
- Main entry:
  - `Watch/` for the watchOS app
    - `MotionRecorder.swift`: CMDeviceMotion at 50 Hz
    - `WorkoutManager.swift`: HKWorkoutSession so recording continues with wrist down
    - `SetStore.swift`: writes CSV, sends to iPhone via WatchConnectivity `transferFile`
    - `RecordSetView.swift`, `ExerciseListView.swift`, `Exercise.swift`: UI and exercise list
  - `iOS/` for the iPhone companion app (receive, count, share CSVs)
  - `analysis/count_reps.py` for the baseline counter (low-pass filter → PCA → autocorrelation → find_peaks)
- Build / verify:
  - Use the Xcode MCP to build both schemes `MaxGymWatch` and `MaxGym`.
  - Pair schemes with matching destinations: `MaxGymWatch` → Apple Watch, `MaxGym` → iPhone.
  - Analysis: `cd analysis && python count_reps.py --demo`
- Data:
  - Recorded CSVs go into `data/`; never modify recorded CSVs (they are labelled ground truth).
  - Analysis outputs go into `analysis/results/` (gitignored).
  - CSV format is a contract with the Python analysis; do not change it without updating `count_reps.py`:
    - Header lines: `# key=value` for `exercise`, `exercise_name`, `true_reps`, `sample_rate_hz`, `recorded_at`
    - Columns: `t,acc_x,acc_y,acc_z,grav_x,grav_y,grav_z,rot_x,rot_y,rot_z`
    - File name: `yyyyMMdd-HHmmss_<exercise_id>_<n>reps.csv`

# Project-specific Rules

- All code, identifiers, comments, commit messages and in-app UI text must be in English.
- Use Apple frameworks only; do not add third-party packages unless asked.
- New Swift files go in `Watch/` or `iOS/`; XcodeGen adds them to the right target automatically.
- Make small changes, then build both schemes to confirm zero errors before moving on.
- Keep watch UI usable mid-workout: large tap targets, minimal text, haptic feedback for state changes.
- Keep algorithm logic in pure functions (no UI / sensor dependencies) so it can be tested and ported between Python and Swift.
- Any change to the counting algorithm must report MAE and exact-match rate per exercise, compared with the previous version.
- Signing / Team / device setup errors are not code problems: stop and tell me instead of changing build settings.

# Response Style

- Talk to me in concise Hong Kong Chinese (Cantonese, Traditional characters).
- I am new to Swift: for every change, say what changed, why, and give a simple example or analogy.
- For engineering work: be direct, concrete, and include file paths.
- Point out flaws in my ideas directly; do not just agree.
