#include <rclcpp/rclcpp.hpp>
#include <sensor_msgs/msg/camera_info.hpp>
#include <camera_info_manager/camera_info_manager.hpp>

class CameraInfoPublisher : public rclcpp::Node
{
public:
    CameraInfoPublisher()
        : Node("camera_info_publisher_cpp")
    {
        this->declare_parameter<std::string>("camera_name", "camera");
        this->declare_parameter<std::string>("camera_info_url", "");

        std::string camera_name = this->get_parameter("camera_name").as_string();
        std::string camera_info_url = this->get_parameter("camera_info_url").as_string();

        // Create camera info manager
        cinfo_manager_ = std::make_shared<camera_info_manager::CameraInfoManager>(this, camera_name, camera_info_url);

        if (cinfo_manager_->loadCameraInfo(camera_info_url))
        {
            RCLCPP_INFO(this->get_logger(), "Loaded camera info from %s", camera_info_url.c_str());
        }
        else
        {
            RCLCPP_WARN(this->get_logger(), "Failed to load camera info from %s", camera_info_url.c_str());
        }

        publisher_ = this->create_publisher<sensor_msgs::msg::CameraInfo>("camera_info", 2000);
        timer_ = this->create_wall_timer(std::chrono::milliseconds(100), std::bind(&CameraInfoPublisher::publish_info, this));
    }

private:
    void publish_info()
    {
        auto msg = cinfo_manager_->getCameraInfo();
        msg.header.stamp = this->get_clock()->now();
        msg.header.frame_id = "zed_left_camera_optical_frame";
        publisher_->publish(msg);
    }

    std::shared_ptr<camera_info_manager::CameraInfoManager> cinfo_manager_;
    rclcpp::Publisher<sensor_msgs::msg::CameraInfo>::SharedPtr publisher_;
    rclcpp::TimerBase::SharedPtr timer_;
};

int main(int argc, char **argv)
{
    rclcpp::init(argc, argv);
    rclcpp::spin(std::make_shared<CameraInfoPublisher>());
    rclcpp::shutdown();
    return 0;
}
