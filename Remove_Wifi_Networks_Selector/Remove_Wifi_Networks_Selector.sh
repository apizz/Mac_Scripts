#!/bin/bash

# Path to airport executable
WIFI_EXC="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
# Get wifi device for machine (en0, en1, etc.)
wifiDevice=$($WIFI_EXC prefs | /usr/bin/awk '/preferences/{print $NF}' | /usr/bin/sed 's/\://g')
# Exclude a desired SSID, so for example your users don't have the ability to remove your preconfigured Wifi connection
ExcludeSSID='YOUR_WIFI_SSID_HERE'

/usr/bin/osascript<<EOF

-- Get Preferred Wifi Networks
set Networks to (do shell script "/usr/sbin/networksetup -listpreferredwirelessnetworks '$wifiDevice' | /usr/bin/sed 1d | /usr/bin/tr -d '\t' | /usr/bin/sed '/'$ExcludeSSID'/d' | /usr/bin/sed '/^$/d'")

-- Save the current TID in oldtid and set the TID to return (the char we want to break the string at)
set {oldtid, AppleScript's text item delimiters} to {AppleScript's text item delimiters, return}

-- create WifiNetworks list from each text item in the string Networks. As the TID is set to the character return the string is broken at each return
if Networks doesn't equal ""
	set WifiNetworks to every text item of Networks

	-- Display Wifi Network list to user and set selection(s) to RemoveNetworks
	set RemoveNetworks to (choose from list WifiNetworks with prompt "Select the saved Wi-Fi networks you wish to remove:" default items "None" OK button name {"Remove"} cancel button name {"Cancel"} with multiple selections allowed with title "Masters Self Service Alert")

	if RemoveNetworks is not false then
    	-- Create RemoveWifiNetworks list from each text item in the string RemoveNetworks
    	set RemoveWifiNetworks to every text item of RemoveNetworks

    	-- Remove each Preferred Wifi Network from selected RemoveWifiNetworks list
    	repeat with WifiNetwork in RemoveWifiNetworks
        	set result to (do shell script "/usr/sbin/networksetup -removepreferredwirelessnetwork '$wifiDevice' \"" & WifiNetwork & "\"" with administrator privileges)
        	do shell script "/bin/echo \"" & result & "\""
    	end repeat
	end if
else
    display dialog "No Wi-Fi Networks detected to be removed." with title "Masters Self Service Alert"
end if

EOF

exit
