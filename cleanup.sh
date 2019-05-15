#!/bin/bash

set -e

if [ ! -n "$OLT_PLATFORM" ]; then
  read -p "Provide your platform URL: " OLT_PLATFORM;
fi

[[ $- == *i* ]] && tput setaf 2
echo "Delete Camera"
[[ $- == *i* ]] && tput sgr0

CODE="$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  "https://api.$OLT_PLATFORM/v1/devices/$OLT_CAMERA_DEVICE" \
  -H "Authorization: Bearer $OLT_TOKEN")"
diff <(echo "$CODE" ) <(echo "204")

[[ $- == *i* ]] && tput setaf 2
echo "Delete Camera Type"
[[ $- == *i* ]] && tput sgr0

CODE="$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  "https://api.$OLT_PLATFORM/v1/device-types/$OLT_CAMERA_DEVICE_TYPE" \
  -H "Authorization: Bearer $OLT_TOKEN")"
diff <(echo "$CODE" ) <(echo "204")

[[ $- == *i* ]] && tput setaf 2
echo "Delete Distance"
[[ $- == *i* ]] && tput sgr0

CODE="$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  "https://api.$OLT_PLATFORM/v1/devices/$OLT_DISTANCE_DEVICE" \
  -H "Authorization: Bearer $OLT_TOKEN")"
diff <(echo "$CODE" ) <(echo "204")

[[ $- == *i* ]] && tput setaf 2
echo "Delete Distance Type"
[[ $- == *i* ]] && tput sgr0

CODE="$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  "https://api.$OLT_PLATFORM/v1/device-types/$OLT_DISTANCE_DEVICE_TYPE" \
  -H "Authorization: Bearer $OLT_TOKEN")"
diff <(echo "$CODE" ) <(echo "204")

[[ $- == *i* ]] && tput setaf 2
echo "Delete Presence"
[[ $- == *i* ]] && tput sgr0

CODE="$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  "https://api.$OLT_PLATFORM/v1/devices/$OLT_PRESENCE_DEVICE" \
  -H "Authorization: Bearer $OLT_TOKEN")"
diff <(echo "$CODE" ) <(echo "204")

[[ $- == *i* ]] && tput setaf 2
echo "Delete Presence Type"
[[ $- == *i* ]] && tput sgr0

CODE="$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  "https://api.$OLT_PLATFORM/v1/device-types/$OLT_PRESENCE_DEVICE_TYPE" \
  -H "Authorization: Bearer $OLT_TOKEN")"
diff <(echo "$CODE" ) <(echo "204")

[[ $- == *i* ]] && tput setaf 2
echo "Delete Rgb"
[[ $- == *i* ]] && tput sgr0

CODE="$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  "https://api.$OLT_PLATFORM/v1/devices/$OLT_RGB_DEVICE" \
  -H "Authorization: Bearer $OLT_TOKEN")"
diff <(echo "$CODE" ) <(echo "204")

[[ $- == *i* ]] && tput setaf 2
echo "Delete Rgb Type"
[[ $- == *i* ]] && tput sgr0

CODE="$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  "https://api.$OLT_PLATFORM/v1/device-types/$OLT_RGB_DEVICE_TYPE" \
  -H "Authorization: Bearer $OLT_TOKEN")"
diff <(echo "$CODE" ) <(echo "204")

[[ $- == *i* ]] && tput setaf 2
echo "Delete Screen"
[[ $- == *i* ]] && tput sgr0

CODE="$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  "https://api.$OLT_PLATFORM/v1/devices/$OLT_SCREEN_DEVICE" \
  -H "Authorization: Bearer $OLT_TOKEN")"
diff <(echo "$CODE" ) <(echo "204")

[[ $- == *i* ]] && tput setaf 2
echo "Delete Screen Type"
[[ $- == *i* ]] && tput sgr0

CODE="$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  "https://api.$OLT_PLATFORM/v1/device-types/$OLT_SCREEN_DEVICE_TYPE" \
  -H "Authorization: Bearer $OLT_TOKEN")"
diff <(echo "$CODE" ) <(echo "204")

[[ $- == *i* ]] && tput setaf 2
echo "Delete Hue"
[[ $- == *i* ]] && tput sgr0

CODE="$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  "https://api.$OLT_PLATFORM/v1/devices/$OLT_HUE_DEVICE" \
  -H "Authorization: Bearer $OLT_TOKEN")"
diff <(echo "$CODE" ) <(echo "204")

[[ $- == *i* ]] && tput setaf 2
echo "Delete Hue Type"
[[ $- == *i* ]] && tput sgr0

CODE="$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  "https://api.$OLT_PLATFORM/v1/device-types/$OLT_HUE_DEVICE_TYPE" \
  -H "Authorization: Bearer $OLT_TOKEN")"
diff <(echo "$CODE" ) <(echo "204")

[[ $- == *i* ]] && tput setaf 2
echo "Delete Hue lightbulbs"
[[ $- == *i* ]] && tput sgr0

for filename in /home/pi/out/hue_lightbulb_device_*.txt; do
    echo "Delete Hue lightbulb $filename"
    export OLT_HUE_LIGHTBULB_DEVICE=`cat $filename`
    CODE="$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
      "https://api.$OLT_PLATFORM/v1/devices/$OLT_HUE_LIGHTBULB_DEVICE" \
      -H "Authorization: Bearer $OLT_TOKEN")"
    diff <(echo "$CODE" ) <(echo "204")
done

[[ $- == *i* ]] && tput setaf 2
echo "Delete Hue lightbulb Type"
[[ $- == *i* ]] && tput sgr0

CODE="$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  "https://api.$OLT_PLATFORM/v1/device-types/$OLT_HUE_LIGHTBULB_DEVICE_TYPE" \
  -H "Authorization: Bearer $OLT_TOKEN")"
diff <(echo "$CODE" ) <(echo "204")

[[ $- == *i* ]] && tput setaf 2
echo "Delete Raspberry"
[[ $- == *i* ]] && tput sgr0

CODE="$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  "https://api.$OLT_PLATFORM/v1/devices/$OLT_RASPBERRY_DEVICE" \
  -H "Authorization: Bearer $OLT_TOKEN")"
diff <(echo "$CODE" ) <(echo "204")

[[ $- == *i* ]] && tput setaf 2
echo "Delete Raspberry Type"
[[ $- == *i* ]] && tput sgr0

CODE="$(curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  "https://api.$OLT_PLATFORM/v1/device-types/$OLT_RASPBERRY_DEVICE_TYPE" \
  -H "Authorization: Bearer $OLT_TOKEN")"
diff <(echo "$CODE" ) <(echo "204")