"""
MaxGym 基準版自動計數（baseline）
=====================================

做咩：讀 Apple Watch 錄落嚟嘅 CSV，用「數山頂」方法估計每組做咗幾多下，
     再同你喺 watch 輸入嘅真實次數比較，計出誤差。

用法：
    python count_reps.py data/            # 分析你自己嘅數據
    python count_reps.py --demo           # 冇 watch 數據都可以先用假數據試流程

輸出（放喺 results/）：
    results.csv        每一組：真實次數 vs 估計次數
    summary.csv        每個動作嘅平均誤差（MAE）同完全命中率
    plots/*.png        每一組嘅波形圖 + 數到嘅山頂（睇圖先知點解錯）

演算法（每一步都可以喺 report 度解釋）：
    1. 剪走頭尾 0.7 秒（撳掣嘅動作唔係 rep）
    2. 低通濾波 2.5 Hz（人舉重最快約 1 秒一下，快過呢個嘅都係手震 / 雜訊）
    3. PCA 搵「郁得最勁嘅方向」，將 3 軸變 1 條線
       - 重力方向（gravity）：手腕「轉角度」嘅動作，例如彎舉
       - 加速度（acc）：手腕角度唔變、只係上落，例如卧推
    4. 自相關（autocorrelation）睇邊條線最「有規律」，估計一下大約幾多秒
    5. find_peaks 數山頂：山頂要夠高、兩個山頂要隔夠遠
"""
from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass
from pathlib import Path

import numpy as np
import pandas as pd
from scipy.signal import butter, filtfilt, find_peaks

TRIM_SEC = 0.7
CUTOFF_HZ = 2.5
MIN_PERIOD_SEC = 0.8
MAX_PERIOD_SEC = 6.0


# ---------- 讀檔 ----------

@dataclass
class SetRecording:
    path: Path
    exercise: str
    true_reps: int
    fs: float
    df: pd.DataFrame


def load_set(path: Path) -> SetRecording:
    meta: dict[str, str] = {}
    with open(path, encoding="utf-8") as f:
        for line in f:
            if not line.startswith("#"):
                break
            key, _, value = line[1:].strip().partition("=")
            meta[key] = value
    df = pd.read_csv(path, comment="#")
    fs = float(meta.get("sample_rate_hz", 50))
    return SetRecording(path, meta.get("exercise", "unknown"),
                        int(meta.get("true_reps", -1)), fs, df)


# ---------- 訊號處理 ----------

def lowpass(x: np.ndarray, fs: float, cutoff: float = CUTOFF_HZ) -> np.ndarray:
    b, a = butter(4, cutoff / (fs / 2), btype="low")
    return filtfilt(b, a, x, axis=0)


def first_pc(x: np.ndarray) -> np.ndarray:
    """PCA 第一主成分：3 軸 → 1 條最有變化嘅線"""
    centered = x - x.mean(axis=0)
    _, _, vt = np.linalg.svd(centered, full_matrices=False)
    return centered @ vt[0]


def periodicity(sig: np.ndarray, fs: float) -> tuple[float, float]:
    """回傳 (規律程度 0~1, 估計週期秒數)。自相關 = 將條線同自己錯開再比較，
    錯開一個週期嗰陣會最似。"""
    s = (sig - sig.mean()) / (sig.std() + 1e-9)
    ac = np.correlate(s, s, mode="full")[len(s) - 1:]
    ac /= ac[0]
    lo, hi = int(MIN_PERIOD_SEC * fs), min(int(MAX_PERIOD_SEC * fs), len(ac) - 1)
    if hi <= lo:
        return 0.0, 2.0
    lag = lo + int(np.argmax(ac[lo:hi]))
    return float(ac[lag]), lag / fs


def count_peaks(sig: np.ndarray, fs: float, period: float) -> np.ndarray:
    distance = max(1, int(0.6 * period * fs))
    prominence = 0.35 * sig.std()
    peaks, _ = find_peaks(sig, distance=distance, prominence=prominence)
    return peaks


def regularity(peaks: np.ndarray) -> float:
    """山頂之間嘅間隔越平均越好（變異係數越細越好）"""
    if len(peaks) < 3:
        return np.inf
    gaps = np.diff(peaks)
    return float(gaps.std() / gaps.mean())


@dataclass
class Prediction:
    reps: int
    source: str
    signal: np.ndarray
    peaks: np.ndarray
    t: np.ndarray


def predict(rec: SetRecording) -> Prediction:
    df, fs = rec.df, rec.fs
    trim = int(TRIM_SEC * fs)
    if len(df) > 2 * trim + int(2 * fs):
        df = df.iloc[trim:-trim]
    t = df["t"].to_numpy()

    candidates = {
        "gravity": first_pc(lowpass(df[["grav_x", "grav_y", "grav_z"]].to_numpy(), fs)),
        "acc": first_pc(lowpass(df[["acc_x", "acc_y", "acc_z"]].to_numpy(), fs)),
    }
    scored = {k: periodicity(v, fs) for k, v in candidates.items()}
    source = max(scored, key=lambda k: scored[k][0])
    period = scored[source][1]
    base = candidates[source]

    # PCA 方向係正定負冇意義，兩邊都數，揀節奏最平均嗰邊
    best = None
    for sig in (base, -base):
        p = count_peaks(sig, fs, period)
        if best is None or regularity(p) < regularity(best[1]):
            best = (sig, p)
    sig, peaks = best
    return Prediction(len(peaks), source, sig, peaks, t)


