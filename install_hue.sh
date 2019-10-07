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
echo "Create device types"
[[ $- == *i* ]] && tput sgr0
dt=`date +%s`
OLT_HUE_DEVICE_TYPE=`curl -X POST \
  https://api.$OLT_PLATFORM/v1/device-types \
  -H "Authorization: Bearer $OLT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{
  \"name\": \"Philips Hue Bridge $dt\",
  \"manufacturer\": \"Philips\",
  \"model\": \"Bridge\",
  \"description\": \"Philips Hue Bridge.\",
  \"reportingRules\": [
    {
      \"path\": \"$.configuration.ambientLight\",
      \"reportTo\": [
        \"timeseries\"
      ]
    }
  ],
  \"schema\": {
    \"configuration\": {
      \"ambientLight\": {
        \"enum\": [
          \"red\",
          \"white\"
        ],
        \"type\": \"string\"
      },
      \"additionalProperties\": false
    }
  }
}" | \
python3 -c "import sys, json; print(json.load(sys.stdin)['data']['id'])"`

OLT_HUE_LIGHTBULB_DEVICE_TYPE=`curl -X POST \
  https://api.$OLT_PLATFORM/v1/device-types \
  -H "Authorization: Bearer $OLT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{
  \"name\": \"Philips HUE Lightbulb $dt\",
  \"manufacturer\": \"Philips\",
  \"model\": \"LCT015\",
  \"description\": \"Zigbee lightbulb with white and color ambiance.\",
  \"reportingRules\": [
    {
      \"path\": \"$.configuration.on\",
      \"reportTo\": [
        \"timeseries\"
      ]
    },
    {
      \"path\": \"$.configuration.bri\",
      \"reportTo\": [
        \"timeseries\"
      ]
    },
    {
      \"path\": \"$.configuration.hue\",
      \"reportTo\": [
        \"timeseries\"
      ]
    },
    {
      \"path\": \"$.configuration.sat\",
      \"reportTo\": [
        \"timeseries\"
      ]
    }
  ],
  \"schema\": {
    \"configuration\": {
      \"on\": {
        \"type\": \"boolean\"
      },
      \"bri\": {
        \"type\": \"number\"
      },
      \"hue\": {
        \"type\": \"number\"
      },
      \"sat\": {
        \"type\": \"number\"
      },
      \"additionalProperties\": false
    }
  }
}" | \
python3 -c "import sys, json; print(json.load(sys.stdin)['data']['id'])"`

[[ $- == *i* ]] && tput setaf 2
echo "Create devices"
[[ $- == *i* ]] && tput sgr0
OLT_HUE_DEVICE=`curl -X POST \
  https://api.$OLT_PLATFORM/v1/devices \
  -H "Authorization: Bearer $OLT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{
  \"info\": {
    \"name\": \"Hue Bridge $dt\",
    \"deviceTypeId\": \"$OLT_HUE_DEVICE_TYPE\",
    \"description\": \"Philips HUE Bridge.\",
    \"tags\": [
      \"Philips\",
      \"HUE\",
      \"Bridge\"
    ],
    \"location\": \"Somewhere around me\"
  }
}" | \
python3 -c "import sys, json; print(json.load(sys.stdin)['data']['id'])"`

crontab -l

mkdir -p /home/pi/out
echo $OLT_HUE_DEVICE_TYPE > /home/pi/out/hue_type.txt
echo $OLT_HUE_DEVICE > /home/pi/out/hue.txt

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


declare -A array
array[1]="Lightbulb1"
array[2]="Lightbulb2"

for i in "${!array[@]}"
do

OLT_HUE_LIGHTBULB_DEVICE=`curl -X POST \
  https://api.$OLT_PLATFORM/v1/devices \
  -H "Authorization: Bearer $OLT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{
  \"info\": {
    \"name\": \"Lightbulb ${array[$i]} $dt\",
    \"deviceTypeId\": \"$OLT_HUE_LIGHTBULB_DEVICE_TYPE\",
    \"description\": \"Philips HUE Lightbulb.\",
    \"tags\": [
      \"Philips\",
      \"HUE\",
      \"Lightbulb\",
      \"${array[$i]}\"
    ],
    \"connectedBy\": \"$OLT_HUE_DEVICE\",
    \"location\": \"Next to ${array[$i]}\"
  }
}" | \
python3 -c "import sys, json; print(json.load(sys.stdin)['data']['id'])"`

  if [ -d /home/pi/hue/$i ]; then
    rm -rf /home/pi/hue/$i;
  fi
  mkdir /home/pi/hue/$i
  openssl ecparam -out /home/pi/hue/$i/device_key.pem -name prime256v1 -genkey
  openssl req -new -key /home/pi/hue/$i/device_key.pem -x509 -days 365 -out /home/pi/hue/$i/device_cert.pem -subj '/O=My-Tenant/CN=My-Device'
  echo "Your device certificate is:"
  [[ $- == *i* ]] && tput sgr0
  OLT_DEVICE_CERTIFICATE=$(</home/pi/hue/$i/device_cert.pem)
  OLT_DEVICE_CERTIFICATE="{\"cert\": \"${OLT_DEVICE_CERTIFICATE//$'\n'/\\\n}\", \"status\":\"valid\"}"

  curl -X POST \
    "https://api.$OLT_PLATFORM/v1/devices/$OLT_HUE_LIGHTBULB_DEVICE/certificates" \
    -H "Authorization: Bearer $OLT_TOKEN" \
    -H 'Content-Type: application/json' \
    -d "$OLT_DEVICE_CERTIFICATE"

  mkdir -p /home/pi/out
  echo $OLT_HUE_LIGHTBULB_DEVICE_TYPE > /home/pi/out/hue_lightbulb_type.txt
  echo $OLT_HUE_LIGHTBULB_DEVICE > /home/pi/out/hue_lightbulb_device_$i.txt
