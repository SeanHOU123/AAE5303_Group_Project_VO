/**
* Modified Mono Compressed node for ORB-SLAM3
* Supports CompressedImage + saves CameraTrajectory.txt (full-frame)
* With optional CLAHE preprocessing
*/

#include<iostream>
#include<algorithm>
#include<fstream>
#include<chrono>

#include<ros/ros.h>
#include <cv_bridge/cv_bridge.h>
#include <sensor_msgs/CompressedImage.h>

#include<opencv2/core/core.hpp>
#include<opencv2/imgcodecs.hpp>
#include<opencv2/imgproc.hpp>

#include"../../../include/System.h"

using namespace std;

class ImageGrabber
{
public:
    ImageGrabber(ORB_SLAM3::System* pSLAM, bool bClahe):mpSLAM(pSLAM), mbClahe(bClahe){}

    void GrabCompressedImage(const sensor_msgs::CompressedImageConstPtr& msg);

    ORB_SLAM3::System* mpSLAM;
    bool mbClahe;
    cv::Ptr<cv::CLAHE> mClahe = cv::createCLAHE(3.0, cv::Size(8, 8));
};

int main(int argc, char **argv)
{
    ros::init(argc, argv, "Mono");
    ros::start();

    if(argc < 3 || argc > 4)
    {
        cerr << endl << "Usage: rosrun ORB_SLAM3 Mono_Compressed path_to_vocabulary path_to_settings [do_equalize]" << endl;
        ros::shutdown();
        return 1;
    }

    bool bEqual = false;
    if(argc == 4)
    {
        string sbEqual(argv[3]);
        if(sbEqual == "true")
            bEqual = true;
    }

    ORB_SLAM3::System SLAM(argv[1],argv[2],ORB_SLAM3::System::MONOCULAR,false);

    ImageGrabber igb(&SLAM, bEqual);

    ros::NodeHandle nodeHandler;
    ros::Subscriber sub = nodeHandler.subscribe("/camera/image_raw/compressed", 1, &ImageGrabber::GrabCompressedImage,&igb);

    ros::spin();

    SLAM.Shutdown();

    SLAM.SaveTrajectoryTUM("CameraTrajectory.txt");
    SLAM.SaveKeyFrameTrajectoryTUM("KeyFrameTrajectory.txt");

    ros::shutdown();

    return 0;
}

void ImageGrabber::GrabCompressedImage(const sensor_msgs::CompressedImageConstPtr& msg)
{
    try
    {
        cv::Mat image = cv::imdecode(cv::Mat(msg->data), cv::IMREAD_COLOR);

        if(image.empty())
        {
            ROS_ERROR("Failed to decode compressed image");
            return;
        }

        if(mbClahe)
        {
            cv::Mat gray;
            cv::cvtColor(image, gray, cv::COLOR_BGR2GRAY);
            mClahe->apply(gray, gray);
            cv::cvtColor(gray, image, cv::COLOR_GRAY2BGR);
        }

        double timestamp = msg->header.stamp.toSec();
        mpSLAM->TrackMonocular(image, timestamp);
    }
    catch (cv::Exception& e)
    {
        ROS_ERROR("OpenCV exception: %s", e.what());
        return;
    }
}
