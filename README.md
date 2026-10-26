# MaxGym — 第一步：收集數據

呢個 app **未會自動數 rep**。佢做嘅係更重要嘅事：錄低你每一組嘅手腕動作 + 你輸入嘅真實次數。
冇呢啲「有答案嘅數據」，之後任何演算法都冇辦法訓練同評分。

```
Apple Watch（錄動作）──自動傳──▶ iPhone（收集 CSV）──AirDrop──▶ Mac（Python 分析）
```

---

## A. 一次性準備（約 1 小時，大部分時間係等下載）

1. **裝 Xcode**：Mac App Store 搜 Xcode，免費，好大（10GB+）。裝完開一次，佢問要唔要裝 watchOS platform → 要。
2. **裝 XcodeGen**（將 `project.yml` 變成 Xcode project 嘅工具）：
   ```bash
   # 未有 Homebrew 先裝：https://brew.sh
   brew install xcodegen
   ```
3. **加 Apple ID**：Xcode → Settings → Accounts → `+` → 登入你個 Apple ID。

## B. 生成 project 同裝落手機 / 手錶

```bash
cd "/Users/masashi/my project/Xcode/MaxGym"
xcodegen            # 生成 MaxGym.xcodeproj
open MaxGym.xcodeproj
```

喺 Xcode：
1. 左邊撳藍色 **MaxGym** project → 揀 target **MaxGym** → Signing & Capabilities → Team 揀你個名（Personal Team）。
2. target **MaxGymWatch** 都做一次。
3. 如果話 bundle ID 用唔到：打開 `project.yml`，將 `com.kenlip` 改做其他（例如 `com.kenlip2026`），全部三處都要改，再跑一次 `xcodegen`。
4. iPhone 用 USB 插 Mac。iPhone：設定 → 私隱與安全性 → **開發者模式** → 開（會重啟）。Apple Watch 都要開開發者模式（Watch 設定 → 私隱與安全性）。
5. 上面揀 scheme **MaxGymWatch** + 你隻 Apple Watch → 撳 ▶︎。第一次會好慢（幾分鐘），手錶要解鎖、放近 iPhone。
6. 第一次開，手錶會問 HealthKit 同動作權限 → 全部允許。

> **免費帳戶限制**：app 7 日後會失效，再插 Mac 撳 ▶︎ 就得。想長期用或者俾人試（TestFlight），先需要付費嘅 Apple Developer Program。作品集階段，免費已經夠。

## C. 去 gym 收集數據（呢步最重要）

每組：揀動作 → **開始** → 做 → **停止** → 轉錶冠輸入**真實次數** → **保存**

**收集規則**（違反咗數據就冇用）：
- **錶戴喺同一隻手、同一個位置**，每次都一樣
- 開始之後**停一秒先做**，做完**停一秒先撳停止**
- 次數要**故意變化**：有啲組 5 下、有啲 12 下、有啲 15 下（唔好次次都 10 下，否則模型會學識「估 10」）
- 真實次數**一定要入啱**。唔肯定就撳「捨棄」
- 目標：**每個動作 ≥ 15 組**，iPhone 畫面會用綠色話你知夠未

## D. 分析

1. iPhone 開 MaxGym → 右上角「分享全部」→ AirDrop 去 Mac → 放入 `data/`
2. ```bash
   cd analysis
   pip install -r requirements.txt
   python count_reps.py --demo        # 先用假數據試一次，確認環境 OK
   python count_reps.py ../data/      # 分析你真正嘅數據
   ```
3. 睇 `results/summary.csv` 同 `results/plots/`——**錯嘅組一定要開圖睇**，咁先知點解錯。

### 假數據跑出嚟嘅結果（用嚟理解，唔係真實表現）

| 動作 | MAE（平均差幾下） | 完全命中 |
|---|---|---|
| 二頭彎舉 | 0.25 | 75% |
| 肩推 | 0.67 | 33% |
| 卧推 | 2.33 | 17% |
| 深蹲 | 3.17 | 17% |

**點解卧推會數多？** 卧推手腕角度唔變，只可以靠加速度。但加速度喺「推上去」同「放落嚟」各有一個山頂——一下動作有兩個山頂，所以數多咗。
解決方向：改用速度（加速度積分）或者位移，或者直接訓練機器學習模型。**呢個就係你 report 入面最好講嘅一段。**

---

## 用 Claude Code 繼續開發

喺 `my project/Xcode/MaxGym` 資料夾開 Claude Code，可以直接叫佢：
- 「跑 `xcodegen` 再用 `xcodebuild` build 個 watch target，有 error 幫我改」
- 「讀 `data/` 入面卧推嗰幾組，幫我改善 `count_reps.py` 嘅演算法」

Xcode 26.3 之後亦可以喺 Xcode 入面直接用 Claude（Settings → Intelligence）。

## 檔案結構

```
MaxGym/
├── project.yml          XcodeGen 設定（取代手動設定 Xcode）
├── Watch/               Apple Watch app
│   ├── MotionRecorder   每秒 50 次讀感應器
│   ├── WorkoutManager   開「體能訓練」，令落手腕都繼續錄
│   ├── SetStore         存 CSV + 傳去 iPhone
│   └── *View            畫面
├── iOS/                 iPhone app：收檔、統計、分享
└── analysis/
    └── count_reps.py    基準版計數 + 評分
```

## 下一步路線

1. ✅ 收集數據（呢個 app）
2. ⬜ 改善演算法，目標：手臂動作 MAE < 0.5
3. ⬜ 用 Create ML 訓練模型，同 baseline 比較（有比較先有說服力）
4. ⬜ 將計數放返入 watch：即時數、每下震一震