done


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

lightbulb1 = "1"
lightbulb2 = "2"

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
    "hue": 41365,
    "sat": 75,
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
    url = "https://" + hue_address + "/api/" + hue_user + "/lights/" + lightbulb1 + "/state"
    update_state(url, color)
    url = "https://" + hue_address + "/api/" + hue_user + "/lights/" + lightbulb2 + "/state"
    update_state(url, color)

EOF

echo "deviceId = \"$OLT_HUE_DEVICE\"" >> /home/pi/hue/hue.py

cat << 'EOF' >> /home/pi/hue/hue.py

def on_message(client, userdata, message):
    msg = message.payload
    parsed_json = json.loads(msg.decode("utf-8"))
    alert = parsed_json["configuration"]["ambientLight"]
    if alert == "red":
        set_color(red)
    if alert == "white":
        set_color(white)
    mqttc.publish("data-ingest", '{ "type": "configuration", "value": { "ambientLight": "' + alert + '"}}')

def on_connect(client, userdata, flags, rc):
    mqttc.subscribe("devices/" + deviceId + "/configuration")

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
    set_color(white)

EOF

chmod +x /home/pi/hue/hue.py


cat << 'EOF' > /home/pi/hue/lightbulb.py
#!/usr/bin/python3

import json
import requests
import time
import urllib3
import paho.mqtt.client as mqtt
import ssl

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

EOF

echo "hue_address = \"$OLT_HUE_ADDRESS\"" >> /home/pi/hue/lightbulb.py
echo "hue_user = \"$OLT_HUE_USER\"" >> /home/pi/hue/lightbulb.py

cat << 'EOF' >> /home/pi/hue/lightbulb.py

lamps = [
    "1",
    "2"
    ]

EOF

echo "mqtt_url=\"mqtt.$OLT_PLATFORM\"" >> /home/pi/hue/lightbulb.py

cat << 'EOF' >> /home/pi/hue/lightbulb.py

ca = "/home/pi/raspberrypi/olt_ca.pem"


def update_state(lamp):
    url = "https://" + hue_address + "/api/" + hue_user + "/lights/" + lamp
    result = requests.get(url, verify=False)
    parsed_json = json.loads(result.text)
    state = '''
{
  "type": "configuration",
  "value": {
    "on": ''' + str(parsed_json["state"]["on"]).lower() + ''',
    "bri": ''' + str(parsed_json["state"]["bri"]) + ''',
    "hue": ''' + str(parsed_json["state"]["hue"]) + ''',
    "sat": ''' + str(parsed_json["state"]["sat"]) + '''
  }
}
'''

    cert = "/home/pi/hue/" + lamp + "/device_cert.pem"
    private = "/home/pi/hue/" + lamp + "/device_key.pem"
    mqttc = mqtt.Client()
    ssl_context = ssl.create_default_context()
    ssl_context.set_alpn_protocols(["mqttv311"])
    ssl_context.load_verify_locations(cafile=ca)
    ssl_context.load_cert_chain(certfile=cert, keyfile=private)
    mqttc.tls_set_context(context=ssl_context)
    mqttc.connect(mqtt_url, port=8883)
    mqttc.publish("data-ingest", state)
    mqttc.disconnect()

while True:
    for lamp in lamps:
        update_state(lamp)

EOF

cat << 'EOF' > /home/pi/hue/cron.sh
#!/bin/bash

kill $(ps aux | grep '[h]ue.py' | awk '{print $2}')
/usr/bin/python3 /home/pi/hue/hue.py > /home/pi/iot.log 2>&1 &

kill $(ps aux | grep '[l]ightbulb.py' | awk '{print $2}')
/usr/bin/python3 /home/pi/hue/lightbulb.py > /home/pi/iot.log 2>&1 &

EOF

chmod +x /home/pi/hue/cron.sh

crontab -l > /tmp/crontabentry 2>&1 || true
if grep -q "no crontab" /tmp/crontabentry; then
  echo -e "\n* * * * * /home/pi/hue/cron.sh > /home/pi/iot.log 2>&1 \n" > /tmp/crontabentry
  crontab /tmp/crontabentry
fi
if ! grep -q "hue/cron.sh" /tmp/crontabentry; then
  echo -e "\n* * * * * /home/pi/hue/cron.sh > /home/pi/iot.log 2>&1 \n" >> /tmp/crontabentry
  crontab /tmp/crontabentry
fi

[[ $- == *i* ]] && tput setaf 2
echo "Installation complete"
[[ $- == *i* ]] && tput sgr0
exit 0
