#!/bin/bash

tput setaf 2
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
tput sgr0

rm -rf /home/pi/screen
mkdir /home/pi/screen

openssl ecparam -out /home/pi/screen/device_key.pem -name prime256v1 -genkey
read -p "Provide your Tenant name (or Id): " tenant
read -p "Provide your Device name (or Id): " device
read -p "Provide your Device  Id: " deviceId
openssl req -new -key /home/pi/screen/device_key.pem -x509 -days 365 -out /home/pi/screen/device_cert.pem -subj '/O=$tenant/CN=$device'

tput setaf 2
echo "Add this certificate to your device"
tput sgr0
cat /home/pi/screen/device_cert.pem

cat << 'EOF' > /home/pi/screen/screen.py
#!/usr/bin/python

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

url = "mqtt.dev.olt-dev.io"
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
        seconddigit = 10;
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

echo "    mqttc.subscribe(\"devices/$deviceId/actions\")" >> /home/pi/screen/screen.py

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
/usr/bin/python /home/pi/screen/screen.py &

EOF

chmod +x /home/pi/screen/cron.sh

crontab -l > /tmp/crontabentry
if grep -q "screen/cron.sh" /tmp/crontabentry; then
  echo '* * * * * /home/pi/screen/cron.sh' >> /tmp/crontabentry
  crontab /tmp/crontabentry
fi

echo """
Please Make sure your Device type has a structure similar to this one

{
  "actions": {
    "updateNumber": {
      "type": "object",
      "properties": {
        "number": {
          "type": "string"
        }
      }
    }
  }
}

"""

tput setaf 2
echo "Installation complete"
tput sgr0
