# solar-monitor

A FreeBSD-first solar and HF radio monitoring pipeline for RTL-SDR v4 receivers and loop antennas.

`solar-monitor` captures spectrum data with `rtl_power`, processes the capture with Fortran tools, builds a latest-observation index, and publishes a plain-text report for web or BBS use.

Python is not used in the production pipeline.

## Current status

The first complete pipeline is working:

1. `sm-capture` captures raw `rtl_power` CSV data.
2. `sm-process` reads the raw capture and writes a processed summary.
3. `sm-index` reads the latest summary and writes a current index.
4. `sm-publish` reads the index and publishes a text report.

The project is still early, but it is no longer just scaffolding. It can capture, process, index, and publish a basic solar/HF monitoring report.

## Command family

* `sm-capture` — capture raw RTL-SDR spectrum data with `rtl_power`
* `sm-process` — process a raw capture into a summary file
* `sm-index` — create a latest-observation index from a summary file
* `sm-publish` — publish the latest index as a text report

## Reference platform

FreeBSD is the reference platform.

Default FreeBSD paths:

* `/usr/local/etc/solar-monitor.conf`
* `/usr/local/bin/`
* `/var/db/solar-monitor/raw/`
* `/var/db/solar-monitor/processed/`
* `/var/db/solar-monitor/index/`
* `/usr/local/www/solar-monitor/`
* `/var/log/solar-monitor.log`

## Supported secondary platform

Linux support is planned and partially scaffolded.

Expected Linux requirements:

* `gfortran`
* `make`
* `rtl-sdr` tools
* `systemd`, for timer/service deployment

FreeBSD remains the primary development and test platform.

## Hardware target

Reference hardware:

* RTL-SDR Blog V4 receiver
* MLA-30 or similar active loop antenna

The default capture range is currently configured for 18 MHz to 30 MHz.

## Basic FreeBSD workflow

Install the tools:

```sh
make
su -
make install OS=freebsd
exit
```

Create or edit the configuration file:

```sh
cp /usr/local/etc/solar-monitor.conf.sample /usr/local/etc/solar-monitor.conf
ee /usr/local/etc/solar-monitor.conf
```

Initialize runtime directories:

```sh
su -
sm-init-dirs /usr/local/etc/solar-monitor.conf rbrown
exit
```

Run preflight:

```sh
sm-preflight /usr/local/etc/solar-monitor.conf
```

Run a capture:

```sh
sm-capture /usr/local/etc/solar-monitor.conf
```

Process the latest capture:

```sh
LATEST="$(ls -t /var/db/solar-monitor/raw/*.csv | head -1)"
sm-process "$LATEST"
```

Index the latest processed summary:

```sh
SUMMARY="$(ls -t /var/db/solar-monitor/processed/*.summary | head -1)"
sm-index "$SUMMARY"
```

Publish the latest report:

```sh
sm-publish /usr/local/etc/solar-monitor.conf
```

## Output files

Raw captures are written as CSV files:

```text
/var/db/solar-monitor/raw/solar_YYYYMMDDTHHMMSSZ.csv
```

Processed summaries are written as key-value text files:

```text
/var/db/solar-monitor/processed/solar_YYYYMMDDTHHMMSSZ.summary
```

The latest index is written to:

```text
/var/db/solar-monitor/index/latest.index
```

The published text report is written to the configured publish directories.

Example report fields include:

```text
Last capture
Mean power
Peak signal frequency
Peak signal power
Bad value count
Status
```

## BBS publishing

`sm-publish` can write a text report to a BBS-accessible directory.

The sample configuration may use a generic local path. BBS operators can point `bbs_dir` at the correct local text directory for their system, such as a Synchronet text area.

## Notes

This project is intentionally modular. Each stage produces a simple file that the next stage can consume.

The current pipeline is basic but functional. Future work will improve signal classification, historical indexing, web output, and station reporting.

