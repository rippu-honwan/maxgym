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

Per set: pick the day → pick the exercise → **Start** → do the set → **Stop** → turn the Digital
Crown to the true rep count → **Next** → turn the crown to the weight → **Save**.

Rules (break them and the data is useless):
- Wear the watch on the same wrist, in the same position, every time.
- After Start, wait about one second before the first rep. After the last rep, wait one second before Stop.
- Vary the rep count on purpose (e.g. 5, 8, 12, 15). Always doing 10 teaches a model to guess 10.
- The rep count is the label. If you are not sure it is right, tap **Discard**.
- `cable_lateral_raise` is single-arm: record only the sets done with the arm wearing the watch.
- Aim for at least 15 sets per exercise. The iPhone app shows the count in green when you get there.

### What gets recorded

Rule: record an exercise only if the **wrist moves or rotates in space**. Holding a handle is not
the question. Assisted pull-up: the hands are fixed, but the forearm rotates around the grip, so it
is recorded. Hip abduction: hands and wrists do not move at all, so it is not.

Tiers (`Exercise.tier` in `MaxGymCore`):
- **core**: clear wrist signal, main focus of Phase 2.
- **experimental**: recorded anyway, expected to be hard to count.

| ID | Equipment | Tier | Days |
|---|---|---|---|
| `machine_chest_press` | machine | core | Upper A |
| `machine_seated_row` | machine | core | Upper A |
| `lat_pulldown` | machine | core | Upper A |
| `lat_pulldown_narrow` | machine | core | Upper B |
| `machine_shoulder_press` | machine | core | Upper A |
| `cable_lateral_raise` | cable | core | Upper A, Upper B |
| `cable_overhead_triceps_extension` | cable | core | Upper A |
| `cable_bicep_curl` | cable | core | Upper A, Upper B |
| `cable_chest_fly` | cable | core | Upper B |
| `cable_face_pull` | cable | core | Upper B |
| `cable_triceps_pushdown` | cable | core | Upper B |
| `smith_rdl` | smith | core | Lower A |
| `assisted_pull_up` | assisted | experimental | Upper B |
| `assisted_dip` | assisted | experimental | Upper B |
| `cable_crunch` | cable | experimental | Upper A |
| `smith_squat` | smith | experimental | Lower B |
| `smith_hip_thrust` | smith | experimental | Lower B |
| `machine_torso_rotation` | machine | experimental | Lower B |

The watch shows each day's exercises in gym order (`Routine.days` in `MaxGymCore`).

Out of scope (in the routine, but not recorded): the hands rest on fixed handles and the wrists do
not move, so there is no wrist signal to count.

| Exercise | Why not |
|---|---|
| Leg press | Hands on fixed side handles |
| Calf press | Hands on fixed side handles |
| Seated leg curl | Hands on fixed side handles |
| Leg extension | Hands on fixed side handles |
| Hip adduction | Hands and wrists do not move |
| Hip abduction | Hands and wrists do not move |

### Weight convention

The watch shows a short reminder under the value.

| Equipment | Enter | Watch hint |
|---|---|---|
| Machine / cable | Stack value shown on the machine | `kg stack` |
| Smith | Plates only, **without** the bar. `0` = bar only | `kg plates` |
| Assisted | Assistance as a **negative** number, e.g. `-47` | `47` / `kg assist` |
| Bodyweight (all except Smith) | `0` (shows `BW`) | `bodyweight` |

On assisted exercises the crown goes from -150 to 0; on all others from 0 to 300 (0.5 kg steps).
`0` is written as an empty `weight_kg` (bodyweight), except on Smith where it is written as `0` (bar only).

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

File name: `yyyyMMdd-HHmmss_<exercise>_<n>reps.csv` (watch local time), e.g. `20261026-141500_cable_bicep_curl_10reps.csv`.

Header lines (`# key=value`):

| Key | Example | Meaning |
|---|---|---|
| `format_version` | `1` | CSV format version |
| `exercise` | `cable_bicep_curl` | Exercise ID (`Exercise` raw value) |
| `true_reps` | `10` | Label: reps counted by the user |
| `weight_kg` | `12.5`, `-47` or empty | Load in kg (0.5 kg steps), see note below. Negative = assistance. `0` = Smith bar only. Empty = bodyweight |
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

`weight_kg` follows the [weight convention](#weight-convention): stack value for machines and
cables, plates only for Smith, negative assistance for assisted exercises.

`t` has 4 decimals, all other values 5. Gaps in `t` show dropped samples.
