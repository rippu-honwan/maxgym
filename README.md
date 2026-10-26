# MaxGym

Automatic rep counting for strength training on Apple Watch. A data science portfolio project:
the watch records wrist motion for each set together with the true rep count, and the counting
algorithm is built and evaluated on that labelled data.

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
