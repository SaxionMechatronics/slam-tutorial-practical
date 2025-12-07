from launch import LaunchDescription
from launch_ros.actions import Node
from ament_index_python.packages import get_package_share_directory
import os
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration


def generate_launch_description():

    image_topic = LaunchConfiguration("image_raw")

    return LaunchDescription(
        [
            DeclareLaunchArgument(
                "image_raw",
                default_value="/image_raw",
                description="Input raw image topic",
            ),
            Node(
                package="camera_rectifier",
                executable="rectify_node",
                name="camera_rectify_node",
                parameters=[
                    {
                        "camera_name": "zed_left",
                        "use_sim_time": True,
                    }
                ],
                remappings=[
                    ("image_raw", image_topic),
                ],
            ),
            Node(
                package="camera_pipeline",
                executable="camera_info_process_node",
                name="camera_info_process",
                parameters=[
                    {
                        "camera_name": "zed_left",
                        "use_sim_time": True,
                        "camera_info_url": "package://camera_pipeline/config/ost.yaml",
                    }
                ],
            ),
        ]
    )
