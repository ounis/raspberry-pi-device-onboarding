#!/bin/bash

set -e
[[ $- == *i* ]] && tput setaf 2
echo "Installing screen program"

echo """
A 4-digit 7-segment LED, 12 pins was used to test this script, but other kinds of similar components could be used

GPIO mapping

--------------------------
| Device  | Raspberry Pi |
--------------------------
| D1      | GPIO 11      |
| A       | GPIO 5       |
| F       | GPIO 6       |
| D2      | GPIO 13      |
| D3      | GPIO 19      |
| B       | GPIO 26      |
| E       | GPIO 4       |
| D       | GPIO 17      |
| Decimal | GPIO 27      |
| C       | GPIO 22      |
| G       | GPIO 10      |
| D4      | GPIO 9       |
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
OLT_SCREEN_DEVICE_TYPE=`curl -X POST \
  https://api.$OLT_PLATFORM/v1/device-types \
  -H "Authorization: Bearer $OLT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{
  \"name\": \"Screen_$dt\",
  \"schema\": {
    \"actions\": {
      \"updateNumber\": {
        \"type\": \"object\",
        \"properties\": {
          \"number\": {
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
OLT_SCREEN_DEVICE=`curl -X POST \
  https://api.$OLT_PLATFORM/v1/devices \
  -H "Authorization: Bearer $OLT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{
  \"info\": {
    \"name\": \"Screen_$dt\",
    \"deviceTypeId\": \"$OLT_SCREEN_DEVICE_TYPE\"
  }
}" | \
python3 -c "import sys, json; print(json.load(sys.stdin)['data']['id'])"`

if [ -d /home/pi/screen ]; then
  rm -rf /home/pi/screen;
fi
mkdir -p /home/pi/screen

openssl ecparam -out /home/pi/screen/device_key.pem -name prime256v1 -genkey
if [ ! -n "$OLT_TENANT" ]; then
  read -p "Provide your Tenant name: " OLT_TENANT;
fi

if [ ! -n "$OLT_SCREEN_DEVICE" ]; then
  read -p "Provide your Device name: " OLT_SCREEN_DEVICE;
fi
openssl req -new -key /home/pi/screen/device_key.pem -x509 -days 365 -out /home/pi/screen/device_cert.pem -subj '/O=$OLT_TENANT/CN=$OLT_SCREEN_DEVICE'

echo "Your device certificate is:"
[[ $- == *i* ]] && tput sgr0
OLT_DEVICE_CERTIFICATE=$(</home/pi/screen/device_cert.pem)
OLT_DEVICE_CERTIFICATE="{\"cert\": \"${OLT_DEVICE_CERTIFICATE//$'\n'/\\\n}\", \"status\":\"valid\"}"

curl -X POST \
  "https://api.$OLT_PLATFORM/v1/devices/$OLT_SCREEN_DEVICE/certificates" \
  -H "Authorization: Bearer $OLT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "$OLT_DEVICE_CERTIFICATE"

cat << 'EOF' > /home/pi/screen/screen.py
#!/usr/bin/python3

import RPi.GPIO as GPIO
import json
import time
import paho.mqtt.client as mqtt #import the client1
import ssl

GPIO.setmode(GPIO.BCM)

A = 5
B = 26
C = 22
D = 17
E = 4
F = 6
G = 10
DP = 27
FIRST = 11
SECOND = 13
THIRD = 19
FOURTH = 9

GPIO.setup(A, GPIO.OUT)
GPIO.output(A, 0)

GPIO.setup(B, GPIO.OUT)
GPIO.output(B, 0)

GPIO.setup(C, GPIO.OUT)
GPIO.output(C, 0)

GPIO.setup(D, GPIO.OUT)
GPIO.output(D, 0)

GPIO.setup(E, GPIO.OUT)
GPIO.output(E, 0)

GPIO.setup(F, GPIO.OUT)
GPIO.output(F, 0)

GPIO.setup(G, GPIO.OUT)
GPIO.output(G, 0)

GPIO.setup(DP, GPIO.OUT)
GPIO.output(DP, 0)

GPIO.setup(FIRST, GPIO.OUT)
GPIO.output(FIRST, 0)

GPIO.setup(SECOND, GPIO.OUT)
GPIO.output(SECOND, 0)

GPIO.setup(THIRD, GPIO.OUT)
GPIO.output(THIRD, 0)

GPIO.setup(FOURTH, GPIO.OUT)
GPIO.output(FOURTH, 0)


EOF

echo "url=\"mqtt.$OLT_PLATFORM\"" >> /home/pi/screen/screen.py

cat << 'EOF' >> /home/pi/screen/screen.py

ca = "/home/pi/raspberrypi/olt_ca.pem"
cert = "/home/pi/screen/device_cert.pem"
private = "/home/pi/screen/device_key.pem"

def zero():
    GPIO.output(A, 1)
    GPIO.output(B, 1)
    GPIO.output(C, 1)
    GPIO.output(D, 1)
    GPIO.output(E, 1)
    GPIO.output(F, 1)
    GPIO.output(G, 0)
    GPIO.output(DP, 0)

def one():
    GPIO.output(A, 0)
    GPIO.output(B, 1)
    GPIO.output(C, 1)
    GPIO.output(D, 0)
    GPIO.output(E, 0)
    GPIO.output(F, 0)
    GPIO.output(G, 0)
    GPIO.output(DP, 0)

def two():
    GPIO.output(A, 1)
    GPIO.output(B, 1)
    GPIO.output(C, 0)
    GPIO.output(D, 1)
    GPIO.output(E, 1)
    GPIO.output(F, 0)
    GPIO.output(G, 1)
    GPIO.output(DP, 0)

def three():
    GPIO.output(A, 1)
    GPIO.output(B, 1)
    GPIO.output(C, 1)
    GPIO.output(D, 1)
    GPIO.output(E, 0)
    GPIO.output(F, 0)
    GPIO.output(G, 1)
    GPIO.output(DP, 0)

def four():
    GPIO.output(A, 0)
    GPIO.output(B, 1)
    GPIO.output(C, 1)
    GPIO.output(D, 0)
    GPIO.output(E, 0)
    GPIO.output(F, 1)
    GPIO.output(G, 1)
    GPIO.output(DP, 0)

def five():
    GPIO.output(A, 1)
    GPIO.output(B, 0)
    GPIO.output(C, 1)
    GPIO.output(D, 1)
    GPIO.output(E, 0)
    GPIO.output(F, 1)
    GPIO.output(G, 1)
    GPIO.output(DP, 0)

def six():
    GPIO.output(A, 1)
    GPIO.output(B, 0)
    GPIO.output(C, 1)
    GPIO.output(D, 1)
    GPIO.output(E, 1)
    GPIO.output(F, 1)
    GPIO.output(G, 1)
    GPIO.output(DP, 0)

def seven():
    GPIO.output(A, 1)
    GPIO.output(B, 1)
    GPIO.output(C, 1)
    GPIO.output(D, 0)
    GPIO.output(E, 0)
    GPIO.output(F, 0)
    GPIO.output(G, 0)
    GPIO.output(DP, 0)

def eight():
    GPIO.output(A, 1)
    GPIO.output(B, 1)
    GPIO.output(C, 1)
    GPIO.output(D, 1)
    GPIO.output(E, 1)
    GPIO.output(F, 1)
    GPIO.output(G, 1)
    GPIO.output(DP, 0)

def nine():
    GPIO.output(A, 1)
    GPIO.output(B, 1)
    GPIO.output(C, 1)
    GPIO.output(D, 1)
    GPIO.output(E, 0)
    GPIO.output(F, 1)
    GPIO.output(G, 1)
    GPIO.output(DP, 0)

def empty():
    GPIO.output(A, 0)
    GPIO.output(B, 0)
    GPIO.output(C, 0)
    GPIO.output(D, 0)
    GPIO.output(E, 0)
    GPIO.output(F, 0)
    GPIO.output(G, 0)
    GPIO.output(DP, 0)

options = {
  0  : zero,
  1  : one,
  2  : two,
  3  : three,
  4  : four,
  5  : five,
  6  : six,
  7  : seven,
  8  : eight,
  9  : nine,
  10 : empty
}

def showNumber(num):
    options[num]()


def displayNumber(number):
    if number > 999 :
        firstdigit = int(number / 1000)
    else :
        firstdigit = 10
    if number > 99 :
        seconddigit = int((number % 1000) / 100)
    else :
        seconddigit = 10
    if number > 9 :
        thirddigit = int(number % 1000 % 100 / 10)
    else :
        thirddigit = 10
    fourthdigit = int(number % 1000 % 100 % 10 / 1)
    showNumber(firstdigit)
    GPIO.output(FIRST, 0)
    GPIO.output(SECOND, 1)
    GPIO.output(THIRD, 1)
    GPIO.output(FOURTH, 1)
    time.sleep(0.001)
    showNumber(seconddigit)
    GPIO.output(FIRST, 1)
    GPIO.output(SECOND, 0)
    GPIO.output(THIRD, 1)
    GPIO.output(FOURTH, 1)
    time.sleep(0.001)
    showNumber(thirddigit)
    GPIO.output(FIRST, 1)
    GPIO.output(SECOND, 1)
    GPIO.output(THIRD, 0)
    GPIO.output(FOURTH, 1)
    time.sleep(0.001)
    showNumber(fourthdigit)
    GPIO.output(FIRST, 1)
    GPIO.output(SECOND, 1)
    GPIO.output(THIRD, 1)
    GPIO.output(FOURTH, 0)
    time.sleep(0.001)

def on_message(client, userdata, message):
    msg = message.payload
    parsed_json = json.loads(msg)
    distance = int(round(float(parsed_json["payload"]["number"])))
    displayNumber(distance)

def on_connect(client, userdata, flags, rc):

EOF

echo "    mqttc.subscribe(\"devices/$OLT_SCREEN_DEVICE/actions\")" >> /home/pi/screen/screen.py

cat << 'EOF' >> /home/pi/screen/screen.py
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

chmod +x /home/pi/screen/screen.py

cat << 'EOF' > /home/pi/screen/cron.sh
#!/bin/bash

kill $(ps aux | grep '[s]creen.py' | awk '{print $2}')
/usr/bin/python3 /home/pi/screen/screen.py > /home/pi/iot.log 2>&1 &

EOF

chmod +x /home/pi/screen/cron.sh

crontab -l > /tmp/crontabentry 2>&1 || true
if grep -q "no crontab" /tmp/crontabentry; then
  echo -e "\n* * * * * /home/pi/screen/cron.sh > /home/pi/iot.log 2>&1 \n" > /tmp/crontabentry
  crontab /tmp/crontabentry
fi
if ! grep -q "screen/cron.sh" /tmp/crontabentry; then
  echo -e "\n* * * * * /home/pi/screen/cron.sh > /home/pi/iot.log 2>&1 \n" >> /tmp/crontabentry
  crontab /tmp/crontabentry
fi

crontab -l

mkdir -p /home/pi/out
echo $OLT_SCREEN_DEVICE_TYPE > /home/pi/out/screen_type.txt
echo $OLT_SCREEN_DEVICE > /home/pi/out/screen.txt

[[ $- == *i* ]] && tput setaf 2
echo "Installation complete"
[[ $- == *i* ]] && tput sgr0
exit 0
