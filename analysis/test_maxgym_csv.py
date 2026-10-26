from pathlib import Path

import pytest

from maxgym_csv import COLUMNS, load_set

GOLDEN = Path(__file__).parent.parent / "fixtures" / "set_v1.csv"


def test_loads_golden_file():
    meta, df = load_set(GOLDEN)
    assert meta["exercise"] == "bicep_curl"
    assert int(meta["true_reps"]) == 3
    assert meta["wrist"] == "left" and meta["crown"] == "right"
    assert list(df.columns) == COLUMNS
    assert len(df) == 3
    assert df["acc_x"].iloc[2] == pytest.approx(-0.12346)


def test_rejects_unknown_version(tmp_path):
    bad = tmp_path / "bad.csv"
    bad.write_text(GOLDEN.read_text().replace("format_version=1", "format_version=2"))
    with pytest.raises(ValueError):
        load_set(bad)
