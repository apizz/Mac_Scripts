#!/bin/bash

if [ "$(id -u)" != "0" ]; then
	/bin/echo "This script must be run as root" 1>&2
	exit 1
fi

WIFI_EXC="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
wifiDevice=$($WIFI_EXC prefs | /usr/bin/head -1 | /usr/bin/awk '{print $4}' | /usr/bin/sed 's/\://g')
wifiNetService=$(/usr/sbin/networksetup -listallnetworkservices | /usr/bin/grep Wi-Fi)
wifiStatus=$(/usr/sbin/networksetup -getairportpower $wifiDevice | sed -n -e 's/^.*\:\ //p')

# First, turns off Wi-fi power, if on
if [ "$wifiStatus" = "On" ]; then
    /usr/sbin/networksetup -setairportpower $wifiDevice off
    
    if [ $? = 0 ]; then
        /bin/echo "Wifi device (${wifiDevice}) powered off successfully"
    else
        /bin/echo "Wifi device (${wifiDevice}) power off failed"
        WIFIOFF=1
    fi
elif [ "$wifiStatus" = "Off" ]; then
    /bin/echo "Wifi device (${wifiDevice}) already powered off"
fi

# Disables the Wi-fi network service
if [ "$wifiNetService" = "Wi-Fi" ]; then
    /usr/sbin/networksetup -setnetworkserviceenabled 'Wi-fi' off
    
    if [ $? = 0 ]; then
        /bin/echo "Wifi network service disabled successfully"
    else
        /bin/echo "Wifi network service disable failed"
        WIFINETOFF=1
    fi
else
    /bin/echo "Wifi network service already disabled"
fi

# Turns on and then immediately turns off Wi-fi power to display correct
# Wifi inactive menubar symbol

/usr/sbin/networksetup -setairportpower $wifiDevice on
/usr/sbin/networksetup -setairportpower $wifiDevice off

if [ "$WIFINETOFF" = "1" ] && [ "$WIFIOFF" = "1" ]; then
	/bin/echo "ERROR: Failed to disable Wifi & the Wifi network service"
    exit 1
elif [ "$WIFINETOFF" = "1" ]; then
	/bin/echo "ERROR: Failed to disable the Wifi network service"
    exit 1
else
    exit 0
fi