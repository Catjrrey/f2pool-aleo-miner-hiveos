#!/bin/bash

WORKSPACE="/hive/miners/custom/$CUSTOM_NAME"
CONF_PATH="$WORKSPACE/aleo.conf"

IP_PORT=$CUSTOM_URL
ACCOUNTNAME=$CUSTOM_TEMPLATE
CUDA=$CUSTOM_PASS

pkill -9 aleo-miner

> /run/hive/miner.1
rm "$CONF_PATH"

GPU_STR=""
if command -v nvidia-smi >/dev/null 2>&1; then
    gpu_info=$(nvidia-smi -L)
    gpu_count=0
    while read -r line; do
        if [ $gpu_count -eq 0 ]; then
            GPU_STR="${gpu_count}"
        else
            GPU_STR="${GPU_STR},${gpu_count}"
        fi
        ((gpu_count++))

    done <<<"$gpu_info"
fi

echo "-d $GPU_STR -u $IP_PORT -w $ACCOUNTNAME" >> $CONF_PATH
echo $(date +%s) >>$CONF_PATH
echo "${CUSTOM_USER_CONFIG}" >> $CONF_PATH

nv=$(echo "${CUSTOM_USER_CONFIG}" | grep "nvtool")
echo $nv
if [[ $nv != "" ]];then
eval $nv 
fi
