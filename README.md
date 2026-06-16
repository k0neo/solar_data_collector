# solar-monitor

A modular solar radio monitoring pipeline for RTL-SDR v4 receivers and loop antennas.

The reference platform is FreeBSD. Linux is a supported deployment platform.

The system is designed around four stages:

1. Capture raw SDR data
2. Process captured data with Fortran tools
3. Compute a local solar/radio index
4. Publish results for web and BBS use

Python is not used in the production pipeline.

## Current status

Initial project skeleton.

The first milestone is reliable raw capture using rtl_power, controlled entirely by a configuration file.

## Command family

- sm-capture
- sm-process
- sm-index
- sm-publish

## Reference platform

FreeBSD.

Default FreeBSD paths:

- /usr/local/etc/solar-monitor.conf
- /usr/local/bin/
- /var/db/solar-monitor/
- /var/log/solar-monitor.log

## Supported secondary platform

Linux with:

- gfortran
- make
- rtl-sdr tools
- systemd

## Hardware target

- RTL-SDR v4
- MLA-30 or similar loop antenna

