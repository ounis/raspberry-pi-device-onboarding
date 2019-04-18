#!/bin/bash

set -e
[[ $- == *i* ]] && tput setaf 2
echo "Installing camera program"

echo """
A Raspberry Pi V2.1 8MP 1080P Camera was used to test this script, but other kinds of cameras could be used
Please don't forget to enable the camera in your raspi-config

"""
[[ $- == *i* ]] && tput sgr0

[[ $- == *i* ]] && tput setaf 2
echo "Create device type"
[[ $- == *i* ]] && tput sgr0
dt=`date +%s`
OLT_CAMERA_DEVICE_TYPE=`curl -X POST \
  https://api.dev.olt-dev.io/v1/device-types \
  -H "Authorization: Bearer $OLT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{
  \"name\": \"Camera_$dt\",
  \"schema\": {
    \"configuration\": {
      \"ipaddress\": {
        \"type\": \"string\"
      }
    }
  }
}"| \
python3 -c "import sys, json; print(json.load(sys.stdin)['data']['id'])"`

[[ $- == *i* ]] && tput setaf 2
echo "Create device"
[[ $- == *i* ]] && tput sgr0
OLT_CAMERA_DEVICE=`curl -X POST \
  https://api.dev.olt-dev.io/v1/devices \
  -H "Authorization: Bearer $OLT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{
  \"info\": {
    \"name\": \"Camera_$dt\",
    \"deviceTypeId\": \"$OLT_CAMERA_DEVICE_TYPE\"
  }
}"| \
python3 -c "import sys, json; print(json.load(sys.stdin)['data']['id'])"`


if [ -d /home/pi/camera ]; then
  rm -rf /home/pi/camera;
fi
mkdir -p /home/pi/camera

openssl ecparam -out /home/pi/camera/device_key.pem -name prime256v1 -genkey
if [ ! -n "$OLT_TENANT" ]; then
  read -p "Provide your Tenant name: " OLT_TENANT;
fi

if [ ! -n "$OLT_CAMERA_DEVICE" ]; then
  read -p "Provide your Device name: " OLT_CAMERA_DEVICE;
fi
openssl req -new -key /home/pi/camera/device_key.pem -x509 -days 365 -out /home/pi/camera/device_cert.pem -subj '/O=$OLT_TENANT/CN=$OLT_CAMERA_DEVICE'

echo "Your device certificate is:"
[[ $- == *i* ]] && tput sgr0
OLT_DEVICE_CERTIFICATE=$(</home/pi/camera/device_cert.pem)
OLT_DEVICE_CERTIFICATE="{\"cert\": \"${OLT_DEVICE_CERTIFICATE//$'\n'/\\\n}\", \"status\":\"valid\"}"

curl -X POST \
  "https://api.dev.olt-dev.io/v1/devices/$OLT_CAMERA_DEVICE/certificates" \
  -H "Authorization: Bearer $OLT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "$OLT_DEVICE_CERTIFICATE"

cat << 'EOF' > /home/pi/camera/camera.py
#!/usr/bin/python

import ssl
import paho.mqtt.client as mqtt
from picamera import PiCamera
from time import sleep
from itertools import chain, islice
import uu
import os
import glob
import hashlib
import urllib

vidFilename = '/home/pi/camera/video.h264'
txtFilename = '/home/pi/camera/video.txt'

# Record a 30 seconds video
with PiCamera() as camera:
    camera.resolution = (640, 480)
    camera.framerate = 30
    camera.start_recording(vidFilename)
    camera.wait_recording(30)
    camera.stop_recording()

# Encode the file into text
uu.encode(vidFilename, txtFilename)

def md5(fname):
    hash_md5 = hashlib.md5()
    with open(fname, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()

md5 = md5(vidFilename)
os.remove(vidFilename)

# Split the file to chunks not larger than 1 Mb
def chunks(iterable, n):
   iterable = iter(iterable)
   while True:
       yield chain([next(iterable)], islice(iterable, n-1))

l = 5000
with open(txtFilename) as bigfile:
    for i, lines in enumerate(chunks(bigfile, l)):
        file_split = '/home/pi/camera/chunk.{}'.format(i)
        with open(file_split, 'w') as f:
            f.writelines(urllib.quote("\n".join(lines)))
os.remove(txtFilename)

# Iterate on chunks and send a message for each one

url = "mqtt.dev.olt-dev.io"
ca = "/home/pi/raspberrypi/olt_ca.pem" 
cert = "/home/pi/camera/device_cert.pem"
private = "/home/pi/camera/device_key.pem"

file_names = glob.glob("/home/pi/camera/chunk.*")
for file_name in file_names:
    with open(file_name, 'r') as file :
        filedata = file.read()
        with open(file_name, 'r+') as f:
            f.seek(0, 0)
            f.write('{ "type": "configuration", "value": { ' +
                '"hash": "' + md5 + '", ' +
                '"chunk": ' + file_name.split('.')[1] + ', ' +
                '"video": "' + filedata + '"')
            f.seek(0, os.SEEK_END)
            f.write(' } }')

    with open(file_name, 'r') as file :
        filedata = file.read()
        mqttc = mqtt.Client()
        ssl_context = ssl.create_default_context()
        ssl_context.set_alpn_protocols(["mqttv311"])
        ssl_context.load_verify_locations(cafile=ca)
        ssl_context.load_cert_chain(certfile=cert, keyfile=private)
        mqttc.tls_set_context(context=ssl_context)
        mqttc.connect(url, port=8883)
        mqttc.publish("data-ingest", filedata)
        os.remove(file_name)

EOF

chmod +x /home/pi/camera/camera.py

cat << 'EOF' > /home/pi/camera/cron.sh
#!/bin/bash

kill $(ps aux | grep '[c]amera.py' | awk '{print $2}')
/usr/bin/python /home/pi/camera/camera.py &

EOF

chmod +x /home/pi/camera/cron.sh

crontab -l > /tmp/crontabentry 2>&1 || true
if grep -q "no crontab" /tmp/crontabentry; then
  echo -e "\n* * * * * /home/pi/camera/ipmqtt.sh\n" > /tmp/crontabentry
  crontab /tmp/crontabentry
fi
if ! grep -q "camera/cron.sh" /tmp/crontabentry; then
  echo -e "\n* * * * * /home/pi/camera/ipmqtt.sh\n" >> /tmp/crontabentry
  crontab /tmp/crontabentry
fi

crontab -l

[[ $- == *i* ]] && tput setaf 2
echo "Delete Device"
[[ $- == *i* ]] && tput sgr0

curl -X DELETE \
  "https://api.dev.olt-dev.io/v1/devices/$OLT_CAMERA_DEVICE" \
  -H "Authorization: Bearer $OLT_TOKEN"

[[ $- == *i* ]] && tput setaf 2
echo "Delete Device Type"
[[ $- == *i* ]] && tput sgr0

curl -X DELETE \
  "https://api.dev.olt-dev.io/v1/device-types/$OLT_CAMERA_DEVICE_TYPE" \
  -H "Authorization: Bearer $OLT_TOKEN"

echo """
Please Make sure your Device type has a structure similar to this one

{
  \"configuration\": {
    \"hash\": {
      \"type\": \"string\"
    },
    \"chunk\": {
      \"type\": \"integer\"
    },
    \"video\": {
      \"type\": \"string\"
    }
  }
}
"""

[[ $- == *i* ]] && tput setaf 2
echo "Installation complete"
[[ $- == *i* ]] && tput sgr0
exit 0