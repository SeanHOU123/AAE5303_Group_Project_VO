# ORB-SLAM3 AMtown02 Optimization Experiment Log

## Project Information
- **Course**: AAE5303 Robust Control Technology in Low-Altitude Aerial Vehicle
- **Task**: Visual Odometry (ORB-SLAM3) Leaderboard
- **Dataset**: MARS-LVIG AMtown02 (DJI M300 RTK, Rural Town, 8 m/s, 80 m altitude)
- **Leaderboard**: https://qian9921.github.io/leaderboard_web/
- **Docker Image**: `liangyu99/orbslam3_ros1:latest`
- **Bag File**: `AMtown02.bag` (16.5 GB, 749 s, 7499 frames @ 10 fps)

## Evaluation Metrics (Total Score = ATE×50% + RPE_Trans×20% + Completeness×30%)
| Metric | Direction | Unit | Description |
|--------|-----------|------|-------------|
| ATE RMSE | Lower is better | m | Global accuracy after Sim(3) alignment (50% weight) |
| RPE Trans Drift | Lower is better | m/m | Translation drift rate, delta=10 m (20% weight) |
| RPE Rot Drift | Lower is better | deg/100m | Rotation drift rate, delta=10 m |
| Completeness | Higher is better | % | Matched poses / total GT poses (30% weight) |

## Baseline (Published on Leaderboard)
| ATE RMSE | RPE Trans | RPE Rot | Completeness |
|----------|-----------|---------|--------------|
| 88.2281 m | 2.04084 m/m | 76.699 deg/100m | 95.73% |

---

## Experiment v1: Mono + CLAHE + Basic Tuning

### Modifications
1. **Fixed Camera.RGB**: Changed from 1 (RGB) to **0 (BGR)** — `cv::imdecode` outputs BGR
2. **Fixed SaveTrajectoryTUM**: Patched `System.cc` to bypass the monocular-mode restriction, enabling full-frame `CameraTrajectory.txt` output
3. **Enabled CLAHE**: Contrast Limited Adaptive Histogram Equalization (clipLimit=3.0, gridSize=8×8)
4. **Increased ORB Features**: nFeatures from 1500 → **3000**
5. **Lowered FAST Thresholds**: iniThFAST 20→**12**, minThFAST 7→**4**
6. **Increased Pyramid Levels**: nLevels 8→**12**

### Configuration
```yaml
Camera.RGB: 0
ORBextractor.nFeatures: 3000
ORBextractor.scaleFactor: 1.2
ORBextractor.nLevels: 12
ORBextractor.iniThFAST: 12
ORBextractor.minThFAST: 4
```

### Runtime Settings
- Mode: Monocular + CLAHE
- Playback rate: 1.0x
- Viewer: Enabled (Xvfb virtual display)

### Results
| Metric | Value | vs Baseline |
|--------|-------|-------------|
| ATE RMSE | **17.155 m** | ↓ 80.6% |
| RPE Trans Drift | **1.362 m/m** | ↓ 33.2% |
| RPE Rot Drift | **41.82 deg/100m** | ↓ 45.5% |
| Completeness | **90.05%** (3377/3750) | ↓ 5.7 pp |
| Trajectory Frames | 3377/7499 (45% tracking rate) | — |
| Loop Closure | 1 detected | — |

### Analysis
- RPE Trans already approaching leaderboard #1 (1.34 m/m)
- ATE still high, mainly due to large deviations in certain regions (max=37.78 m)
- Completeness is low (90.05%), many frames marked as lost
- Need to improve tracking robustness

---

## Experiment v2: Aggressive Feature Extraction ★ Final Submission

### Modifications (relative to v1)
1. **nFeatures**: 3000 → **5000** (more feature points)
2. **iniThFAST**: 12 → **8** (lower threshold to detect weak features)
3. **minThFAST**: 4 → **3**
4. **Viewer**: Disabled (faster processing)
5. **Playback rate**: 1.0x → **0.75x** (reduce frame drops)

