#!/bin/bash

export OLT_TOKEN="${OLT_TOKEN}"
export OLT_TENANT="${OLT_TENANT}"
bash /home/pi/raspbiansetup.sh
export OLT_RASPBERRY_DEVICE=`cat out/raspberry.txt`
export OLT_RASPBERRY_DEVICE_TYPE=`cat out/raspberry_type.txt`

bash /home/pi/install_camera.sh
export OLT_CAMERA_DEVICE=`cat out/camera.txt`
export OLT_CAMERA_DEVICE_TYPE=`cat out/camera_type.txt`

bash /home/pi/install_screen.sh
export OLT_SCREEN_DEVICE=`cat out/screen.txt`
export OLT_SCREEN_DEVICE_TYPE=`cat out/screen_type.txt`

bash /home/pi/install_distance.sh
export OLT_DISTANCE_DEVICE=`cat out/distance.txt`
export OLT_DISTANCE_DEVICE_TYPE=`cat out/distance_type.txt`

bash /home/pi/install_presence.sh
export OLT_PRESENCE_DEVICE=`cat out/presence.txt`
export OLT_PRESENCE_DEVICE_TYPE=`cat out/presence_type.txt`

bash /home/pi/install_rgb.sh
export OLT_RGB_DEVICE=`cat out/rgb.txt`
export OLT_RGB_DEVICE_TYPE=`cat out/rgb_type.txt`

bash /home/pi/install_hue.sh
export OLT_HUE_DEVICE=`cat out/hue.txt`
export OLT_HUE_DEVICE_TYPE=`cat out/hue_type.txt`

bash /home/pi/install_link.sh

bash /home/pi/cleanup.sh