# Part 1 Results (ORB-SLAM3, AMtown02)

This file records the final Visual Odometry results for AAE5303 Part 1.

## Run Setup

- Method: ORB-SLAM3 Monocular VO
- Dataset: MARS-LVIG AMtown02
- Estimated trajectory: `CameraTrajectory.txt` (TUM format)
- Ground truth: RTK + attitude extracted to TUM format
- Evaluation protocol: Sim(3) alignment + `correct_scale`, `t_max_diff=0.1s`
- RPE delta: 10 m (distance-domain)
- Image preprocessing: CLAHE (clipLimit=3.0, gridSize=8×8)
- Playback rate: 0.75x

## Metrics

- ATE RMSE (m): `10.646227`
- RPE Trans Drift (m/m): `1.406900`
- RPE Rot Drift (deg/100m): `42.670000`
- Completeness (%): `94.506667`

## Trajectory Stats

- Estimated poses: `3776`
- Ground-truth poses: `3750`
- Matched poses: `3544`

## Configuration Summary

- `ORBextractor.nFeatures`: 5000
- `ORBextractor.scaleFactor`: 1.2
- `ORBextractor.nLevels`: 12
- `ORBextractor.iniThFAST`: 8
- `ORBextractor.minThFAST`: 3
- `Camera.RGB`: 0 (BGR)
- CLAHE: Enabled

## Notes

- Leaderboard JSON is provided at: `leaderboard/GOGOGO_Leaderboard.json`
- This is the v2 optimized run, selected for best ATE RMSE (50% leaderboard weight).
- Four versions were tested; see `docs/EXPERIMENT_LOG.md` for full optimization history.
- Key code modifications: `System.cc` patched to allow monocular `SaveTrajectoryTUM`, `ros_mono_compressed.cc` extended with CLAHE support.
