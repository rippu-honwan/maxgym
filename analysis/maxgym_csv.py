"""Load MaxGym set recordings (CSV format v1, see README.md)."""
from __future__ import annotations

from pathlib import Path

import pandas as pd

FORMAT_VERSION = "1"
COLUMNS = ["t", "acc_x", "acc_y", "acc_z", "grav_x", "grav_y", "grav_z",
           "rot_x", "rot_y", "rot_z", "att_w", "att_x", "att_y", "att_z"]


def load_set(path: str | Path) -> tuple[dict[str, str], pd.DataFrame]:
    """Return (header metadata, samples). Raises ValueError for an unsupported file."""
    meta: dict[str, str] = {}
    with open(path, encoding="utf-8") as f:
        for line in f:
            if not line.startswith("#"):
                break
            key, _, value = line[1:].strip().partition("=")
            meta[key] = value
    if meta.get("format_version") != FORMAT_VERSION:
        raise ValueError(f"{path}: unsupported format_version {meta.get('format_version')!r}")
    df = pd.read_csv(path, comment="#")
    if list(df.columns) != COLUMNS:
        raise ValueError(f"{path}: unexpected columns {list(df.columns)}")
    return meta, df


def weight_kg(meta: dict[str, str]) -> float | None:
    """Load in kg (negative = assistance), or None for bodyweight (empty or missing `weight_kg`)."""
    value = meta.get("weight_kg", "")
    return float(value) if value else None
