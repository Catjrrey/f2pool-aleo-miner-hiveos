#!/bin/bash

source h-manifest.conf

LOG="$LOG_PATH/aleo-miner-$(date +'%Y-%m-%d').log"
CONF=$(sed -n '1p' $CONF_PATH)

find "$LOG_PATH" -name "*miner-*.log" -type f -mtime +7 -exec rm -f {} \;

$APP_PATH $CONF $@ 2>&1 | tee --append "$LOG"
