# VO Parameter Optimization Notes (AMtown02)

This document records the parameter optimization route and rationale for the final Part 1 VO result.

## 1) Fixed Baseline Requirements

- Framework: ORB-SLAM3 Monocular mode
- Dataset: MARS-LVIG AMtown02 (DJI M300 RTK, Rural Town, 8m/s, 80m altitude)
- Output trajectory: `CameraTrajectory.txt` (TUM format)
- Evaluation: Sim(3) alignment + scale correction, RPE delta=10m
- Docker: `liangyu99/orbslam3_ros1:latest`

## 2) Problems Identified in Default Configuration

### 2.1 Camera.RGB Setting
The default YAML had `Camera.RGB: 1` (RGB mode), but `cv::imdecode` outputs BGR. This mismatch caused color channel confusion in ORB feature extraction, leading to suboptimal feature matching.

**Fix**: Set `Camera.RGB: 0` (BGR)

### 2.2 SaveTrajectoryTUM Restriction
ORB-SLAM3 `System.cc` line 572 blocks `SaveTrajectoryTUM()` for monocular mode, only allowing `SaveKeyFrameTrajectoryTUM()`. The leaderboard requires full-frame `CameraTrajectory.txt`.

**Fix**: Patched `System.cc` to bypass the monocular check:
```cpp
// Original:  if(mSensor==MONOCULAR)
// Patched:   if(false && mSensor==MONOCULAR)
```

### 2.3 Image Quality
AMtown02 is a rural aerial dataset at 80m altitude. Default ORB parameters (`nFeatures=1500`) extracted too few features from the relatively homogeneous terrain.

**Fix**: Applied CLAHE preprocessing + increased feature count

## 3) Optimization Strategy

### Phase 1: Foundation Fixes (v1)
- BGR color fix
- CLAHE image enhancement
- Feature count: 1500 → 3000
- FAST thresholds: 20/7 → 12/4
- Pyramid levels: 8 → 12

### Phase 2: Aggressive Feature Extraction (v2 — Final)
- Feature count: 3000 → **5000**
- FAST thresholds: 12/4 → **8/3**
- Playback rate: 1.0x → **0.75x** (more processing time per frame)
- Viewer disabled for computation savings

### Phase 3: Completeness Focus (v3)
- Feature count: 5000 → 4000 (reduce noise)
- FAST thresholds: 8/3 → 10/3 (moderate)
- Playback rate: 0.75x → **0.5x**

### Phase 4: Hybrid (v4)
- v2 config (5000 features, FAST 8/3) + 0.5x rate

## 4) Effective Final Settings (v2)

From `configs/AMtown02_Mono_v2.yaml`:

| Parameter | Default | v2 (Final) | Rationale |
|-----------|---------|------------|-----------|
| `Camera.RGB` | 1 | **0** | BGR output from cv::imdecode |
| `ORBextractor.nFeatures` | 1500 | **5000** | More features for aerial scenes |
| `ORBextractor.scaleFactor` | 1.2 | 1.2 | Unchanged |
| `ORBextractor.nLevels` | 8 | **12** | Better multi-scale detection |
| `ORBextractor.iniThFAST` | 20 | **8** | Detect weak features |
| `ORBextractor.minThFAST` | 7 | **3** | Fallback for low-texture regions |
| CLAHE | Off | **On** | Contrast enhancement |
| Playback Rate | 1.0x | **0.75x** | Prevent frame drops |

## 5) Version Selection Rationale

| Version | ATE RMSE (m) | RPE Trans (m/m) | Completeness (%) |
|---------|-------------|-----------------|-------------------|
| v1 | 17.155 | 1.362 | 90.05 |
| **v2** ★ | **10.646** | 1.407 | 94.51 |
| v3 | 15.769 | 1.354 | 98.08 |
| v4 | 14.932 | 1.384 | 98.61 |

**v2 was selected** because:
- **Best ATE RMSE** at 10.646m (50% of total score)
- Competitive Completeness at 94.51% (30% weight)
- RPE Trans at 1.407 is close to the best (v3's 1.354) (20% weight)
- Under the weighted scoring formula, v2 yields the highest expected total score

## 6) Link to Outputs

- `output/PART1_AMtown02_results.md`
- `leaderboard/GOGOGO_Leaderboard.json`
- `output/evaluation_report.json`
- `docs/EXPERIMENT_LOG.md` — full experiment history
