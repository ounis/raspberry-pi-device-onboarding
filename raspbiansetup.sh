#!/bin/bash

set -e
[[ $- == *i* ]] && tput setaf 2
echo "Insttalling a Raspberry Pi"
echo "Install Mosqitto"
[[ $- == *i* ]] && tput sgr0
sudo wget https://repo.mosquitto.org/debian/mosquitto-repo.gpg.key -P /tmp/
sudo apt-key add /tmp/mosquitto-repo.gpg.key
sudo wget http://repo.mosquitto.org/debian/mosquitto-stretch.list -P /etc/apt/sources.list.d/
sudo apt-get update -y
sudo apt-get install -y mosquitto mosquitto-clients

[[ $- == *i* ]] && tput setaf 2
echo "Install some other dependencies (Could be skipped)"
[[ $- == *i* ]] && tput sgr0
sudo apt-get install -y python-smbus
sudo apt-get install -y python3-pip
sudo apt-get install -y python-pip
sudo apt-get install -y python-requests
sudo pip3 install paho-mqtt
sudo pip install paho-mqtt
sudo pip install RPi.GPIO

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
OLT_RASPBERRY_DEVICE_TYPE=`curl -X POST \
  https://api.$OLT_PLATFORM/v1/device-types \
  -H "Authorization: Bearer $OLT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{
  \"name\": \"RaspberryPi_$dt\",
  \"schema\": {
    \"configuration\": {
      \"ipaddress\": {
        \"type\": \"string\"
      },
      \"temperature\": {
        \"type\": \"string\"
      }
    }
  }
}" | \
python3 -c "import sys, json; print(json.load(sys.stdin)['data']['id'])"`

[[ $- == *i* ]] && tput setaf 2
echo "Create device"
[[ $- == *i* ]] && tput sgr0
OLT_RASPBERRY_DEVICE=`curl -X POST \
  https://api.$OLT_PLATFORM/v1/devices \
  -H "Authorization: Bearer $OLT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{
  \"info\": {
    \"name\": \"RaspberryPi_$dt\",
    \"deviceTypeId\": \"$OLT_RASPBERRY_DEVICE_TYPE\"
  }
}" | \
python3 -c "import sys, json; print(json.load(sys.stdin)['data']['id'])"`

[[ $- == *i* ]] && tput setaf 2
echo "Generate certificate & key"
[[ $- == *i* ]] && tput sgr0
if [ -d /home/pi/raspberrypi ]; then
  rm -rf /home/pi/raspberrypi;
fi
mkdir /home/pi/raspberrypi
openssl ecparam -out /home/pi/raspberrypi/device_key.pem -name prime256v1 -genkey
if [ ! -n "$OLT_TENANT" ]; then
  read -p "Provide your Tenant name: " OLT_TENANT;
fi

if [ ! -n "$OLT_RASPBERRY_DEVICE" ]; then
  read -p "Provide your Device name: " OLT_RASPBERRY_DEVICE;
fi
openssl req -new -key /home/pi/raspberrypi/device_key.pem -x509 -days 365 -out /home/pi/raspberrypi/device_cert.pem -subj '/O=$OLT_TENANT/CN=$OLT_RASPBERRY_DEVICE'

[[ $- == *i* ]] && tput setaf 2
echo "Your device certificate is:"
[[ $- == *i* ]] && tput sgr0
OLT_DEVICE_CERTIFICATE=$(</home/pi/raspberrypi/device_cert.pem)
OLT_DEVICE_CERTIFICATE="{\"cert\": \"${OLT_DEVICE_CERTIFICATE//$'\n'/\\\n}\", \"status\":\"valid\"}"

curl -X POST \
  "https://api.$OLT_PLATFORM/v1/devices/$OLT_RASPBERRY_DEVICE/certificates" \
  -H "Authorization: Bearer $OLT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "$OLT_DEVICE_CERTIFICATE"

[[ $- == *i* ]] && tput setaf 2
echo "Save OLT certificate"
[[ $- == *i* ]] && tput sgr0

