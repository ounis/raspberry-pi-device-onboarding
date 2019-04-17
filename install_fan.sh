#!/bin/bash

set -e
[[ $- == *i* ]] && tput setaf 2
echo "Installing fan program"

echo """
A 30 x 30 mm Fan 5V 7 mA was used to test this script, but other kinds of fans could be used

GPIO mapping

------------------------------------
| Device            | Raspberry Pi |
------------------------------------
| Red wire (VCC 5V) | VGPIO 14     |
| Black wire (Gnd)  | Ground       |
------------------------------------

"""
[[ $- == *i* ]] && tput sgr0

if [ -d /home/pi/fan ]; then
  rm -rf /home/pi/fan;
fi
mkdir -p /home/pi/fan

cat << 'EOF' > /home/pi/fan/fan.py
#!/usr/bin/python

import os
import time
import RPi.GPIO as GPIO

GPIO.setmode(GPIO.BCM)

FAN = 14

GPIO.setup(FAN,GPIO.OUT)
GPIO.output(FAN, 0)

def measure_temp():
        temp = os.popen("vcgencmd measure_temp").readline()
        return (float(temp.replace("temp=", "").replace("'C", "")))

try:
    while (True):
        time.sleep(1)
        temp = measure_temp()
        print(temp)
        if (temp > 50):
            GPIO.output(FAN, 1)
        else:
            GPIO.output(FAN, 0)
except KeyboardInterrupt:
    GPIO.cleanup()

EOF

chmod +x /home/pi/fan/fan.py

cat << 'EOF' > /home/pi/fan/cron.sh
#!/bin/bash

kill $(ps aux | grep '[f]an.py' | awk '{print $2}')
/usr/bin/python /home/pi/fan/fan.py &

EOF

chmod +x /home/pi/fan/cron.sh

crontab -l > /tmp/crontabentry
if ! grep -q "fan/cron.sh" /tmp/crontabentry; then
  echo '* * * * * /home/pi/fan/cron.sh' >> /tmp/crontabentry
  crontab /tmp/crontabentry
fi
if grep -q "no crontab" /tmp/crontabentry; then
  echo '* * * * * /home/pi/fan/cron.sh' > /tmp/crontabentry
  crontab /tmp/crontabentry
fi

[[ $- == *i* ]] && tput setaf 2
echo "Installation complete"
[[ $- == *i* ]] && tput sgr0