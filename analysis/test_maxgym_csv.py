from pathlib import Path

import pytest

from maxgym_csv import COLUMNS, load_set, weight_kg

GOLDEN = Path(__file__).parent.parent / "fixtures" / "set_v1.csv"


def test_loads_golden_file():
    meta, df = load_set(GOLDEN)
    assert meta["exercise"] == "cable_biceps_curl"
    assert int(meta["true_reps"]) == 3
    assert weight_kg(meta) == 12.5
    assert meta["wrist"] == "left" and meta["crown"] == "right"
    assert list(df.columns) == COLUMNS
    assert len(df) == 3
    assert df["acc_x"].iloc[2] == pytest.approx(-0.12346)


def test_rejects_unknown_version(tmp_path):
    bad = tmp_path / "bad.csv"
    bad.write_text(GOLDEN.read_text().replace("format_version=1", "format_version=2"))
    with pytest.raises(ValueError):
        load_set(bad)


def test_empty_weight_is_bodyweight(tmp_path):
    bodyweight = tmp_path / "bw.csv"
    bodyweight.write_text(GOLDEN.read_text().replace("weight_kg=12.5", "weight_kg="))
    meta, _ = load_set(bodyweight)
    assert weight_kg(meta) is None


def test_negative_weight_is_assistance(tmp_path):
    assisted = tmp_path / "assisted.csv"
    assisted.write_text(GOLDEN.read_text().replace("weight_kg=12.5", "weight_kg=-47"))
    meta, _ = load_set(assisted)
    assert weight_kg(meta) == -47.0


def test_zero_weight_is_not_bodyweight(tmp_path):
    bar_only = tmp_path / "bar_only.csv"
    bar_only.write_text(GOLDEN.read_text().replace("weight_kg=12.5", "weight_kg=0"))
    meta, _ = load_set(bar_only)
    assert weight_kg(meta) == 0.0