cat << 'EOF' > /home/pi/raspberrypi/olt_ca.pem
-----BEGIN CERTIFICATE-----
MIICBzCCAaygAwIBAgIBADAKBggqhkjOPQQDAjBcMQswCQYDVQQGEwJERTEOMAwG
A1UEChMFT1NSQU0xDDAKBgNVBAsTA09MVDEvMC0GA1UEAxMmT1NSQU0gT0xUIERl
dmljZVNlcnZpY2VzIFRydXN0QW5jaG9yIDEwIBcNMTgwNjEyMTU1NTMwWhgPMjA1
ODA2MTIxNTU1MzBaMFwxCzAJBgNVBAYTAkRFMQ4wDAYDVQQKEwVPU1JBTTEMMAoG
A1UECxMDT0xUMS8wLQYDVQQDEyZPU1JBTSBPTFQgRGV2aWNlU2VydmljZXMgVHJ1
c3RBbmNob3IgMTBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABIRHefdjW8eKPEpi
RV88sqk/7nqOIDdg4v2KcIsX8LQD94YGkDEDO4Alg3EdtibTXMtztbSiRMmy/BeB
7Fmbr+KjXTBbMB0GA1UdDgQWBBQmEJ8uur+FfHaFxDYw1oeYNu1M6TAfBgNVHSME
GDAWgBQmEJ8uur+FfHaFxDYw1oeYNu1M6TAMBgNVHRMEBTADAQH/MAsGA1UdDwQE
AwIBBjAKBggqhkjOPQQDAgNJADBGAiEA1dAeBWcIDUyOzuQSzhO0cajg3mZfiHp/
NwryIKRR9fgCIQDKqKmKv1STjPEePu4NL2YEqsVauaVl4CVQIYVjEwN3cw==
-----END CERTIFICATE-----
EOF

[[ $- == *i* ]] && tput setaf 2
echo "Prepare to send ip address to your device in OLT platform"
[[ $- == *i* ]] && tput sgr0
cat << 'EOF' > /home/pi/raspberrypi/ipmqtt.sh
#!/bin/bash

EOF

if [ ! -n "$NETWORK_INTERFACE" ]; then
  read -p "Provide Device network interface (eth0, wlan0, etc...): " NETWORK_INTERFACE;
fi

echo "ip=\`/sbin/ifconfig $NETWORK_INTERFACE | grep 'inet ' | awk '{print \$2}'\`" >> /home/pi/raspberrypi/ipmqtt.sh

cat << 'EOF' >> /home/pi/raspberrypi/ipmqtt.sh

reading=`vcgencmd measure_temp`
prefix="temp="
suffix="'C"
reading="${reading#"$prefix"}"
temperature="${reading%"$suffix"}"

msg=$(printf '{ "type": "configuration", "value": { "ipaddress": "%s", "temperature": "%s"} }' "$ip" "$temperature")

EOF

echo "url=\"mqtt.$OLT_PLATFORM\"" >> /home/pi/raspberrypi/ipmqtt.sh

cat << 'EOF' >> /home/pi/raspberrypi/ipmqtt.sh

/usr/bin/mosquitto_pub -h "$url" \
-p 8883 \
--cafile /home/pi/raspberrypi/olt_ca.pem \
--cert /home/pi/raspberrypi/device_cert.pem \
--key /home/pi/raspberrypi/device_key.pem \
-m "$msg" \
-V mqttv311 \
-t data-ingest \
-d \

EOF

chmod +x /home/pi/raspberrypi/ipmqtt.sh

crontab -l > /tmp/crontabentry 2>&1 || true
if grep -q "no crontab" /tmp/crontabentry; then
  echo -e "\n* * * * * /home/pi/raspberrypi/ipmqtt.sh > /home/pi/iot.log 2>&1 \n" > /tmp/crontabentry
  crontab /tmp/crontabentry
fi
if ! grep -q "raspberrypi/ipmqtt.sh" /tmp/crontabentry; then
  echo -e "\n* * * * * /home/pi/raspberrypi/ipmqtt.sh > /home/pi/iot.log 2>&1 \n" >> /tmp/crontabentry
  crontab /tmp/crontabentry
fi

crontab -l

/home/pi/raspberrypi/ipmqtt.sh

sleep 5

IP_ADDRESS=`curl -X GET \
  "https://api.$OLT_PLATFORM/v1/devices/$OLT_RASPBERRY_DEVICE/state" \
  -H "Authorization: Bearer $OLT_TOKEN" | \
python3 -c "import sys, json; print(json.load(sys.stdin)['data']['configuration']['ipaddress'])"`

diff <(echo "$IP_ADDRESS" ) <(echo `/sbin/ifconfig $NETWORK_INTERFACE | grep 'inet ' | awk '{print $2}'`)

mkdir -p /home/pi/out

echo $OLT_RASPBERRY_DEVICE_TYPE > /home/pi/out/raspberry_type.txt
echo $OLT_RASPBERRY_DEVICE > /home/pi/out/raspberry.txt

[[ $- == *i* ]] && tput setaf 2
echo "Installation complete"
[[ $- == *i* ]] && tput sgr0
exit 0
