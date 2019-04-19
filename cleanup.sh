#!/bin/bash

set -e

[[ $- == *i* ]] && tput setaf 2
echo "Delete Camera"
[[ $- == *i* ]] && tput sgr0

$CODE=`curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  "https://api.dev.olt-dev.io/v1/devices/$OLT_CAMERA_DEVICE" \
  -H "Authorization: Bearer $OLT_TOKEN"`
diff <(echo "$CODE" ) <(echo "204")

[[ $- == *i* ]] && tput setaf 2
echo "Delete Camera Type"
[[ $- == *i* ]] && tput sgr0

$CODE=`curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  "https://api.dev.olt-dev.io/v1/device-types/$OLT_CAMERA_DEVICE_TYPE" \
  -H "Authorization: Bearer $OLT_TOKEN"`
diff <(echo "$CODE" ) <(echo "204")

[[ $- == *i* ]] && tput setaf 2
echo "Delete Distance"
[[ $- == *i* ]] && tput sgr0

$CODE=`curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  "https://api.dev.olt-dev.io/v1/devices/$OLT_DISTANCE_DEVICE" \
  -H "Authorization: Bearer $OLT_TOKEN"`
diff <(echo "$CODE" ) <(echo "204")

[[ $- == *i* ]] && tput setaf 2
echo "Delete Distance Type"
[[ $- == *i* ]] && tput sgr0

$CODE=`curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  "https://api.dev.olt-dev.io/v1/device-types/$OLT_DISTANCE_DEVICE_TYPE" \
  -H "Authorization: Bearer $OLT_TOKEN"`
diff <(echo "$CODE" ) <(echo "204")

[[ $- == *i* ]] && tput setaf 2
echo "Delete Presence"
[[ $- == *i* ]] && tput sgr0

$CODE=`curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  "https://api.dev.olt-dev.io/v1/devices/$OLT_PRESENCE_DEVICE" \
  -H "Authorization: Bearer $OLT_TOKEN"`
diff <(echo "$CODE" ) <(echo "204")

[[ $- == *i* ]] && tput setaf 2
echo "Delete Presence Type"
[[ $- == *i* ]] && tput sgr0

$CODE=`curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  "https://api.dev.olt-dev.io/v1/device-types/$OLT_PRESENCE_DEVICE_TYPE" \
  -H "Authorization: Bearer $OLT_TOKEN"`
diff <(echo "$CODE" ) <(echo "204")

[[ $- == *i* ]] && tput setaf 2
echo "Delete Rgb"
[[ $- == *i* ]] && tput sgr0

$CODE=`curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  "https://api.dev.olt-dev.io/v1/devices/$OLT_RGB_DEVICE" \
  -H "Authorization: Bearer $OLT_TOKEN"`
diff <(echo "$CODE" ) <(echo "204")

[[ $- == *i* ]] && tput setaf 2
echo "Delete Rgb Type"
[[ $- == *i* ]] && tput sgr0

$CODE=`curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  "https://api.dev.olt-dev.io/v1/device-types/$OLT_RGB_DEVICE_TYPE" \
  -H "Authorization: Bearer $OLT_TOKEN"`
diff <(echo "$CODE" ) <(echo "204")

[[ $- == *i* ]] && tput setaf 2
echo "Delete Screen"
[[ $- == *i* ]] && tput sgr0

$CODE=`curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  "https://api.dev.olt-dev.io/v1/devices/$OLT_SCREEN_DEVICE" \
  -H "Authorization: Bearer $OLT_TOKEN"`
diff <(echo "$CODE" ) <(echo "204")

[[ $- == *i* ]] && tput setaf 2
echo "Delete Screen Type"
[[ $- == *i* ]] && tput sgr0

$CODE=`curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  "https://api.dev.olt-dev.io/v1/device-types/$OLT_SCREEN_DEVICE_TYPE" \
  -H "Authorization: Bearer $OLT_TOKEN"`
diff <(echo "$CODE" ) <(echo "204")

[[ $- == *i* ]] && tput setaf 2
echo "Delete Raspberry"
[[ $- == *i* ]] && tput sgr0

$CODE=`curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  "https://api.dev.olt-dev.io/v1/devices/$OLT_RASPBERRY_DEVICE" \
  -H "Authorization: Bearer $OLT_TOKEN"`
diff <(echo "$CODE" ) <(echo "204")

[[ $- == *i* ]] && tput setaf 2
echo "Delete Raspberry Type"
[[ $- == *i* ]] && tput sgr0

$CODE=`curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  "https://api.dev.olt-dev.io/v1/device-types/$OLT_RASPBERRY_DEVICE_TYPE" \
  -H "Authorization: Bearer $OLT_TOKEN"`
diff <(echo "$CODE" ) <(echo "204")