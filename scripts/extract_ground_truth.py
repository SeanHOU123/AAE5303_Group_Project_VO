#!/usr/bin/env python3
"""Extract RTK ground truth from AMtown02.bag and convert to TUM format."""
import rosbag
import numpy as np

bag = rosbag.Bag('/data/AMtown02.bag')
rtk_data = []

for topic, msg, t in bag.read_messages(topics=['/dji_osdk_ros/rtk_position']):
    timestamp = msg.header.stamp.to_sec()
    lat, lon, alt = msg.latitude, msg.longitude, msg.altitude
    rtk_data.append([timestamp, lat, lon, alt])

bag.close()
rtk_data = np.array(rtk_data)
print(f"Total RTK poses: {len(rtk_data)}")
print(f"Time range: {rtk_data[0,0]:.3f} - {rtk_data[-1,0]:.3f}")
print(f"Duration: {rtk_data[-1,0] - rtk_data[0,0]:.1f}s")

lat0, lon0, alt0 = rtk_data[0, 1], rtk_data[0, 2], rtk_data[0, 3]
R = 6378137.0

x = R * np.radians(rtk_data[:, 2] - lon0) * np.cos(np.radians(lat0))
y = R * np.radians(rtk_data[:, 1] - lat0)
z = rtk_data[:, 3] - alt0

with open('/root/ORB_SLAM3/ground_truth.txt', 'w') as f:
    for i in range(len(rtk_data)):
        f.write(f"{rtk_data[i,0]:.6f} {x[i]:.6f} {y[i]:.6f} {z[i]:.6f} 0 0 0 1\n")

print(f"Saved {len(rtk_data)} ground truth poses to /root/ORB_SLAM3/ground_truth.txt")
print(f"X range: [{x.min():.2f}, {x.max():.2f}] m")
print(f"Y range: [{y.min():.2f}, {y.max():.2f}] m")
print(f"Z range: [{z.min():.2f}, {z.max():.2f}] m")
