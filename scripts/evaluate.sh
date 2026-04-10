#!/bin/bash
# Evaluation script for AMtown02 ORB-SLAM3 results
source /opt/ros/noetic/setup.bash
cd /root/ORB_SLAM3

echo "=========================================="
echo "  AMtown02 ORB-SLAM3 Evaluation Results"
echo "=========================================="

# Check trajectory file
if [ ! -f CameraTrajectory.txt ]; then
    echo "ERROR: CameraTrajectory.txt not found!"
    exit 1
fi

TRAJ_LINES=$(wc -l < CameraTrajectory.txt)
GT_LINES=$(wc -l < ground_truth.txt)
echo ""
echo "Trajectory lines: $TRAJ_LINES"
echo "Ground truth lines: $GT_LINES"
echo ""

# ATE RMSE
echo "--- ATE RMSE (Sim3 aligned, scale corrected) ---"
evo_ape tum ground_truth.txt CameraTrajectory.txt \
    --align --correct_scale \
    --t_max_diff 0.1 -va 2>&1

echo ""
echo "--- RPE Translation Drift (delta=10m, distance) ---"
evo_rpe tum ground_truth.txt CameraTrajectory.txt \
    --align --correct_scale \
    --t_max_diff 0.1 \
    --delta 10 --delta_unit m \
    --pose_relation trans_part -va 2>&1

echo ""
echo "--- RPE Rotation Drift (delta=10m, distance) ---"
evo_rpe tum ground_truth.txt CameraTrajectory.txt \
    --align --correct_scale \
    --t_max_diff 0.1 \
    --delta 10 --delta_unit m \
    --pose_relation angle_deg -va 2>&1

echo ""
echo "=========================================="
echo "  Done! Compare with baseline:"
echo "  ATE RMSE: 88.2281 m"
echo "  RPE Trans Drift: 2.04084 m/m"
echo "  RPE Rot Drift: 76.69911 deg/100m"
echo "  Completeness: 95.73%"
echo "=========================================="
