#!/bin/bash

export PATH=/opt/homebrew/bin:"$PATH"

SCRIPT_DIR=$(dirname $(readlink -f $0))
LOG_FILE="${SCRIPT_DIR}"/cron.log

date +"%Y-%m-%d %H:%M:%S start checking" >> "${LOG_FILE}"

if ! [[ -f /var/run/wireguard/wg0.name ]]; then
    echo "Wireguard is down" >> "${LOG_FILE}"
    wg-quick down wg0 >> "${LOG_FILE}" 2>&1
    wg-quick up wg0 >> "${LOG_FILE}" 2>&1
else
    echo "Wireguard is already up" >> "${LOG_FILE}"
fi

chown hotoku:staff "${LOG_FILE}"
