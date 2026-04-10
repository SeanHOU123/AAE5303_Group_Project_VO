#!/bin/bash
#================================================================
# ORB-SLAM3 AMtown02 实验运行脚本
# 用法: 在 Docker 容器内执行
# docker run -it --name orbslam_run -v D:\:/data liangyu99/orbslam3_ros1:latest bash
# 然后在容器内: bash /data/liangyun99/project/scripts/run_experiment.sh <版本号>
#================================================================

VERSION=${1:-"v1"}
RATE=${2:-"0.75"}
BAG_PATH="/data/AMtown02.bag"
SLAM_DIR="/root/ORB_SLAM3"

echo "================================================"
echo "  ORB-SLAM3 AMtown02 实验 - $VERSION"
echo "  播放速率: ${RATE}x"
echo "================================================"

# ---- 0. 选择配置文件 ----
case $VERSION in
    v1) CONFIG="Examples/Monocular/AMtown02_Mono.yaml" ;;
    v2) CONFIG="Examples/Monocular/AMtown02_Mono_v2.yaml" ;;
    *)  CONFIG="Examples/Monocular/AMtown02_Mono_${VERSION}.yaml" ;;
esac

echo "配置文件: $CONFIG"

# ---- 1. 环境准备 ----
source /opt/ros/noetic/setup.bash
cd $SLAM_DIR
rm -f CameraTrajectory.txt KeyFrameTrajectory.txt

# ---- 2. 启动 roscore ----
echo "[1/4] 启动 roscore..."
roscore &
ROSCORE_PID=$!
sleep 3

# ---- 3. 提取 Ground Truth (如果不存在) ----
if [ ! -f ground_truth.txt ]; then
    echo "[2/4] 提取 ground truth..."
    python3 /data/liangyun99/project/scripts/extract_ground_truth.py
else
    echo "[2/4] Ground truth 已存在，跳过"
fi

# ---- 4. 启动 SLAM ----
echo "[3/4] 启动 ORB-SLAM3 (Mono + CLAHE)..."
./Examples_old/ROS/ORB_SLAM3/Mono_Compressed \
    Vocabulary/ORBvoc.txt $CONFIG true &
SLAM_PID=$!
sleep 15
echo "SLAM PID: $SLAM_PID, 词汇表加载完成"

# ---- 5. 播放 Bag ----
echo "[4/4] 播放 bag (${RATE}x 速率)..."
rosbag play $BAG_PATH \
    /left_camera/image/compressed:=/camera/image_raw/compressed \
    --rate $RATE
echo "Bag 播放完毕"

# ---- 6. 等待并保存 ----
sleep 5
kill -2 $SLAM_PID
sleep 10

echo ""
echo "================================================"
echo "  运行完成!"
echo "================================================"

if [ -f CameraTrajectory.txt ]; then
    LINES=$(wc -l < CameraTrajectory.txt)
    GT_LINES=$(wc -l < ground_truth.txt)
    echo "CameraTrajectory.txt: $LINES 行"
    echo "ground_truth.txt:     $GT_LINES 行"
    echo ""

    echo "---- ATE RMSE ----"
    evo_ape tum ground_truth.txt CameraTrajectory.txt \
        --align --correct_scale --t_max_diff 0.1 -v 2>&1 | grep -E "rmse|mean|Found"

    echo ""
    echo "---- RPE Translation ----"
    evo_rpe tum ground_truth.txt CameraTrajectory.txt \
        --align --correct_scale --t_max_diff 0.1 \
        --delta 10 --delta_unit m --pose_relation trans_part -v 2>&1 | grep -E "mean|Found"

    echo ""
    echo "---- RPE Rotation ----"
    evo_rpe tum ground_truth.txt CameraTrajectory.txt \
        --align --correct_scale --t_max_diff 0.1 \
        --delta 10 --delta_unit m --pose_relation angle_deg -v 2>&1 | grep -E "mean|Found"

    echo ""
    echo "==== Leaderboard 指标 ===="
    echo "请手动计算:"
    echo "  RPE Trans Drift (m/m) = RPE_trans_mean / 10"
    echo "  RPE Rot Drift (deg/100m) = (RPE_rot_mean / 10) * 100"
    echo "  Completeness (%) = matched_poses / $GT_LINES * 100"
else
    echo "ERROR: CameraTrajectory.txt 未生成!"
fi

kill $ROSCORE_PID 2>/dev/null
echo "Done."
