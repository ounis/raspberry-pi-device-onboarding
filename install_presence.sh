#!/bin/bash

set -e
[[ $- == *i* ]] && tput setaf 2
echo "Installing presence program"

echo """
A HC-SR501 PIR Sensor was used to test this script, but other kinds of similar sensors could be used

GPIO mapping

-------------------------
| Device | Raspberry Pi |
-------------------------
| VCC    | VCC 5V       |
| Out    | GPIO 4       |
| GND    | Ground       |
-------------------------

"""
[[ $- == *i* ]] && tput sgr0

[[ $- == *i* ]] && tput setaf 2
echo "Create device type"
[[ $- == *i* ]] && tput sgr0
dt=`date +%s`
OLT_PRESENCE_DEVICE_TYPE=`curl -X POST \
  https://api.dev.olt-dev.io/v1/device-types \
  -H "Authorization: Bearer $OLT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{
  \"name\": \"Presence_$dt\",
  \"schema\": {
    \"configuration\": {
      \"presence\": {
        \"type\": \"integer\"
      }
    }
  }
}" | \
python3 -c "import sys, json; print(json.load(sys.stdin)['data']['id'])"`

[[ $- == *i* ]] && tput setaf 2
echo "Create device"
[[ $- == *i* ]] && tput sgr0
OLT_PRESENCE_DEVICE=`curl -X POST \
  https://api.dev.olt-dev.io/v1/devices \
  -H "Authorization: Bearer $OLT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{
  \"info\": {
    \"name\": \"Presence_$dt\",
    \"deviceTypeId\": \"$OLT_PRESENCE_DEVICE_TYPE\"
  }
}" | \
python3 -c "import sys, json; print(json.load(sys.stdin)['data']['id'])"`

if [ -d /home/pi/presence ]; then
  rm -rf /home/pi/presence;
fi
mkdir -p /home/pi/presence

openssl ecparam -out /home/pi/presence/device_key.pem -name prime256v1 -genkey
if [ ! -n "$OLT_TENANT" ]; then
  read -p "Provide your Tenant name: " OLT_TENANT;
fi

if [ ! -n "$OLT_PRESENCE_DEVICE" ]; then
  read -p "Provide your Device name: " OLT_PRESENCE_DEVICE;
fi
openssl req -new -key /home/pi/presence/device_key.pem -x509 -days 365 -out /home/pi/presence/device_cert.pem -subj '/O=$OLT_TENANT/CN=$OLT_PRESENCE_DEVICE'

echo "Your device certificate is:"
[[ $- == *i* ]] && tput sgr0
OLT_DEVICE_CERTIFICATE=$(</home/pi/presence/device_cert.pem)
OLT_DEVICE_CERTIFICATE="{\"cert\": \"${OLT_DEVICE_CERTIFICATE//$'\n'/\\\n}\", \"status\":\"valid\"}"

curl -X POST \
  "https://api.dev.olt-dev.io/v1/devices/$OLT_PRESENCE_DEVICE/certificates" \
  -H "Authorization: Bearer $OLT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "$OLT_DEVICE_CERTIFICATE"

cat << 'EOF' > /home/pi/presence/presence.py
#!/usr/bin/python

import time
import RPi.GPIO as GPIO
import paho.mqtt.client as mqtt
import ssl

GPIO.setmode(GPIO.BCM)
GPIO_PRESENCE = 4
GPIO.setup(GPIO_PRESENCE,GPIO.IN)

url = "mqtt.dev.olt-dev.io"
ca = "/home/pi/raspberrypi/olt_ca.pem"
cert = "/home/pi/presence/device_cert.pem"
private = "/home/pi/presence/device_key.pem"

try:
  while True:
    presence = GPIO.input(GPIO_PRESENCE)
    mqttc = mqtt.Client()
    ssl_context = ssl.create_default_context()
    ssl_context.set_alpn_protocols(["mqttv311"])
    ssl_context.load_verify_locations(cafile=ca)
    ssl_context.load_cert_chain(certfile=cert, keyfile=private)
    mqttc.tls_set_context(context=ssl_context)
    mqttc.connect(url, port=8883)
    mqttc.publish("data-ingest", '{ "type": "configuration", "value": { "presence": ' + str(presence) + ' } }')
    time.sleep(0.5)
except KeyboardInterrupt:
  GPIO.cleanup()

EOF

chmod +x /home/pi/presence/presence.py

cat << 'EOF' > /home/pi/presence/cron.sh
#!/bin/bash

kill $(ps aux | grep '[p]resence.py' | awk '{print $2}')
/usr/bin/python /home/pi/presence/presence.py &

EOF

chmod +x /home/pi/presence/cron.sh

crontab -l > /tmp/crontabentry 2>&1 || true
if grep -q "no crontab" /tmp/crontabentry; then
  echo -e "\n* * * * * /home/pi/presence/presence.py\n" > /tmp/crontabentry
  crontab /tmp/crontabentry
fi
if ! grep -q "presence/cron.sh" /tmp/crontabentry; then
  echo -e "\n* * * * * /home/pi/presence/presence.py\n" >> /tmp/crontabentry
  crontab /tmp/crontabentry
fi

crontab -l

mkdir -p out
echo $OLT_PRESENCE_DEVICE_TYPE > out/presence_type.txt
echo $OLT_PRESENCE_DEVICE > out/presence.txt

[[ $- == *i* ]] && tput setaf 2
echo "Installation complete"
[[ $- == *i* ]] && tput sgr0
exit 0