### Configuration
```yaml
Camera.RGB: 0
ORBextractor.nFeatures: 5000
ORBextractor.scaleFactor: 1.2
ORBextractor.nLevels: 12
ORBextractor.iniThFAST: 8
ORBextractor.minThFAST: 3
```

### Runtime Settings
- Mode: Monocular + CLAHE
- Playback rate: 0.75x
- Viewer: Disabled
- Commands:
```bash
./Examples_old/ROS/ORB_SLAM3/Mono_Compressed \
    Vocabulary/ORBvoc.txt \
    Examples/Monocular/AMtown02_Mono_v2.yaml true
rosbag play /data/AMtown02.bag \
    /left_camera/image/compressed:=/camera/image_raw/compressed --rate 0.75
```

### Results
| Metric | Value | vs v1 | vs Baseline |
|--------|-------|-------|-------------|
| ATE RMSE | **10.646 m** | ↓ 37.9% | ↓ 87.9% |
| RPE Trans Drift | **1.407 m/m** | ↑ 3.3% | ↓ 31.1% |
| RPE Rot Drift | **42.67 deg/100m** | ≈ same | ↓ 44.4% |
| Completeness | **94.51%** (3544/3750) | ↑ 4.5 pp | ↓ 1.2 pp |
| Trajectory Frames | 3776/7499 (50% tracking rate) | ↑ 5 pp | — |
| Loop Closure | Map Merge ×1 | — | — |
| Scale Factor | 2.204 | — | — |

### Analysis
- **ATE significantly reduced**: 17.16 → 10.65 (↓37.9%), more features + 0.75x rate improved tracking stability
- **Completeness improved**: 90.05% → 94.51%, approaching baseline 95.73%
- **RPE Trans slightly worse**: 1.36 → 1.41, possibly due to noisy matches from excessive features
- **Map Merge**: Successfully merged two sub-maps, improving global consistency
- **Selection rationale**: ATE RMSE accounts for 50% of the leaderboard score; v2 achieves the best ATE among all versions

---

## Experiment v3: Balanced Parameters + 0.5x Rate

### Modifications (relative to v2)
1. **nFeatures**: 5000 → **4000** (compromise to reduce noisy matches)
2. **iniThFAST**: 8 → **10** (midpoint between v1=12 and v2=8)
3. **Playback rate**: 0.75x → **0.5x** (maximum processing time per frame)

### Configuration
```yaml
Camera.RGB: 0
ORBextractor.nFeatures: 4000
ORBextractor.scaleFactor: 1.2
ORBextractor.nLevels: 12
ORBextractor.iniThFAST: 10
ORBextractor.minThFAST: 3
```

### Runtime Settings
- Mode: Monocular + CLAHE
- Playback rate: 0.5x
- Viewer: Disabled

