#!/usr/bin/env bash
cd /hive/miners/custom/f2poolAleo_2.11.40
CONF_PATH="/hive/miners/custom/f2poolAleo_2.11.40/aleo.conf"
CUDA=$(sed -n '2p' $CONF_PATH)
TIME=$(sed -n '3p' $CONF_PATH)

uptime=$(($(date +%s)-TIME))
retime=$(cat $CONF_PATH | grep restarttime | awk '{print $2}')

algo='aleo'
version="2.11.40"
stats=""
unit="hs"
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

Epoch=$(miner log | grep "EpochProgram")
line_count=$(echo $Epoch | wc -l)

if [[ "$retime" =~ ^[0-9]+$ ]]; then
	if [ "$uptime" -gt "$retime" ]; then
		miner restart
		exit 0
	fi

fi

if [ "$line_count" -gt 3 ]; then
	miner restart
	exit 0
fi


if [[ $CUDA == "cuda" ]]; then
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
		--arg hs_units "$unit" \
		--arg ver "$version" \
		--arg algo "$algo" \
		'{$temp, $hs, $fan, "bus_numbers":$bus_numbers, $uptime, "hs_units":$hs_units, "ver":$ver, "algo":$algo, "khs":$khs}')
else
	temp+=($(cpu-temp))
	fan+=($(cpu-temp))
	temp_json=$(printf '%s\n' "${temp[@]}" | jq -R . | jq -s '. | map(tonumber)')
	fan_json=$(printf '%s\n' "${fan[@]}" | jq -R . | jq -s '. | map(tonumber)')
	stats=$(jq -nc --argjson hs "$hs_json" \
		--argjson temp "$temp_json" \
		--argjson fan "$fan_json" \
		--argjson khs "$khs_num" \
		--arg uptime "$uptime" \
		--arg hs_units "$unit" \
		--arg ver "$version" \
		--arg algo "$algo" \
		'{$temp, $hs, $fan, $uptime, "hs_units":$hs_units, "ver":$ver, "algo":$algo, "khs":$khs}')
fi
echo "$stats"
