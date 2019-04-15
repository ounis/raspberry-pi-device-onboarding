#!/bin/bash

[[ $- == *i* ]] && tput setaf 2
echo "Installing link program"
[[ $- == *i* ]] && tput sgr0

rm -rf /home/pi/link
mkdir /home/pi/link

read -p "Provide your API Authentication-Token: " token
read -p "Provide Distance Device Id: " distance
read -p "Provide Screen Device Id: " screen

cat << 'EOF' > /home/pi/link/link.py
#!/usr/bin/python

import requests
import json

url = "https://api.dev.olt-dev.io/v1/devices/"
EOF

echo "jwt = \"Bearer $token\"" >> /home/pi/link/link.py
echo "contentType = \"application/json\""  >> /home/pi/link/link.py
echo "distanceCensor = \"$distance\""  >> /home/pi/link/link.py
echo "screen = \"$screen\""  >> /home/pi/link/link.py

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

crontab -l > /tmp/crontabentry
if ! grep -q "link/cron.sh" /tmp/crontabentry; then
  echo '* * * * * /home/pi/link/cron.sh' >> /tmp/crontabentry
  crontab /tmp/crontabentry
fi
if grep -q "no crontab" /tmp/crontabentry; then
  echo '* * * * * /home/pi/link/cron.sh' > /tmp/crontabentry
  crontab /tmp/crontabentry
fi

[[ $- == *i* ]] && tput setaf 2
echo "Installation complete"
[[ $- == *i* ]] && tput sgr0