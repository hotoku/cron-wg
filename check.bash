#!/bin/bash

export PATH=/opt/homebrew/bin:"$PATH"

SCRIPT_DIR=$(dirname $(readlink -f $0))
LOG_FILE="${SCRIPT_DIR}"/cron.log
LOGS_URL=$(cat "${SCRIPT_DIR}"/credentials/urls.json |jq -r '.logs')
WARNS_URL=$(cat "${SCRIPT_DIR}"/credentials/urls.json |jq -r '.warnings')


send_message(){
    local msg=$1
    local dest=$2
    if [[ "${dest}" = "logs" ]]
    then
        webhook_url="${LOGS_URL}"
    elif [[ "${dest}" = "warns" ]]
    then
        webhook_url="${WARNS_URL}"
    else
        msg="error: invalid destination. original message: ${msg}"
        webhook_url=${LOGS_URL}
    fi
    echo "sending to ${dest} with message: ${msg}" >> "${LOG_FILE}"
    echo "webhook url: ${webhook_url}" >> "${LOG_FILE}"
    local tmp='{"text": "cron-wg: __MESSAGE__"}'
    local payload=$(echo ${tmp} | sed -e "s/__MESSAGE__/${msg}/")    
    curl -X POST -H "Content-type: application/json" -d "${payload}" "${webhook_url}" >> "${LOG_FILE}" 2>&1
    echo "" >> "${LOG_FILE}" # curlが末尾の改行を出力しないので追加
}

date +"%Y-%m-%d %H:%M:%S start checking" >> "${LOG_FILE}"

if ! [[ -f /var/run/wireguard/wg0.name ]]; then
    echo "Wireguard is down" >> "${LOG_FILE}"
    send_message "Wireguard is down" "warns"
    wg-quick down wg0 >> "${LOG_FILE}" 2>&1
    wg-quick up wg0 >> "${LOG_FILE}" 2>&1
else
    echo "Wireguard is already up" >> "${LOG_FILE}"
    send_message "Wireguard is already up" "logs"
fi

chown hotoku:staff "${LOG_FILE}"
