#!/bin/bash

function concatLineIfNecessary() {
    local strRet="$1"
    local freebox_host="$2"
    local strKey="$3"
    local strValue="$4"

    if [ -z "$strRet" ]; then
        if [ -n "$strValue" ]; then
            strRet="$freebox_host $strKey $strValue"
        fi
    elif [ -n "$strRet" ]; then
        if [ -n "$strValue" ]; then
            strRet="$strRet"`cat <<EOF

$freebox_host $strKey $strValue
EOF
`
        fi
    fi

    echo "$strRet"
}



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


echo -n "Get Disk datas... "
answer=$(call_freebox_api "/storage/disk/?_dc=$epochNow")
result_storage_disk_spinning=$(get_json_value_for_key "$answer" 'result[0].spinning')
result_storage_disk_idle=$(get_json_value_for_key "$answer" 'result[0].idle')
result_storage_disk_state=$(get_json_value_for_key "$answer" 'result[0].state')
result_storage_disk_total_bytes=$(get_json_value_for_key "$answer" 'result[0].total_bytes')
result_storage_disk_partition_0_total_bytes=$(get_json_value_for_key "$answer" 'result[0].partitions[0].total_bytes')
result_storage_disk_partition_0_fsck_result=$(get_json_value_for_key "$answer" 'result[0].partitions[0].fsck_result')
result_storage_disk_partition_0_free_bytes=$(get_json_value_for_key "$answer" 'result[0].partitions[0].free_bytes')
result_storage_disk_partition_0_used_bytes=$(get_json_value_for_key "$answer" 'result[0].partitions[0].used_bytes')
echo -e "${GREEN_COLOR}[OK]${NO_COLOR}"




# -------------------------------------------------------------------------------
# RETRIEVE INFOS - END
# -------------------------------------------------------------------------------

# Logout
echo -n "Logout to Freebox... "
logout_freebox
echo -e "${GREEN_COLOR}[OK]${NO_COLOR}"

echo -n "Write to data file... "


strContent=""
strContent=$(concatLineIfNecessary "$strContent" "$FREEBOX_HOST" "freebox.result.bytes_up" "$result_bytes_up")
strContent=$(concatLineIfNecessary "$strContent" "$FREEBOX_HOST" "freebox.result.bytes_down" "$result_bytes_down")
strContent=$(concatLineIfNecessary "$strContent" "$FREEBOX_HOST" "freebox.result.state" "$result_state")
strContent=$(concatLineIfNecessary "$strContent" "$FREEBOX_HOST" "freebox.result.media" "$result_media")
strContent=$(concatLineIfNecessary "$strContent" "$FREEBOX_HOST" "freebox.result.fans.0.value" "$result_fans_0_value")
strContent=$(concatLineIfNecessary "$strContent" "$FREEBOX_HOST" "freebox.result.sensors.0.value" "$result_sensors_0_value")
strContent=$(concatLineIfNecessary "$strContent" "$FREEBOX_HOST" "freebox.result.sensors.1.value" "$result_sensors_1_value")
strContent=$(concatLineIfNecessary "$strContent" "$FREEBOX_HOST" "freebox.result.sensors.2.value" "$result_sensors_2_value")
strContent=$(concatLineIfNecessary "$strContent" "$FREEBOX_HOST" "freebox.result.sensors.3.value" "$result_sensors_3_value")
strContent=$(concatLineIfNecessary "$strContent" "$FREEBOX_HOST" "freebox.result.uptime_val" "$result_uptime_val")
strContent=$(concatLineIfNecessary "$strContent" "$FREEBOX_HOST" "freebox.result.nbActiveDevices" "$result_nb_active_devices")
strContent=$(concatLineIfNecessary "$strContent" "$FREEBOX_HOST" "freebox.result.rrd_tx_1" "$result_rrd_tx_1")
strContent=$(concatLineIfNecessary "$strContent" "$FREEBOX_HOST" "freebox.result.rrd_rx_1" "$result_rrd_rx_1")
strContent=$(concatLineIfNecessary "$strContent" "$FREEBOX_HOST" "freebox.result.rrd_tx_2" "$result_rrd_tx_2")
strContent=$(concatLineIfNecessary "$strContent" "$FREEBOX_HOST" "freebox.result.rrd_rx_2" "$result_rrd_rx_2")
strContent=$(concatLineIfNecessary "$strContent" "$FREEBOX_HOST" "freebox.result.rrd_tx_3" "$result_rrd_tx_3")
strContent=$(concatLineIfNecessary "$strContent" "$FREEBOX_HOST" "freebox.result.rrd_rx_3" "$result_rrd_rx_3")
strContent=$(concatLineIfNecessary "$strContent" "$FREEBOX_HOST" "freebox.result.rrd_tx_4" "$result_rrd_tx_4")
strContent=$(concatLineIfNecessary "$strContent" "$FREEBOX_HOST" "freebox.result.rrd_rx_4" "$result_rrd_rx_4")
strContent=$(concatLineIfNecessary "$strContent" "$FREEBOX_HOST" "freebox.result.storage.disk.spinning" "$result_storage_disk_spinning")
strContent=$(concatLineIfNecessary "$strContent" "$FREEBOX_HOST" "freebox.result.storage.disk.idle" "$result_storage_disk_idle")
strContent=$(concatLineIfNecessary "$strContent" "$FREEBOX_HOST" "freebox.result.storage.disk.state" "$result_storage_disk_state")
strContent=$(concatLineIfNecessary "$strContent" "$FREEBOX_HOST" "freebox.result.storage.disk.total_bytes" "$result_storage_disk_total_bytes")
strContent=$(concatLineIfNecessary "$strContent" "$FREEBOX_HOST" "freebox.result.storage.disk.0.total_bytes" "$result_storage_disk_partition_0_total_bytes")
strContent=$(concatLineIfNecessary "$strContent" "$FREEBOX_HOST" "freebox.result.storage.disk.0.fsck_result" "$result_storage_disk_partition_0_fsck_result")
strContent=$(concatLineIfNecessary "$strContent" "$FREEBOX_HOST" "freebox.result.storage.disk.0.free_bytes" "$result_storage_disk_partition_0_free_bytes")
strContent=$(concatLineIfNecessary "$strContent" "$FREEBOX_HOST" "freebox.result.storage.disk.0.used_bytes" "$result_storage_disk_partition_0_used_bytes")

cat > $DATA_VALUES_FILE <<EOF
$strContent
EOF

echo -e "${GREEN_COLOR}[OK]${NO_COLOR}"

echo -n "Send data to Zabbix... "
#zabbix_sender -z 127.0.0.1 -i $DATA_VALUES_FILE
zabbix_sender -z 127.0.0.1 -i $DATA_VALUES_FILE >/dev/null 2>&1
echo -e "${GREEN_COLOR}[OK]${NO_COLOR}"

te=$(date +%s%N)

echo "Done in $((($(date +%s%N) - $ts)/1000000)) ms"
