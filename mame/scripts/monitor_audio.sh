#!/bin/sh
#
# This script will monitor the volume knob and headphone jack
# to make the headphone jack and volume knob work similar to
# how it did with the original software
#

# TODO: HDMI volume?
monitor_audio() {
    HEADPHONE_STATUS=-1
    VOL_STATUS=-1

    amixer set "HPOUT" on

    while true; do
        VOLUME_KNOB=$(cat /sys/devices/platform/soc@3000000/2009000.gpadc0/iio:device0/in_voltage2_raw)
        HEADPHONE_ENABLED=$(cat /sys/module/snd_soc_sunxi_common/parameters/jack_state)
        VOL=$(($VOLUME_KNOB*64/1234))

        if [ $HEADPHONE_ENABLED -ne $HEADPHONE_STATUS ]; then
            if [ $HEADPHONE_ENABLED -eq 1 ]; then
                # Headphones plugged in
                amixer set "SPK" off
            else
                amixer set "SPK" on
            fi

            HEADPHONE_STATUS=$HEADPHONE_ENABLED
        fi

        # DAC range is 0-63
        if [ $VOL -gt 63 ]; then
            VOL=63
        elif [ $VOL -lt 0 ]; then
            VOL=0
        fi

        if [ $VOL_STATUS -ne $VOL ]; then
            amixer set "DAC" $VOL
            VOL_STATUS=$VOL
        fi

        sleep 0.1
    done
}

monitor_audio
