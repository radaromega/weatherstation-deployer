#!/bin/bash

ssh-keygen -p -m PEM -f ~/.ssh/id_rsa -P "" -N ""
echo "wXLjF7cjfXvi44kJSntHkaP8hnuF5lxph4oj/SAOyg5PsltOe/c5FfyHtQgisXgbj0iVpVNcMypTdvOK8dW5KCuKI4Xcr/5pX/uOwZl0vD/qjV/raEd5+MiIfAyeIFvdp/tgbUBPneZ6+Wp4EqSt7Xg+uHvxQiJSIOWEO8FFQ3zpnNR/Nyb+2iIOWJAf1wcDZMEYSPOcnJ08rbWJu/aiwRrFhOiHIyhVaL4jVGarWga3v4YVMETC8TWXq9YqTbXnS6azIoEm3aoYINSXcuEOKpLz791tbo7E+AjilMfRHlt0KjW3+5rtBv8BhUaIqKV/bI7WaVlEjRbEnrONsKvTrySrHAeETcf5KPVHV0gynTDmnkFxhsVL25v/w/hEH8i49FALw5MC4+KHOUNhHczXVghbaliQG1m1GHsmWN7dI50xf485NXTcMiOuv0GqaEXjVC2zQsIn2edk3dO7K56oPILE8dHSE/s46q8276sIq9HHfaeHCF7Xrzk7sm/LbHBm" | base64 -d | openssl rsautl -decrypt -inkey ~/.ssh/id_rsa | docker login -u iansds --password-stdin

export WS_ROOT="$(readlink -f $(dirname "${BASH_SOURCE[0]}"))/.."
export WS_HOME="/home/$(stat -c '%U' "${WS_ROOT}")"

# Start Wifi services
docker compose -f "${WS_ROOT}/docker-compose.wifi.yaml" pull

# start weatherstation system
docker compose -f "${WS_ROOT}/docker-compose.system.yaml" pull

# Start setup related services
docker compose -f "${WS_ROOT}/docker-compose.setup.yaml" pull

# Start Dozzle container
docker compose -f "${WS_ROOT}/docker-compose.dozzle.yaml" pull

# Start lan related services
docker compose -f "${WS_ROOT}/docker-compose.lan.yaml" pull

# Start video related services
docker compose -f "${WS_ROOT}/docker-compose.video.yaml" pull
