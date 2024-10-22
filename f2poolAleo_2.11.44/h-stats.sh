#!/usr/bin/env bash

source $MINER_DIR/$CUSTOM_MINER/h-manifest.conf

TIME=$(sed -n '2p' $CONF_PATH)

uptime=$(($(date +%s)-TIME))
retime=$(cat $CONF_PATH | grep restarttime | awk '{print $2}')

stats=""
khs=0
hs=()
temp=()
fan=()
numbers=()

log=$(miner log | grep "Speed(S/s)" | awk 'END {print}')
khs=$(echo $log | awk '{print $3}')

khs=$(echo "scale=5; $khs / 1000" | bc)
hs+=($(echo $log | awk '{print $3}'))

hs_json=$(printf '%s\n' "${hs[@]}" | jq -R . | jq -s '. | map(tonumber)')

khs_num=$(echo "$khs" | jq -R . | jq -s 'map(tonumber)[0]')

if [[ "$retime" =~ ^[0-9]+$ ]]; then
	if [ "$uptime" -gt "$retime" ]; then
		miner restart
		exit 0
	fi

fi

temp+=($(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits))
fan+=($(nvidia-smi --query-gpu=fan.speed --format=csv,noheader,nounits))
temp_json=$(printf '%s\n' "${temp[@]}" | jq -R . | jq -s '. | map(tonumber)')
fan_json=$(printf '%s\n' "${fan[@]}" | jq -R . | jq -s '. | map(tonumber)')
gpu_buses=($(lspci | grep -i nvidia | awk '{print $1}' | cut -d ':' -f 1 | sort | uniq))
for bus in "${gpu_buses[@]}"; do
	dec_bus=$((16#$bus))
	numbers+=($dec_bus)
	done
numbers_json=$(printf '%s\n' "${numbers[@]}" | jq -R . | jq -s '. | map(tonumber)')
stats=$(jq -nc --argjson hs "$hs_json" \
	--argjson temp "$temp_json" \
	--argjson fan "$fan_json" \
	--argjson khs "$khs_num" \
	--argjson bus_numbers "$numbers_json" \
	--arg uptime "$uptime" \
	--arg hs_units "$UNIT" \
	--arg ver "$CUSTOM_VERSION" \
	--arg algo "$ALOG" \
	'{$temp, $hs, $fan, "bus_numbers":$bus_numbers, $uptime, "hs_units":$hs_units, "ver":$ver, "algo":$algo, "khs":$khs}')

echo "$stats"
