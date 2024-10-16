# How to build MAME for DDR classic mini

## Requirements
- Docker

## Steps
Create a new Ubuntu 21.10 image in Docker. Replace `/path/to/folder/on/host` with the path to the folder containing `mame_crosscompile.diff` as it will be needed to build MAME for the DDR Classic Mini.
```bash
# Start Docker container with required build environment
# Replace the volume path with the folder you want to share between your host and Docker
docker run -it --name ubuntu_mame -v /path/to/folder/on/host:/mame_build --privileged=true ubuntu:21.10 bash
```

Once you have a bash shell opened for Ubuntu 21.10 running in Docker, execute the following commands to install all of the required libraries and then compile MAME:
```bash
# Inside Docker...
# Fix repositories and install basic tools
sed -i -e "s,# deb-src http://ports.ubuntu.com,deb-src http://ports.ubuntu.com,g" /etc/apt/sources.list
sed -i -e "s,ports.ubuntu.com/ubuntu-ports,old-releases.ubuntu.com/ubuntu,g" /etc/apt/sources.list
apt update && apt install -y git sudo

git clone https://github.com/danmons/mame_raspberrypi_cross_compile.git
cd mame_raspberrypi_cross_compile

# Install tools needed for building then build environment, must be root
./install_prereqs.sh

# crosstool-ng will not let you use root, so make non-root user now
adduser crosstoolng
chown -R crosstoolng:crosstoolng .
su crosstoolng

# Apply modifications to environment to use Bemani fork + make compilation go smoother
git apply /mame_build/mame_crosscompile.diff

# Prepare MAME build environment
./mame-cross-compile.sh -o download -r 11 -a arm64 -f bemani
./mame-cross-compile.sh -o prepare -r 11 -a arm64 -f bemani

# Build MAME
./mame-cross-compile.sh -o compile -r 11 -a arm64 -f bemani

# Copy compiled file to the host OS
cp build/output/mame_*_arm64.7z /mame_build
```

## Notes
This method requires patching `mame_raspberrypi_cross_compile` to support the Bemani fork of MAME which contains the modifications required to build for the DDR Classic Mini. If you wish to build any other branch of MAME then you must apply the same patches as I applied [here](https://github.com/987123879113/mame/commit/9a2b312caa3df990faa49bb7a8afd16cfd814a6b.patch).

## Audio
The [provided script](scripts/monitor_audio.sh) can be started before MAME to make the volume knob and headphone jack work again.

You can start it like this:
```
#/bin/sh

# Start audio monitoring
sh monitor_audio.sh &

# Replace with your command here
./mame ddrmax
```

## DDR Cabinet Lights

Copy `plugins/ksys573_ddr_lights_ddrmini` to MAME's `plugins` folder.

Add the line `ksys573_ddr_lights_ddrmini 1` to `plugin.ini` in the MAME folder to enable the script automatically on start.

**NOTE**: This script is set to autostart which may not work with non-DDR games. You can disable autostart by modifying `plugins/ksys573_ddr_lights_ddrmini/plugin.json` and set `start` to `false`.
