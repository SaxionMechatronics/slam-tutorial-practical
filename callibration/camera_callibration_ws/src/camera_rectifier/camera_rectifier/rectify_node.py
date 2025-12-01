#!/usr/bin/env python3
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Image, CameraInfo
from cv_bridge import CvBridge
import cv2
import numpy as np


class RectifyNode(Node):
    def __init__(self):
        super().__init__("rectify_node")
        self.bridge = CvBridge()
        self.got_camera_info = False
        self._warned_once = False

        # Subscribers
        self.create_subscription(
            CameraInfo, "camera_info", self.camera_info_callback, 10
        )
        self.create_subscription(Image, "image_raw", self.image_callback, 10)

        # Publisher
        self.publisher_ = self.create_publisher(Image, "image_rect", 10)

        self.get_logger().info("RectifyNode initialized. Waiting for camera_info...")

    def camera_info_callback(self, msg: CameraInfo):
        """Store camera parameters and precompute maps."""
        self.camera_matrix = np.array(msg.k, dtype=np.float64).reshape((3, 3))
        self.dist_coeffs = np.array(msg.d, dtype=np.float64)
        self.image_size = (msg.width, msg.height)
        self.got_camera_info = True

        self.new_camera_matrix, _ = cv2.getOptimalNewCameraMatrix(
            self.camera_matrix, self.dist_coeffs, self.image_size, 1, self.image_size
        )

        self.map1, self.map2 = cv2.initUndistortRectifyMap(
            self.camera_matrix,
            self.dist_coeffs,
            None,
            self.new_camera_matrix,
            self.image_size,
            cv2.CV_16SC2,
        )

        self.get_logger().info("Camera info received, rectification maps initialized.")

    def image_callback(self, msg: Image):
        """Rectify each incoming image."""
        if not self.got_camera_info:
            if not self._warned_once:
                self.get_logger().warn("No camera info yet, skipping frames...")
                self._warned_once = True
            return

        try:
            cv_image = self.bridge.imgmsg_to_cv2(msg, desired_encoding="bgr8")
        except Exception as e:
            self.get_logger().error(f"cv_bridge conversion failed: {e}")
            return
        self.get_logger().info("Camera raw image received, rectifying...")

        rectified = cv2.remap(
            cv_image, self.map1, self.map2, interpolation=cv2.INTER_LINEAR
        )

        rectified_msg = self.bridge.cv2_to_imgmsg(rectified, encoding="bgr8")
        rectified_msg.header = msg.header
        self.publisher_.publish(rectified_msg)
        # save rectified image with name based on timestamp

        cv2.imwrite(
            f"{msg.header.stamp.sec}_rectified_.png",
            rectified,
        )

        cv2.imwrite(
            f"{msg.header.stamp.sec}_raw.png",
            cv_image,
        )

        self.get_logger().debug("Published rectified image.")


def main(args=None):
    rclpy.init(args=args)
    node = RectifyNode()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()


if __name__ == "__main__":
    main()