### Results
| Metric | Value | vs v2 | vs Baseline |
|--------|-------|-------|-------------|
| ATE RMSE | **15.769 m** | ↑ 48.1% | ↓ 82.1% |
| RPE Trans Drift | **1.354 m/m** | ↓ 3.8% | ↓ 33.7% |
| RPE Rot Drift | **41.08 deg/100m** | ↓ 3.7% | ↓ 46.5% |
| Completeness | **98.08%** (3678/3750) | ↑ 3.6 pp | ↑ 2.4 pp |
| Trajectory Frames | 6278/7499 (83.7% tracking rate) | ↑ 33.7 pp | — |
| Loop Closure | Map Merge ×1 | — | — |
| Scale Factor | 1.301 (much more reasonable than v2's 2.204) | — | — |

### Analysis
- **Completeness dramatically improved**: 94.51% → **98.08%**, exceeding most leaderboard entries
- **Best RPE Trans**: 1.354 m/m, closest to leaderboard #1 (1.336)
- **ATE worsened**: 10.65 → 15.77, likely because more tracked frames include poorly-estimated regions
- **0.5x rate** was the key improvement — tracking rate jumped from 50% to 83.7%

---

## Experiment v4: v2 Config + 0.5x Rate (Hybrid Strategy)

### Modifications (relative to v3)
- Used v2 configuration (5000 features, FAST 8/3) with 0.5x slow playback rate
- Goal: combine v2's high ATE accuracy with v3's high Completeness

### Configuration
```yaml
Camera.RGB: 0
ORBextractor.nFeatures: 5000
ORBextractor.scaleFactor: 1.2
ORBextractor.nLevels: 12
ORBextractor.iniThFAST: 8
ORBextractor.minThFAST: 3
```

### Runtime Settings
- Mode: Monocular + CLAHE
- Playback rate: 0.5x
- Viewer: Disabled

### Results
| Metric | Value | vs v2 | vs v3 | vs Baseline |
|--------|-------|-------|-------|-------------|
| ATE RMSE | **14.932 m** | ↑ 40.3% | ↓ 5.3% | ↓ 83.1% |
| RPE Trans Drift | **1.384 m/m** | ↓ 1.6% | ↑ 2.2% | ↓ 32.2% |
| RPE Rot Drift | **38.47 deg/100m** | ↓ 9.8% | ↓ 6.4% | ↓ 49.8% |
| Completeness | **98.61%** (3698/3750) | ↑ 4.1 pp | ↑ 0.5 pp | ↑ 2.9 pp |

### Analysis
- **Highest Completeness**: 98.61%, best across all versions
- **Lowest RPE Rot**: 38.47 deg/100m, best rotational drift control
- **ATE still higher than v2**: Confirms that 0.5x rate improves tracking coverage but introduces more drifted regions into evaluation
- Validates the hybrid strategy partially, but ATE cannot surpass v2

---

## Results Summary

| Version | ATE RMSE (m) | RPE Trans (m/m) | RPE Rot (deg/100m) | Completeness (%) | Key Changes |
|---------|-------------|-----------------|---------------------|-------------------|-------------|
| Baseline | 88.228 | 2.041 | 76.70 | 95.73 | Default parameters |
| **v1** | 17.155 | 1.362 | 41.82 | 90.05 | BGR fix, CLAHE, 3000 feat, 1.0x |
| **v2** ★ | **10.646** | 1.407 | 42.67 | 94.51 | 5000 feat, FAST 8/3, 0.75x |
| **v3** | 15.769 | **1.354** | 41.08 | 98.08 | 4000 feat, FAST 10/3, 0.5x |
| **v4** | 14.932 | 1.384 | **38.47** | **98.61** | v2 config + 0.5x rate |
| Leaderboard #1 | 1.741 | 1.336 | — | 94.99 | (reference target) |

★ **v2 selected as final submission** — Best ATE RMSE (50% leaderboard weight)

## Final Submission Rationale

Under the weighted scoring formula `Total Score = ATE×50% + RPE_Trans×20% + Completeness×30%`:

- **v2's ATE (10.646 m)** is far superior to v3 (15.769 m) and v4 (14.932 m)
- **v2's Completeness (94.51%)** is only 3–4 pp below v3/v4
- **v2's RPE Trans (1.407)** is close to the best (v3's 1.354)
- Overall weighted score is expected to be highest for v2

---

## Code Modification Record

### System.cc — Bypass Monocular SaveTrajectoryTUM Restriction
```cpp
// Original (line 572):
if(mSensor==MONOCULAR)
// Patched to:
if(false && mSensor==MONOCULAR)
```
**Reason**: ORB-SLAM3 blocks full-frame trajectory saving in monocular mode by default, but the leaderboard requires `CameraTrajectory.txt`.

### ros_mono_compressed.cc — Key Modifications
1. Added `SaveTrajectoryTUM("CameraTrajectory.txt")` after `SLAM.Shutdown()` to save full-frame trajectory
2. Added CLAHE preprocessing support (enabled via 3rd argument `true`)
3. Viewer set to `false` (disabled visualization to save computation)

---

## Reproduction Steps

See `scripts/run_experiment.sh` for the full automation script.

```bash
# Inside Docker container
docker run -it --name AMtown02_Run -v D:\:/data liangyu99/orbslam3_ros1:latest bash

# Run v2 experiment
bash /data/liangyun99/Hand_off/scripts/run_experiment.sh v2 0.75
```