# ---------- 假數據（測試用） ----------

def make_demo(folder: Path, seed: int = 7) -> None:
    rng = np.random.default_rng(seed)
    folder.mkdir(parents=True, exist_ok=True)
    fs = 50
    # (動作, 主要訊號, 訊號強度)
    profiles = [("bicep_curl", "gravity", 1.0), ("shoulder_press", "gravity", 0.6),
                ("bench_press", "acc", 0.25), ("squat", "acc", 0.06)]
    n = 0
    for exercise, kind, amp in profiles:
        for _ in range(12):
            reps = int(rng.integers(5, 16))
            rep_sec = rng.uniform(1.6, 3.0)
            idle = 1.5
            # 每一下快慢都唔同（真人唔係機械人）
            durations = rep_sec * rng.uniform(0.8, 1.2, reps)
            phase = np.concatenate([np.linspace(0, 2 * np.pi, int(d * fs), endpoint=False)
                                    for d in durations])
            motion = np.concatenate([np.zeros(int(idle * fs)),
                                     (1 - np.cos(phase)) / 2,   # 0 → 1 → 0 = 一下
                                     np.zeros(int(idle * fs))])
            # 撳掣嗰下嘅抖動
            motion[:15] += rng.normal(0, 0.3, 15)
            motion[-15:] += rng.normal(0, 0.3, 15)
            m = len(motion)
            t = np.arange(m) / fs
            angle = (amp * motion * 1.4) if kind == "gravity" else np.zeros(m)
            grav = np.stack([np.sin(angle), -np.cos(angle), np.zeros(m)], axis=1)
            acc = np.zeros((m, 3))
            if kind == "acc":
                acc[:, 2] = amp * np.gradient(np.gradient(motion)) * fs * fs / 40
            else:
                acc[:, 0] = 0.1 * amp * np.gradient(motion) * fs
            grav += rng.normal(0, 0.03, grav.shape)
            acc += rng.normal(0, 0.04, acc.shape)
            rot = rng.normal(0, 0.1, (m, 3))
            df = pd.DataFrame(np.column_stack([t, acc, grav, rot]),
                              columns=["t", "acc_x", "acc_y", "acc_z", "grav_x", "grav_y",
                                       "grav_z", "rot_x", "rot_y", "rot_z"])
            path = folder / f"demo-{n:03d}_{exercise}_{reps}reps.csv"
            header = (f"# exercise={exercise}\n# true_reps={reps}\n"
                      f"# sample_rate_hz={fs}\n# recorded_at=demo\n")
            path.write_text(header + df.to_csv(index=False, float_format="%.5f"))
            n += 1
    print(f"生成咗 {n} 組假數據 → {folder}")


# ---------- 主程式 ----------

def plot(rec: SetRecording, pred: Prediction, out: Path) -> None:
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    ok = pred.reps == rec.true_reps
    fig, ax = plt.subplots(figsize=(9, 3))
    ax.plot(pred.t, pred.signal, lw=1.2, color="#3b6fb6")
    ax.plot(pred.t[pred.peaks], pred.signal[pred.peaks], "o", color="#d1495b")
    ax.set_title(f"{rec.exercise} | true {rec.true_reps} / predicted {pred.reps} "
                 f"({pred.source}) {'OK' if ok else 'MISS'}", fontsize=10)
    ax.set_xlabel("seconds")
    ax.spines[["top", "right"]].set_visible(False)
    fig.tight_layout()
    fig.savefig(out, dpi=110)
    plt.close(fig)


def main() -> int:
    ap = argparse.ArgumentParser(description="MaxGym baseline rep counter")
    ap.add_argument("data", nargs="?", type=Path, help="放 CSV 嘅資料夾")
    ap.add_argument("--demo", action="store_true", help="用假數據試")
    ap.add_argument("--out", type=Path, default=Path("results"))
    ap.add_argument("--no-plots", action="store_true")
    args = ap.parse_args()

    if args.demo:
        args.data = Path("data_demo")
        make_demo(args.data)
    if args.data is None or not args.data.exists():
        ap.error("請俾一個資料夾，或者用 --demo")

    files = sorted(args.data.glob("*.csv"))
    if not files:
        print(f"{args.data} 入面冇 CSV")
        return 1

    plots = args.out / "plots"
    plots.mkdir(parents=True, exist_ok=True)
    rows = []
    for path in files:
        rec = load_set(path)
        pred = predict(rec)
        rows.append({"file": path.name, "exercise": rec.exercise,
                     "true_reps": rec.true_reps, "predicted": pred.reps,
                     "error": pred.reps - rec.true_reps, "signal_used": pred.source})
        if not args.no_plots:
            plot(rec, pred, plots / f"{path.stem}.png")

    res = pd.DataFrame(rows)
    res.to_csv(args.out / "results.csv", index=False)
    summary = (res.assign(abs_err=res.error.abs(), exact=res.error.eq(0))
               .groupby("exercise")
               .agg(sets=("file", "count"), MAE=("abs_err", "mean"),
                    exact_rate=("exact", "mean"), bias=("error", "mean"))
               .round(2).sort_values("MAE"))
    summary.to_csv(args.out / "summary.csv")

    print("\n每個動作（MAE = 平均差幾多下；exact_rate = 完全數啱嘅比例；bias 正數 = 數多咗）")
    print(summary.to_string())
    print(f"\n全部：MAE {res.error.abs().mean():.2f} 下，完全命中 {res.error.eq(0).mean():.0%}")
    print(f"結果 → {args.out.resolve()}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
