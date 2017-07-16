#!/bin/bash

if [ "$(id -u)" != "0" ]; then
	/bin/echo "This script must be run as root" 1>&2
	exit 1
fi

WIFI_EXC="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
wifiDevice=$($WIFI_EXC prefs | /usr/bin/head -1 | /usr/bin/awk '{print $4}' | /usr/bin/sed 's/\://g')
wifiNetService=$(/usr/sbin/networksetup -listallnetworkservices | /usr/bin/grep Wi-Fi)
wifiStatus=$(/usr/sbin/networksetup -getairportpower $wifiDevice | sed -n -e 's/^.*\:\ //p')

# First, turns on Wi-fi power, if off
if [ "$wifiStatus" = "Off" ]; then
    /usr/sbin/networksetup -setairportpower $wifiDevice on
    
    if [ $? = 0 ]; then
        /bin/echo "Wifi device (${wifiDevice}) powered on successfully"
    else
        /bin/echo "Wifi device (${wifiDevice}) power on failed"
        WIFION=1
    fi
elif [ "$wifiStatus" = "On" ]; then
    /bin/echo "Wifi device (${wifiDevice}) already powered on"
fi

# Enables the Wi-fi network service
if [ "$wifiNetService" = "*Wi-Fi" ]; then
    /usr/sbin/networksetup -setnetworkserviceenabled 'Wi-fi' on
    
    if [ $? = 0 ]; then
        /bin/echo "Wifi network service enabled successfully"
    else
        /bin/echo "Wifi network service enable failed"
        WIFINETON=1
    fi
else
    /bin/echo "Wifi network service already disabled"
fi

# Turns off and then immediately turns on Wi-fi power to display correct
# Wifi inactive menubar symbol

/usr/sbin/networksetup -setairportpower $wifiDevice off
/usr/sbin/networksetup -setairportpower $wifiDevice on

if [ "$WIFINETON" = "1" ] && [ "$WIFION" = "1" ]; then
	/bin/echo "ERROR: Failed to enable Wifi & the Wifi network service"
    exit 1
elif [ "$WIFINETON" = "1" ]; then
	/bin/echo "ERROR: Failed to enable the Wifi network service"
    exit 1
else
    exit 0
fi

exit 0