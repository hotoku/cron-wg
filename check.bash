#!/bin/bash


export PATH=/sbin:/usr/sbin:/opt/homebrew/bin:"$PATH"


SCRIPT_DIR=$(dirname $(readlink -f $0))
LOG_FILE="${SCRIPT_DIR}"/cron.log
LOGS_URL=$(cat "${SCRIPT_DIR}"/credentials/urls.json |jq -r '.logs')
REPORT_FILE="${SCRIPT_DIR}"/report.txt

initialiize(){
    if [[ ! -f "${LOG_FILE}" ]]; then
        touch "${LOG_FILE}"
    fi

    if [[ ! -f "${REPORT_FILE}" ]]; then
        echo "${LOGS_URL}" > "${REPORT_FILE}"
    fi
}


send_message(){
    local msg=$1


    echo "sending a message to slack" >> "${LOG_FILE}"
    echo "message: ${msg}" >> "${LOG_FILE}"
    echo "webhook url: ${LOGS_URL}" >> "${LOG_FILE}"


    local msg_escaped=$(echo "${msg}" | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g')
    local template='{"text": "__MESSAGE__"}'
    local payload=$(echo "${template}" | sed -e "s|__MESSAGE__|${msg_escaped}|")


    curl -X POST -H "Content-type: application/json" -d "${payload}" "${LOGS_URL}" >> "${LOG_FILE}" 2>&1
    echo "" >> "${LOG_FILE}" # curlが末尾の改行を出力しないので追加
}

initialiize
date +"%Y-%m-%d %H:%M:%S start checking" >> "${LOG_FILE}"


if ! [[ -f /var/run/wireguard/wg0.name ]]; then
    echo "Wireguard is down" >> "${LOG_FILE}"
    REPORT=$(date "+%y-%m-%d %H:%M:%S down")
    wg-quick down wg0 >> "${LOG_FILE}" 2>&1
    wg-quick up wg0 >> "${LOG_FILE}" 2>&1
else
    echo "Wireguard is already up" >> "${LOG_FILE}"
    REPORT=$(date "+%y-%m-%d %H:%M:%S up")
fi


ping -c 1 10.0.0.1
if [[ $? -eq 0 ]]; then
    REPORT="${REPORT} ping ok"
else
    REPORT="${REPORT} ping ng"
fi
echo "${REPORT}" >> "${REPORT_FILE}"


chown hotoku:staff "${REPORT_FILE}"
chown hotoku:staff "${LOG_FILE}"


if [[ $(cat "${REPORT_FILE}" | wc -l) -ge 10 ]]; then
    send_message "$(cat "${REPORT_FILE}")" logs
    rm -f "${REPORT_FILE}"
fi
