# cyclonePORT Weather Station

The cyclonePORT Weather Station is a sophisticated system to capture meteorological telemetry from a wide range of supported sensors and can also stream video to the cloud.

Supported features:
- BME280
- BME680
- Boltek LD 250
- DS18B20
- SCD40
- GPS
- Inkbird
- Raingauge
- Voltage reading (useful for battery operated units)
- Windvane
- Davis Anemometer
- Rainwise Anemometer
- Screen
- BlinkM LED
- Cumulus support
- SignalK support
- ONVIF IP camera support (either directly attached or via the LAN)
- USB camera support
- Daisy chaining (via the USB Ethernet adapter)
- LoRa support

Deprecated features (but could be returned):
- AM2302
- SHT31
- Inspeed Anemometer

## Getting started

### Scripts

Start
```bash
sudo ./scripts/start.sh
```

Stop
```bash
sudo ./scripts/stop.sh
```

Update
```bash
sudo ./scripts/update.sh
```
