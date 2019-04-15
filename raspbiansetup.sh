#!/bin/bash

set -e
[[ $- == *i* ]] && tput setaf 2
echo "Insttalling a Raspberry Pi"
echo "Install Mosqitto"
[[ $- == *i* ]] && tput sgr0
cd /tmp
sudo wget https://repo.mosquitto.org/debian/mosquitto-repo.gpg.key
sudo apt-key add mosquitto-repo.gpg.key
cd /etc/apt/sources.list.d/
sudo wget http://repo.mosquitto.org/debian/mosquitto-stretch.list
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

[[ $- == *i* ]] && tput setaf 2
echo "Generate certificate & key"
[[ $- == *i* ]] && tput sgr0
if [ -d /home/pi/raspberrypi ]; then
  rm -rf /home/pi/raspberrypi
fi

mkdir /home/pi/raspberrypi
# Genereate enough entropy inside the container to generate the ssl key
i=0
while [ ! -d /home/pi/raspberrypi/device_key.pem ] do
  find / > /dev/null 2>&1
  print $i
  i++
done &
openssl ecparam -out /home/pi/raspberrypi/device_key.pem -name prime256v1 -genkey
read -p "Provide your Tenant name: " tenant
read -p "Provide your Device name: " device
openssl req -new -key /home/pi/raspberrypi/device_key.pem -x509 -days 365 -out /home/pi/raspberrypi/device_cert.pem -subj '/O=$tenant/CN=$device'

[[ $- == *i* ]] && tput setaf 2
echo "Your device certificate is:"
[[ $- == *i* ]] && tput sgr0
cat /home/pi/raspberrypi/device_cert.pem
[[ $- == *i* ]] && tput setaf 2
echo "Please copy and paste it in your device certificate section in OLT platform"


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
echo "Make sure your device has in the configuration a String entry called ipaddress"
[[ $- == *i* ]] && tput sgr0
cat << 'EOF' > /home/pi/raspberrypi/ipmqtt.sh
#!/bin/bash

ip=`/sbin/ifconfig wlan0 | grep 'inet ' | awk '{print $2}'`

msg=$(printf '{ "type": "configuration", "value": { "ipaddress": "%s" } }' "$ip")

/usr/bin/mosquitto_pub -h mqtt.dev.olt-dev.io \
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

crontab -l > /tmp/crontabentry
if ! grep -q "raspberrypi/ipmqtt.sh" /tmp/crontabentry; then
  echo '* * * * * /home/pi/raspberrypi/ipmqtt.sh' >> /tmp/crontabentry
  crontab /tmp/crontabentry
fi
if grep -q "no crontab" /tmp/crontabentry; then
  echo '* * * * * /home/pi/raspberrypi/ipmqtt.sh' > /tmp/crontabentry
  crontab /tmp/crontabentry
fi

echo """
Please Make sure your Device type has a structure similar to this one

{
  \"configuration\": {
    \"ipaddress\": {
      \"type\": \"string\"
    }
  }
}

"""

[[ $- == *i* ]] && tput setaf 2
echo "Installation complete"
[[ $- == *i* ]] && tput sgr0