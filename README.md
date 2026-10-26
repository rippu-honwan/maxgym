# MaxGym

Automatic rep counting for strength training on Apple Watch. A data science portfolio project:
the watch records wrist motion for each set together with the true rep count, and the counting
algorithm is built and evaluated on that labelled data.

```
Apple Watch (record) ──WatchConnectivity──▶ iPhone (collect CSVs) ──AirDrop──▶ Mac (analysis/)
```

## Setup

1. Install Xcode 27 and the watchOS platform, then XcodeGen: `brew install xcodegen`.
2. Generate and open the project:
   ```bash
   xcodegen
   open MaxGym.xcodeproj
   ```
3. In Xcode, set your Team under Signing & Capabilities for both targets `MaxGym` and `MaxGymWatch`.
   `xcodegen` regenerates the project, so you may need to pick the Team again after running it.
4. Turn on Developer Mode on the iPhone and the Apple Watch (Settings → Privacy & Security).
5. Run scheme `MaxGymWatch` on the Apple Watch. Allow Health and Motion access on first launch.

With a free Apple ID the apps expire after 7 days; run them from Xcode again.

## Collecting data

Per set: pick the exercise → **Start** → do the set → **Stop** → turn the Digital Crown to the
true rep count → **Save**.

Rules (break them and the data is useless):
- Wear the watch on the same wrist, in the same position, every time.
- After Start, wait about one second before the first rep. After the last rep, wait one second before Stop.
- Vary the rep count on purpose (e.g. 5, 8, 12, 15). Always doing 10 teaches a model to guess 10.
- The rep count is the label. If you are not sure it is right, tap **Discard**.
- Aim for at least 15 sets per exercise. The iPhone app shows the count in green when you get there.

Then on the iPhone: MaxGym → **Share All** → AirDrop to the Mac → put the files in `data/`.
`data/` is gitignored, so back it up somewhere else (e.g. iCloud Drive). The recordings cannot be redone.

## Tests

```bash
swift test --package-path MaxGymCore              # Swift core
python3 -m venv .venv && .venv/bin/pip install -r analysis/requirements.txt
.venv/bin/python -m pytest analysis               # Python
```

## CSV format (v1)

One file per set. The format is a contract between the Swift encoder
(`MaxGymCore/Sources/MaxGymCore/SetCSV.swift`) and the Python loader (`analysis/maxgym_csv.py`).
Both are tested against [`fixtures/set_v1.csv`](fixtures/set_v1.csv). Change all of them together
and bump `format_version`.

File name: `yyyyMMdd-HHmmss_<exercise>_<n>reps.csv` (watch local time), e.g. `20261026-141500_bicep_curl_10reps.csv`.

Header lines (`# key=value`):

| Key | Example | Meaning |
|---|---|---|
| `format_version` | `1` | CSV format version |
| `exercise` | `bicep_curl` | Exercise ID (`Exercise` raw value) |
| `true_reps` | `10` | Label: reps counted by the user |
| `weight_kg` | `12.5` or empty | Load in kg (0.5 kg steps). Empty = bodyweight |
| `sample_rate_hz` | `50` | Requested sample rate |
| `recorded_at` | `2026-10-26T06:15:00Z` | Set start, ISO 8601 UTC |
| `wrist` | `left` / `right` | Wrist the watch is worn on |
| `crown` | `left` / `right` | Side the Digital Crown faces |

Columns (one row per CMDeviceMotion sample):

| Columns | Source | Unit |
|---|---|---|
| `t` | `timestamp`, relative to the first sample | s |
| `acc_x,acc_y,acc_z` | `userAcceleration` (gravity removed) | g |
| `grav_x,grav_y,grav_z` | `gravity` | g |
| `rot_x,rot_y,rot_z` | `rotationRate` | rad/s |
| `att_w,att_x,att_y,att_z` | `attitude.quaternion` | — |

`t` has 4 decimals, all other values 5. Gaps in `t` show dropped samples.
