from setuptools import setup

package_name = "camera_rectifier"

setup(
    name=package_name,
    version="0.0.1",
    packages=[package_name],
    install_requires=["setuptools"],
    zip_safe=True,
    maintainer="Eliyas Abraha",
    maintainer_email="you@example.com",
    description="Python-based camera image rectification node using OpenCV.",
    license="Apache-2.0",
    entry_points={
        "console_scripts": [
            "rectify_node = camera_rectifier.rectify_node:main",
        ],
    },
)
