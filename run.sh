#!/bin/bash

export OLT_TOKEN="${OLT_TOKEN}"
export OLT_TENANT="${OLT_TENANT}"
bash /home/pi/raspbiansetup.sh
export OLT_RASPBERRY_DEVICE=`cat /home/pi/out/raspberry.txt`
export OLT_RASPBERRY_DEVICE_TYPE=`cat /home/pi/out/raspberry_type.txt`

bash /home/pi/install_camera.sh
export OLT_CAMERA_DEVICE=`cat /home/pi/out/camera.txt`
export OLT_CAMERA_DEVICE_TYPE=`cat /home/pi/out/camera_type.txt`

bash /home/pi/install_screen.sh
export OLT_SCREEN_DEVICE=`cat /home/pi/out/screen.txt`
export OLT_SCREEN_DEVICE_TYPE=`cat /home/pi/out/screen_type.txt`

bash /home/pi/install_distance.sh
export OLT_DISTANCE_DEVICE=`cat /home/pi/out/distance.txt`
export OLT_DISTANCE_DEVICE_TYPE=`cat /home/pi/out/distance_type.txt`

bash /home/pi/install_presence.sh
export OLT_PRESENCE_DEVICE=`cat /home/pi/out/presence.txt`
export OLT_PRESENCE_DEVICE_TYPE=`cat /home/pi/out/presence_type.txt`

bash /home/pi/install_rgb.sh
export OLT_RGB_DEVICE=`cat /home/pi/out/rgb.txt`
export OLT_RGB_DEVICE_TYPE=`cat /home/pi/out/rgb_type.txt`

bash /home/pi/install_hue.sh
export OLT_HUE_DEVICE=`cat /home/pi/out/hue.txt`
export OLT_HUE_DEVICE_TYPE=`cat /home/pi/out/hue_type.txt`
export OLT_HUE_LIGHTBULB_DEVICE_TYPE=`cat /home/pi/out/hue_type.txt`

bash /home/pi/install_link.sh

bash /home/pi/install_fan.sh

bash /home/pi/cleanup.sh