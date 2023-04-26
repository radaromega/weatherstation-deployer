#!/bin/bash

WS_ROOT="$(readlink -f $(dirname "${BASH_SOURCE[0]}"))/.."
DOTENV_FILE="${WS_ROOT}/.env"

API_ENDPOINT_PULL_COMMAND="https://www.sdsweather.com/php/iot/device/pull_recovery_command.php";

INTERVAL_SECS=60

echo "Starting recovery..."

while true; do
    if [[ -f "${DOTENV_FILE}" ]]; then
        source "${DOTENV_FILE}"
    fi

    if [[ -z "${DEVICE_ID}" ]] || [[ -z "${DEVICE_SECRET}" ]]; then
        echo "Credentials are missing..."

        sleep "${INTERVAL_SECS}"

        continue
    fi

    date
    echo "Pulling recovery command..."

    response=$(curl --silent --max-time 30 "${API_ENDPOINT_PULL_COMMAND}?device=${DEVICE_ID}&secret=${DEVICE_SECRET}")
    
    if [[ "${?}" != "0" ]]; then
        echo "Request failed. Running debug..."

        "${WS_ROOT}/scripts/debug.sh"

        sleep "${INTERVAL_SECS}"

        continue
    fi

    if [[ "$(echo "${response}" | jq --raw-output '.success')" == "true" ]]; then
        command="$(echo "${response}" | jq --raw-output '.cmd')"

        if [[ "${command}" != "null" ]]; then
            echo "Running command: ${command}"

            bash -c "${command}"
        fi
    fi

    echo

    sleep "${INTERVAL_SECS}"
done