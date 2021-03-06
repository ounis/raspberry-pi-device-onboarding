#!/bin/bash

set -e
[[ $- == *i* ]] && tput setaf 2
echo "Installing rgb program"

echo """
Connect a 4-pin RGB-LED to your Raspberry Pi.

GPIO mapping:

--------------------------
| Device  | Raspberry Pi |
--------------------------
| Green   | GPIO 24      |
| Blue    | GPIO 25      |
| Cathode | GPIO 5       |
| Red     | GPIO 23      |
--------------------------

"""
[[ $- == *i* ]] && tput sgr0

if [ ! -n "$OLT_PLATFORM" ]; then
  read -p "Provide your platform URL: " OLT_PLATFORM;
fi

if [ ! -n "$OLT_TOKEN" ]; then
  read -p "Provide your API Authentication-Token: " OLT_TOKEN;
fi

[[ $- == *i* ]] && tput setaf 2
echo "Create device type"
[[ $- == *i* ]] && tput sgr0
dt=`date +%s`
OLT_RGB_DEVICE_TYPE=`curl -X POST \
  https://api.$OLT_PLATFORM/v1/device-types \
  -H "Authorization: Bearer $OLT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{
  \"name\": \"Rgb_$dt\",
  \"schema\": {
    \"actions\": {
      \"ambientLight\": {
        \"type\": \"object\",
        \"properties\": {
          \"b\": {
            \"type\": \"string\"
          },
          \"g\": {
            \"type\": \"string\"
          },
          \"r\": {
            \"type\": \"string\"
          }
        }
      }
    }
  }
}" | \
python3 -c "import sys, json; print(json.load(sys.stdin)['data']['id'])"`

[[ $- == *i* ]] && tput setaf 2
echo "Create device"
[[ $- == *i* ]] && tput sgr0
OLT_RGB_DEVICE=`curl -X POST \
  https://api.$OLT_PLATFORM/v1/devices \
  -H "Authorization: Bearer $OLT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{
  \"info\": {
    \"name\": \"Rgb_$dt\",
    \"deviceTypeId\": \"$OLT_RGB_DEVICE_TYPE\"
  }
}" | \
python3 -c "import sys, json; print(json.load(sys.stdin)['data']['id'])"`

if [ -d /home/pi/rgb ]; then
  rm -rf /home/pi/rgb;
fi
mkdir -p /home/pi/rgb

openssl ecparam -out /home/pi/rgb/device_key.pem -name prime256v1 -genkey
if [ ! -n "$OLT_TENANT" ]; then
  read -p "Provide your Tenant name: " OLT_TENANT;
fi

if [ ! -n "$OLT_RGB_DEVICE" ]; then
  read -p "Provide your Device name: " OLT_RGB_DEVICE;
fi
openssl req -new -key /home/pi/rgb/device_key.pem -x509 -days 365 -out /home/pi/rgb/device_cert.pem -subj '/O=$OLT_TENANT/CN=$OLT_RGB_DEVICE'

echo "Your device certificate is:"
[[ $- == *i* ]] && tput sgr0
OLT_DEVICE_CERTIFICATE=$(</home/pi/rgb/device_cert.pem)
OLT_DEVICE_CERTIFICATE="{\"cert\": \"${OLT_DEVICE_CERTIFICATE//$'\n'/\\\n}\", \"status\":\"valid\"}"

curl -X POST \
  "https://api.$OLT_PLATFORM/v1/devices/$OLT_RGB_DEVICE/certificates" \
  -H "Authorization: Bearer $OLT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "$OLT_DEVICE_CERTIFICATE"

cat << 'EOF' > /home/pi/rgb/rgb.py
#!/usr/bin/python3

import RPi.GPIO as GPIO
import json
import re
import paho.mqtt.client as mqtt #import the client1
import ssl

GPIO.setmode(GPIO.BCM)

RED = 23
GREEN = 24
BLUE = 25

GPIO.setup(RED, GPIO.OUT)
GPIO.output(RED, 0)
GPIO.setup(GREEN, GPIO.OUT)
GPIO.output(GREEN, 0)
GPIO.setup(BLUE, GPIO.OUT)
GPIO.output(BLUE, 0)


EOF

echo "url=\"mqtt.$OLT_PLATFORM\"" >> /home/pi/rgb/rgb.py

cat << 'EOF' >> /home/pi/rgb/rgb.py

ca = "/home/pi/raspberrypi/olt_ca.pem"
cert = "/home/pi/rgb/device_cert.pem"
private = "/home/pi/rgb/device_key.pem"

EOF

echo "deviceId = \"$OLT_RGB_DEVICE\"" >> /home/pi/rgb/rgb.py

cat << 'EOF' >> /home/pi/rgb/rgb.py

def on_message(client, userdata, message):
    msg = message.payload
    parsed_json = json.loads(msg)
    r = parsed_json["payload"]["r"]
    g = parsed_json["payload"]["g"]
    b = parsed_json["payload"]["b"]
    GPIO.output(RED, int(r))
    GPIO.output(GREEN, int(g))
    GPIO.output(BLUE, int(b))

def on_connect(client, userdata, flags, rc):
    mqttc.subscribe("devices/" + deviceId + "/actions")

mqttc = mqtt.Client()
mqttc.on_message=on_message
mqttc.on_connect = on_connect
ssl_context = ssl.create_default_context()
ssl_context.set_alpn_protocols(["mqttv311"])
ssl_context.load_verify_locations(cafile=ca)
ssl_context.load_cert_chain(certfile=cert, keyfile=private)
mqttc.tls_set_context(context=ssl_context)
mqttc.connect(url, port=8883)
try:
    while True:
        mqttc.loop_forever()

except KeyboardInterrupt:
    mqttc.disconnect()
    mqttc.loop_stop()
    GPIO.cleanup()

EOF

chmod +x /home/pi/rgb/rgb.py

cat << 'EOF' > /home/pi/rgb/cron.sh
#!/bin/bash

kill $(ps aux | grep '[r]gb.py' | awk '{print $2}')
/usr/bin/python3 /home/pi/rgb/rgb.py > /home/pi/iot.log 2>&1 &

EOF

chmod +x /home/pi/rgb/cron.sh

crontab -l > /tmp/crontabentry 2>&1 || true
if grep -q "no crontab" /tmp/crontabentry; then
  echo -e "\n* * * * * /home/pi/rgb/cron.sh > /home/pi/iot.log 2>&1 \n" > /tmp/crontabentry
  crontab /tmp/crontabentry
fi
if ! grep -q "rgb/cron.sh" /tmp/crontabentry; then
  echo -e "\n* * * * * /home/pi/rgb/cron.sh > /home/pi/iot.log 2>&1 \n" >> /tmp/crontabentry
  crontab /tmp/crontabentry
fi

crontab -l

mkdir -p /home/pi/out
echo $OLT_RGB_DEVICE_TYPE > /home/pi/out/rgb_type.txt
echo $OLT_RGB_DEVICE > /home/pi/out/rgb.txt

[[ $- == *i* ]] && tput setaf 2
echo "Installation complete"
[[ $- == *i* ]] && tput sgr0
exit 0
