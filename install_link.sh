#!/bin/bash

set -e
[[ $- == *i* ]] && tput setaf 2
echo "Installing link program"
[[ $- == *i* ]] && tput sgr0

if [ -d /home/pi/link ]; then
  rm -rf /home/pi/link;
fi
mkdir -p /home/pi/link

if [ ! -n "$OLT_TOKEN" ]; then
  read -p "Provide your API Authentication-Token: " OLT_TOKEN;
fi

if [ ! -n "$OLT_DISTANCE_DEVICE" ]; then
  read -p "Provide Distance Device Id: " OLT_DISTANCE_DEVICE;
fi

if [ ! -n "$OLT_SCREEN_DEVICE" ]; then
  read -p "Provide Screen Device Id: " OLT_SCREEN_DEVICE;
fi

cat << 'EOF' > /home/pi/link/link.py
#!/usr/bin/python

import requests
import json

url = "https://api.dev.olt-dev.io/v1/devices/"
EOF

echo "jwt = \"Bearer $OLT_TOKEN\"" >> /home/pi/link/link.py
echo "contentType = \"application/json\""  >> /home/pi/link/link.py
echo "distanceCensor = \"$OLT_DISTANCE_DEVICE\""  >> /home/pi/link/link.py
echo "screen = \"$OLT_SCREEN_DEVICE\""  >> /home/pi/link/link.py

cat << 'EOF' >> /home/pi/link/link.py
try:
    while True:
        try:
            response = requests.get(url + distanceCensor + '/state',
                headers={
                    "content-type":contentType,
                    "Authorization":jwt})
            data = json.loads(response.content)
            try:
                distance = float(data["data"]["configuration"]["distance"])
            except ValueError:
                distance = 0

            payload = '{"number": "' + str(distance) + '"}'

            response = requests.post(url + screen + '/actions',
                headers={
                    "content-type":contentType,
                    "Authorization":jwt},
                data='{"action": "updateNumber", "payload": ' + payload + '}')
        except requests.ConnectionError:
            break
except KeyboardInterrupt:
    pass

EOF

chmod +x /home/pi/link/link.py

cat << 'EOF' > /home/pi/link/cron.sh
#!/bin/bash

kill $(ps aux | grep '[l]ink.py' | awk '{print $2}')
/usr/bin/python /home/pi/link/link.py &

EOF

chmod +x /home/pi/link/cron.sh

crontab -l > /tmp/crontabentry 2>&1 || true
if grep -q "no crontab" /tmp/crontabentry; then
  echo -e "\n* * * * * /home/pi/link/ipmqtt.sh\n" > /tmp/crontabentry
  crontab /tmp/crontabentry
fi
if ! grep -q "link/cron.sh" /tmp/crontabentry; then
  echo -e "\n* * * * * /home/pi/link/ipmqtt.sh\n" >> /tmp/crontabentry
  crontab /tmp/crontabentry
fi

crontab -l

[[ $- == *i* ]] && tput setaf 2
echo "Installation complete"
[[ $- == *i* ]] && tput sgr0
exit 0
