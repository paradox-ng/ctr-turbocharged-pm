# armhf cross-build environment for the PortMaster port.
# Debian bullseye keeps glibc at 2.31 so the binary runs on older firmware.
# Bullseye now lives on archive.debian.org, security updates and backports included.
FROM debian:bullseye
RUN rm -f /etc/apt/sources.list.d/* \
 && printf '%s\n' \
      'deb http://archive.debian.org/debian bullseye main' \
      'deb http://archive.debian.org/debian bullseye-updates main' \
      'deb http://archive.debian.org/debian-security bullseye-security main' \
      'deb http://archive.debian.org/debian bullseye-backports main' \
      > /etc/apt/sources.list \
 && dpkg --add-architecture armhf && apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential crossbuild-essential-armhf ninja-build git pkg-config python3 file ca-certificates \
      libdrm-dev:armhf libgbm-dev:armhf libegl-dev:armhf libgles-dev:armhf \
      libasound2-dev:armhf libpulse-dev:armhf libudev-dev:armhf \
 && apt-get install -y --no-install-recommends -t bullseye-backports cmake \
 && rm -rf /var/lib/apt/lists/*
