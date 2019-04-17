#!/bin/bash

set -e
[[ $- == *i* ]] && tput setaf 2
echo "Installing distance program"


echo """
A Ultrasonic Sensor HC – SR04 was used to test this script, but other kinds of similar sensors could be used

GPIO mapping

-------------------------
| Device | Raspberry Pi |
-------------------------
| VCC    | VCC 5V       |
| Trig   | GPIO 14      |
| Echo   | GPIO 15      |
| GND    | Ground       |
-------------------------

"""
[[ $- == *i* ]] && tput sgr0

if [ -d /home/pi/distance ]; then
  rm -rf /home/pi/distance
fi
mkdir -p /home/pi/distance

openssl ecparam -out /home/pi/distance/device_key.pem -name prime256v1 -genkey
if [ ! -z ${OLT_TENANT} ] then
  read -p "Provide your Tenant name: " OLT_TENANT;
fi

if [ ! -z ${OLT_DISTANCE_DEVICE} ] then
  read -p "Provide your Device name: " OLT_DISTANCE_DEVICE;
fi
openssl req -new -key /home/pi/distance/device_key.pem -x509 -days 365 -out /home/pi/distance/device_cert.pem -subj '/O=$OLT_TENANT/CN=$OLT_DISTANCE_DEVICE'

[[ $- == *i* ]] && tput setaf 2
echo "Add this certificate to your device"
[[ $- == *i* ]] && tput sgr0
cat /home/pi/distance/device_cert.pem

cat << 'EOF' > /home/pi/distance/distance.py
#!/usr/bin/python

import time
import RPi.GPIO as GPIO
import ssl
import paho.mqtt.client as mqtt

def measure(distance):
  try:
    # This function measures a distance
    GPIO.output(GPIO_TRIGGER, True)
    # Wait 10us
    time.sleep(0.00001)
    GPIO.output(GPIO_TRIGGER, False)
    start = time.time()
    
    while GPIO.input(GPIO_ECHO)==0:
      start = time.time()

    while GPIO.input(GPIO_ECHO)==1:
      stop = time.time()

    elapsed = stop-start
    distance = (elapsed * speedSound)/2
  except UnboundLocalError:
    pass

  return distance

def measure_average(distance):
  # This function takes 3 measurements and
  # returns the average.

  distance1=measure(distance)
  time.sleep(0.1)
  distance2=measure(distance)
  time.sleep(0.1)
  distance3=measure(distance)
  distance = distance1 + distance2 + distance3
  distance = distance / 3
  return distance

# -----------------------
# Main Script
# -----------------------

# Use BCM GPIO references
# instead of physical pin numbers
GPIO.setmode(GPIO.BCM)

# Define GPIO to use on Pi
GPIO_TRIGGER = 14
GPIO_ECHO    = 15

# Speed of sound in cm/s at temperature
temperature = 20
speedSound = 33100 + (0.6*temperature)

print("Ultrasonic Measurement")
print("Speed of sound is",speedSound/100,"m/s at ",temperature,"deg")

# Set pins as output and input
GPIO.setup(GPIO_TRIGGER,GPIO.OUT)  # Trigger
GPIO.setup(GPIO_ECHO,GPIO.IN)      # Echo

# Set trigger to False (Low)
GPIO.output(GPIO_TRIGGER, False)

# Allow module to settle
time.sleep(0.5)

distance = 0

url = "mqtt.dev.olt-dev.io"
ca = "/home/pi/raspberrypi/olt_ca.pem" 
cert = "/home/pi/distance/device_cert.pem"
private = "/home/pi/distance/device_key.pem"

# Wrap main content in a try block so we can
# catch the user pressing CTRL-C and run the
# GPIO cleanup function. This will also prevent
# the user seeing lots of unnecessary error
# messages.
try:
  while True:
    distance = measure_average(distance)
    print("Distance : {0:5.1f}".format(distance))
    distance = "{0:5.1f}\n".format(distance).lstrip()
    message = '{ "type": "configuration", "value": { "distance": "' + distance + '" } }'
    mqttc = mqtt.Client()
    ssl_context = ssl.create_default_context()
    ssl_context.set_alpn_protocols(["mqttv311"])
    ssl_context.load_verify_locations(cafile=ca)
    ssl_context.load_cert_chain(certfile=cert, keyfile=private)
    mqttc.tls_set_context(context=ssl_context)
    mqttc.connect(url, port=8883)
    mqttc.publish("data-ingest", message)

except KeyboardInterrupt:
  # User pressed CTRL-C
  # Reset GPIO settings
  GPIO.cleanup()

EOF

chmod +x /home/pi/distance/distance.py

cat << 'EOF' > /home/pi/distance/simpledistance.py
#!/usr/bin/python

import time
import RPi.GPIO as GPIO
import ssl
import paho.mqtt.client as mqtt

def measure(distance):
  try:
    GPIO.output(GPIO_TRIGGER, True)
    time.sleep(0.00006)
    GPIO.output(GPIO_TRIGGER, False)
    start = time.time()

    while GPIO.input(GPIO_ECHO)==0:
      start = time.time()

    while GPIO.input(GPIO_ECHO)==1:
      stop = time.time()

    elapsed = stop-start
    distance = (elapsed * speedSound)/2
  except UnboundLocalError:
    pass

  return distance


GPIO.setmode(GPIO.BCM)

GPIO_TRIGGER = 14
GPIO_ECHO    = 15

temperature = 20
speedSound = 33100 + (0.6*temperature)

GPIO.setup(GPIO_TRIGGER,GPIO.OUT)
GPIO.setup(GPIO_ECHO,GPIO.IN)

GPIO.output(GPIO_TRIGGER, False)

time.sleep(0.5)

url = "mqtt.dev.olt-dev.io"
ca = "/home/pi/raspberrypi/olt_ca.pem" 
cert = "/home/pi/distance/device_cert.pem"
private = "/home/pi/distance/device_key.pem"

try:
  distance = 0
  while True:
    distance = measure(distance)
    distance = "{0:5.1f}\n".format(distance).lstrip()
    message = '{ "type": "configuration", "value": { "distance": "' + distance + '" } }'
    mqttc = mqtt.Client()
    ssl_context = ssl.create_default_context()
    ssl_context.set_alpn_protocols(["mqttv311"])
    ssl_context.load_verify_locations(cafile=ca)
    ssl_context.load_cert_chain(certfile=cert, keyfile=private)
    mqttc.tls_set_context(context=ssl_context)
    mqttc.connect(url, port=8883)
    mqttc.publish("data-ingest", message)

except KeyboardInterrupt:
  GPIO.cleanup()

EOF

cat << 'EOF' > /home/pi/distance/cron.sh
#!/bin/bash

kill $(ps aux | grep '[d]istance.py' | awk '{print $2}')
/usr/bin/python /home/pi/distance/distance.py &

EOF

chmod +x /home/pi/distance/cron.sh

crontab -l > /tmp/crontabentry
if ! grep -q "distance/cron.sh" /tmp/crontabentry; then
  echo '* * * * * /home/pi/distance/cron.sh' >> /tmp/crontabentry
  crontab /tmp/crontabentry
fi
if grep -q "no crontab" /tmp/crontabentry; then
  echo '* * * * * /home/pi/distance/cron.sh' > /tmp/crontabentry
  crontab /tmp/crontabentry
fi


echo """
Please Make sure your Device type has a structure similar to this one

{
  \"configuration\": {
    \"distance\": {
      \"type\": \"string\"
    }
}

"""

[[ $- == *i* ]] && tput setaf 2
echo "Installation complete"
[[ $- == *i* ]] && tput sgr0