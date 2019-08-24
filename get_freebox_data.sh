#!/bin/bash

ts=$(date +%s%N)

FREEBOX_HOST="Freebox"

GREEN_COLOR='\033[0;32m'
NO_COLOR='\033[0m' # No Color

MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
TOKEN_FILE="$MYDIR/freebox_token.conf"
LIBRARY_FILE="$MYDIR/freeboxos_zabbix_library.sh"
DATA_VALUES_FILE="$MYDIR/data_values.txt"

if test ! -f "$TOKEN_FILE"; then
    echo "$TOKEN_FILE does not exist --> EXIT"
    exit 1
fi

if test ! -f "$LIBRARY_FILE"; then
    echo "$LIBRARY_FILE does not exist --> EXIT"
    exit 1
fi


. "$TOKEN_FILE"
. "$LIBRARY_FILE"

# Login
echo -n "Login to Freebox... "
login_freebox "$MY_APP_ID" "$MY_APP_TOKEN"
echo -e "${GREEN_COLOR}[OK]${NO_COLOR}"



# -------------------------------------------------------------------------------
# RETRIEVE INFOS - START
# -------------------------------------------------------------------------------

#FTTH Link
#answer=$(call_freebox_api '/connection/ftth')
#echo $answer

#XDSL Link
#answer=$(call_freebox_api '/connection/xdsl')
#echo $answer

#FULL Data Link
echo -n "Get connection full datas... "
answer=$(call_freebox_api '/connection/full/')
result_bytes_up=$(get_json_value_for_key "$answer" 'result.bytes_up')
result_bytes_down=$(get_json_value_for_key "$answer" 'result.bytes_down')
result_state=$(get_json_value_for_key "$answer" 'result.state')
result_media=$(get_json_value_for_key "$answer" 'result.media')
echo -e "${GREEN_COLOR}[OK]${NO_COLOR}"

#System
echo -n "Get System datas... "
answer=$(call_freebox_api '/system/')
result_fans_0_value=$(get_json_value_for_key "$answer" 'result.fans[0].value')
result_sensors_0_value=$(get_json_value_for_key "$answer" 'result.sensors[0].value')
result_sensors_1_value=$(get_json_value_for_key "$answer" 'result.sensors[1].value')
result_sensors_2_value=$(get_json_value_for_key "$answer" 'result.sensors[2].value')
result_sensors_3_value=$(get_json_value_for_key "$answer" 'result.sensors[3].value')
result_uptime_val=$(get_json_value_for_key "$answer" 'result.uptime_val')
echo -e "${GREEN_COLOR}[OK]${NO_COLOR}"

#LAN Browser
echo -n "Get LAN Browser datas... "
answer=$(call_freebox_api '/lan/browser/pub/')
result_nb_active_devices=$(grep -o "\"active\"\:true,\"id\"\:" <<<"$answer" | grep -c .)
echo -e "${GREEN_COLOR}[OK]${NO_COLOR}"

echo -n "Get Switch port datas... "
epochNow=$EPOCHSECONDS
epochPast=$(expr $epochNow - 60)
for i in {1..4}; do 
    answer=$(call_freebox_api "/rrd/" "{\"db\":\"switch\",\"precision\":1,\"date_start\":$epochPast,\"date_end\":$epochNow,\"fields\":[\"tx_${i}\"]}" )
    declare "result_rrd_tx_$i"=$(get_json_value_for_key "$answer" "result.data[0].tx_$i")
    answer=$(call_freebox_api "/rrd/" "{\"db\":\"switch\",\"precision\":1,\"date_start\":$epochPast,\"date_end\":$epochNow,\"fields\":[\"rx_${i}\"]}" )
    declare "result_rrd_rx_$i"=$(get_json_value_for_key "$answer" "result.data[0].rx_$i")
done
echo -e "${GREEN_COLOR}[OK]${NO_COLOR}"

# -------------------------------------------------------------------------------
# RETRIEVE INFOS - END
# -------------------------------------------------------------------------------

# Logout
echo -n "Logout to Freebox... "
logout_freebox
echo -e "${GREEN_COLOR}[OK]${NO_COLOR}"

echo -n "Write to data file... "
cat > $DATA_VALUES_FILE <<EOF
$FREEBOX_HOST freebox.result.bytes_up $result_bytes_up
$FREEBOX_HOST freebox.result.bytes_down $result_bytes_down
$FREEBOX_HOST freebox.result.state $result_state
$FREEBOX_HOST freebox.result.media $result_media
$FREEBOX_HOST freebox.result.fans.0.value $result_fans_0_value
$FREEBOX_HOST freebox.result.sensors.0.value $result_sensors_0_value
$FREEBOX_HOST freebox.result.sensors.1.value $result_sensors_1_value
$FREEBOX_HOST freebox.result.sensors.2.value $result_sensors_2_value
$FREEBOX_HOST freebox.result.sensors.3.value $result_sensors_3_value
$FREEBOX_HOST freebox.result.uptime_val $result_uptime_val
$FREEBOX_HOST freebox.result.nbActiveDevices $result_nb_active_devices
$FREEBOX_HOST freebox.result.rrd_tx_1 $result_rrd_tx_1
$FREEBOX_HOST freebox.result.rrd_rx_1 $result_rrd_rx_1
$FREEBOX_HOST freebox.result.rrd_tx_2 $result_rrd_tx_2
$FREEBOX_HOST freebox.result.rrd_rx_2 $result_rrd_rx_2
$FREEBOX_HOST freebox.result.rrd_tx_3 $result_rrd_tx_3
$FREEBOX_HOST freebox.result.rrd_rx_3 $result_rrd_rx_3
$FREEBOX_HOST freebox.result.rrd_tx_4 $result_rrd_tx_4
$FREEBOX_HOST freebox.result.rrd_rx_4 $result_rrd_rx_4
EOF

echo -e "${GREEN_COLOR}[OK]${NO_COLOR}"

echo -n "Send data to Zabbix... "
#zabbix_sender -z 127.0.0.1 -i $DATA_VALUES_FILE
zabbix_sender -z 127.0.0.1 -i $DATA_VALUES_FILE >/dev/null 2>&1
echo -e "${GREEN_COLOR}[OK]${NO_COLOR}"

te=$(date +%s%N)

echo "Done in $((($(date +%s%N) - $ts)/1000000)) ms"
