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

rm -rf /home/pi/presence
mkdir -p /home/pi/presence

openssl ecparam -out /home/pi/presence/device_key.pem -name prime256v1 -genkey
read -p "Provide your Tenant name (or Id): " tenant
read -p "Provide your Device name (or Id): " device
openssl req -new -key /home/pi/presence/device_key.pem -x509 -days 365 -out /home/pi/presence/device_cert.pem -subj '/O=$tenant/CN=$device'

[[ $- == *i* ]] && tput setaf 2
echo "Add this certificate to your device"
[[ $- == *i* ]] && tput sgr0
cat /home/pi/presence/device_cert.pem

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

crontab -l > /tmp/crontabentry
if ! grep -q "presence/cron.sh" /tmp/crontabentry; then
  echo '* * * * * /home/pi/presence/cron.sh' >> /tmp/crontabentry
  crontab /tmp/crontabentry
fi
if grep -q "no crontab" /tmp/crontabentry; then
  echo '* * * * * /home/pi/presence/cron.sh' > /tmp/crontabentry
  crontab /tmp/crontabentry
fi

echo """
Please Make sure your Device type has a structure similar to this one

{
  \"configuration\": {
    \"presence\": {
      \"type\": \"integer\"
    }
  }
}

"""

[[ $- == *i* ]] && tput setaf 2
echo "Installation complete"
[[ $- == *i* ]] && tput sgr0