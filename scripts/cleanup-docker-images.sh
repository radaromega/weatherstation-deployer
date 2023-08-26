#!/usr/bin/env bash
set -euo pipefail

WS_ROOT="$(realpath $(readlink -f $(dirname "${BASH_SOURCE[0]}"))/..)"

allowed_images=$(cat "${WS_ROOT}"/*.yaml | grep "image:" | awk '{$1=$1;print}' | sed "s/image://" | sed 's/ //g'|sed -E 's/@.+//g')

# echo "${allowed_images}"

installed_images=$(docker images --format '{{.Repository}}:{{.Tag}}')

while IFS= read -r image; do
    if echo "${image}" | grep -q "<none>"; then
        continue
    fi

    echo "${image}"

    if echo "${allowed_images}" | grep -q "${image}"; then
        # Image found in allowed images
        true
    else
        docker rmi "${image}" || true
    fi
done <<< "${installed_images}"
