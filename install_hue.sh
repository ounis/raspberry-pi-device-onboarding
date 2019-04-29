#!/bin/bash

set -e
[[ $- == *i* ]] && tput setaf 2
echo "Installing hue program"

echo """
A Philips Hue gateway was used with several Hue lightbulbs
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
OLT_HUE_DEVICE_TYPE=`curl -X POST \
  https://api.$OLT_PLATFORM/v1/device-types \
  -H "Authorization: Bearer $OLT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{
  \"name\": \"Hue_$dt\",
  \"schema\": {
    \"actions\": {
      \"ambientLight\": {
        \"type\": \"object\",
        \"properties\": {
          \"alert\": {
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
OLT_HUE_DEVICE=`curl -X POST \
  https://api.$OLT_PLATFORM/v1/devices \
  -H "Authorization: Bearer $OLT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{
  \"info\": {
    \"name\": \"Hue_$dt\",
    \"deviceTypeId\": \"$OLT_HUE_DEVICE_TYPE\"
  }
}" | \
python3 -c "import sys, json; print(json.load(sys.stdin)['data']['id'])"`

if [ -d /home/pi/hue ]; then
  rm -rf /home/pi/hue;
fi
mkdir -p /home/pi/hue

openssl ecparam -out /home/pi/hue/device_key.pem -name prime256v1 -genkey
if [ ! -n "$OLT_TENANT" ]; then
  read -p "Provide your Tenant name: " OLT_TENANT;
fi

if [ ! -n "$OLT_HUE_DEVICE" ]; then
  read -p "Provide your Device name: " OLT_HUE_DEVICE;
fi
openssl req -new -key /home/pi/hue/device_key.pem -x509 -days 365 -out /home/pi/hue/device_cert.pem -subj '/O=$OLT_TENANT/CN=$OLT_HUE_DEVICE'

echo "Your device certificate is:"
[[ $- == *i* ]] && tput sgr0
OLT_DEVICE_CERTIFICATE=$(</home/pi/hue/device_cert.pem)
OLT_DEVICE_CERTIFICATE="{\"cert\": \"${OLT_DEVICE_CERTIFICATE//$'\n'/\\\n}\", \"status\":\"valid\"}"

curl -X POST \
  "https://api.$OLT_PLATFORM/v1/devices/$OLT_HUE_DEVICE/certificates" \
  -H "Authorization: Bearer $OLT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "$OLT_DEVICE_CERTIFICATE"

cat << 'EOF' > /home/pi/hue/hue.py
#!/usr/bin/python3

import json
import requests
import time
import urllib3
import paho.mqtt.client as mqtt
import ssl

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

EOF

if [ ! -n "$OLT_HUE_ADDRESS" ]; then
  read -p "Provide your Device IP address or URL: " OLT_HUE_ADDRESS;
fi

if [ ! -n "$OLT_HUE_USER" ]; then
  read -p "Provide your Hue user name: " OLT_HUE_USER;
fi

echo "hue_address = \"$OLT_HUE_ADDRESS\"" >> /home/pi/hue/hue.py
echo "hue_user = \"$OLT_HUE_USER\"" >> /home/pi/hue/hue.py

cat << 'EOF' >> /home/pi/hue/hue.py

lamp1 = "25"

red = """{
    "hue": 65535,
    "sat": 254,
    "transitiontime": 0
}"""

yellow = """{
    "hue": 10000,
    "sat": 254,
    "transitiontime": 0
}"""

green = """{
    "hue": 21845,
    "sat": 254,
    "transitiontime": 0
}"""

cyan = """{
    "hue": 40000,
    "sat": 254,
    "transitiontime": 0
}"""

blue = """{
    "hue": 45000,
    "sat": 254,
    "transitiontime": 0
}"""

purple = """{
    "hue": 45500,
    "sat": 254,
    "transitiontime": 0
}"""

orange = """{
    "hue": 8000,
    "sat": 254,
    "transitiontime": 0
}"""

white = """{
    "on": true,
    "bri": 254,
    "hue": 41500,
    "sat": 100,
    "transitiontime": 0
}"""


off = """{
    "on": false,
    "transitiontime": 0
}"""


def update_state(url, payload):
     requests.put(url,
        verify=False,
        headers={"content-type":"application/json"},
        data=payload)

def set_color(color):
    url = "https://" + hue_address + "/api/" + hue_user + "/lights/" + lamp1 + "/state"
    update_state(url, color)

EOF

echo "deviceId = \"$OLT_HUE_DEVICE\"" >> /home/pi/hue/hue.py

cat << 'EOF' >> /home/pi/hue/hue.py

def on_message(client, userdata, message):
    msg = message.payload
    parsed_json = json.loads(msg.decode("utf-8"))
    alert = parsed_json["payload"]["alert"]
    if alert == "error":
        set_color(red)
    if alert == "success":
        set_color(green)

def on_connect(client, userdata, flags, rc):
    mqttc.subscribe("devices/" + deviceId + "/actions")

EOF

echo "url=\"mqtt.$OLT_PLATFORM\"" >> /home/pi/hue/hue.py

cat << 'EOF' >> /home/pi/hue/hue.py

ca = "/home/pi/raspberrypi/olt_ca.pem"
cert = "/home/pi/hue/device_cert.pem"
private = "/home/pi/hue/device_key.pem"

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
    set_color(yellow)

EOF

chmod +x /home/pi/hue/hue.py

cat << 'EOF' > /home/pi/hue/cron.sh
#!/bin/bash

kill $(ps aux | grep '[h]ue.py' | awk '{print $2}')
/usr/bin/python3 /home/pi/hue/hue.py &

EOF

chmod +x /home/pi/hue/cron.sh

crontab -l > /tmp/crontabentry 2>&1 || true
if grep -q "no crontab" /tmp/crontabentry; then
  echo -e "\n* * * * * /home/pi/hue/cron.sh\n" > /tmp/crontabentry
  crontab /tmp/crontabentry
fi
if ! grep -q "hue/cron.sh" /tmp/crontabentry; then
  echo -e "\n* * * * * /home/pi/hue/cron.sh\n" >> /tmp/crontabentry
  crontab /tmp/crontabentry
fi

crontab -l

mkdir -p /home/pi/out
echo $OLT_HUE_DEVICE_TYPE > /home/pi/out/hue_type.txt
echo $OLT_HUE_DEVICE > /home/pi/out/hue.txt

[[ $- == *i* ]] && tput setaf 2
echo "Installation complete"
[[ $- == *i* ]] && tput sgr0
exit 0
