#!/bin/bash

WORKSPACE="$(cd $(dirname $0) && pwd)"
LOG_PATH="$WORKSPACE/aleo-miner.log"
APP_PATH="$WORKSPACE/aleo-miner"
CONF_PATH="$WORKSPACE/aleo.conf"
CONF=$(sed -n '1p' $CONF_PATH)

./aleo-miner $CONF $@ 2>&1 | tee --append ${CUSTOM_LOG_BASENAME}miner.log
