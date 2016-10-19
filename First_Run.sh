#!/bin/bash

#########################################################
# Modified by me for use at our organization 
# for imaging Macs. Lower half taken from first run script
# written by mac admin Rich Trouton.
#
# Created: 3/30/16
#
#########################################################


################## VARIABLES #######################

timeServer=$4
kickstart="/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart"
orglogs=$5
orgreceipts=$6
tccutil="/usr/local/bin/tccutil.py"
osvers=$(sw_vers -productVersion | awk -F. '{print $2}')
sw_vers=$(sw_vers -productVersion)
sw_build=$(sw_vers -buildVersion)

####################################################

# Sets Time Server if not a STULOAN laptop
/bin/hostname | /usr/bin/grep stuloan
if [ $? != "0" ]; then
    /usr/sbin/systemsetup -setnetworktimeserver $timeServer
    
    if [ $? = "0" ]; then
        /bin/echo "Set Time Server: Successful."
    else
        /bin/echo "Set Time Server: Failed."
    fi
    
    /usr/sbin/systemsetup -setusingnetworktime on
else
    /bin/echo "STULOAN Machine. Not setting Time Server."
fi

# Creates ORG Receipts folder and sets permissions
/bin/mkdir $orgreceipts 
/usr/sbin/chown root:wheel $orgreceipts
/bin/chmod 755 $orgreceipts

if [ -d "$orgreceipts" ]; then
    /bin/echo "ORG Receipt Folder Creation: Successful."
else
    /bin/echo "ORG Receipt Folder Creation: Failed."
fi

# Creates ORG Log folder and sets permissions
/bin/mkdir $orglogs 
/usr/sbin/chown root:wheel $orglogs
/bin/chmod 755 $orglogs

# Array for each ORG Log to be created in for-do statement below
# The following logs are utilized by our outset scripts, which is
# why permissions are 777.
ORG_LOG_FILE=('AddServerShortcuts.log'
'CaffeineSetup.log'
'DisableOSXKeychainSync.log'
'DisablePhotosAutoLaunch.log'
'DockSetup.log'
'GoogleEarthSetup.log'
'HelpdeskFirstAid.log'
'MountHome.log'
'Office2016LocalSave.log'
'outset.log'
'TrackpadByHost.log'
'SetVLCasDefault.log'
'SidebarSetup.log'
'SpotlightExclusions.log')

# Checks that ORG Log folder exists and then creates logs and sets permissions
if [ -d "$orglogs" ]; then
	/bin/echo "ORG Log Folder Creation Successful! Creating ORG Logs ..."
	
	for ((i = 0; i < "${#ORG_LOG_FILE[@]}"; i++))
	do
		/usr/bin/touch "$orglogs"/"${ORG_LOG_FILE[$i]}"
		
		if [ -f "$orglogs/${ORG_LOG_FILE[$i]}" ]; then
			/bin/echo "${ORG_LOG_FILE[$i]} Creation Successful!"
			
			# Writes creation date & time to log
			/bin/echo "$(date) Initial Creation Date & Time" >> "$orglogs"/"${ORG_LOG_FILE[$i]}"
			
			# Sets ownership & permissions
			/usr/sbin/chown root:wheel "$orglogs"/"${ORG_LOG_FILE[$i]}"
			/bin/chmod 777 "$orglogs"/"${ORG_LOG_FILE[$i]}"
		
			if [ $? = 0 ]; then
				/bin/echo "${ORG_LOG_FILE[$i]} Permissions Successful!"
			else
				/bin/echo "${ORG_LOG_FILE[$i]} Permissions Failed."
			fi
		
		else
			/bin/echo "${ORG_LOG_FILE[$i]} Creation Failed."
		fi
	done
	
else
	/bin/echo "ORG Log Folder Creation: Failed. No ORG Logs Created."
fi

#####################################################
#
# The commented out settings below are VERY IMPORTANT for our Macs, however these are now set via
# Extension Attribute scripts, so each time a computer updates inventory the AD pass interval,
# sharepoint, and UNC path home settings are checked and disabled (if necessary).
#
#####################################################

# *****Sets AD Password interval to 0 - VERY IMPORTANT*****
# /usr/bin/sudo /usr/sbin/dsconfigad -passinterval 0
# NOTE: this setting gets set by the ADPass Status Extension Attribute

# Disables dsconfigad mounting home folder as a sharepoint, which is done by Panther.app
# /usr/bin/sudo /usr/sbin/dsconfigad -sharepoint disable
# NOTE: this setting gets set by the Sharepoint Status Extension Attribute

# Disables UNC path home setting
# /usr/bin/sudo /usr/sbin/dsconfigad -useuncpath disable

######################################
# Configure root /Library Preferences
######################################

# 1) Save to disk (not to iCloud) by default
# 2) Expand OS X save panel by default
# 3) Expand OS X print panel by default
# 4) Turn off Bluetooth by default
# 5) Disable OS X Password Expiration prompt at Login Window
# 6) Disable OS X Time Machine prompt for new connected disks
# 7) Set Time Zone automatically using current location
# 8) Disable automatic Java Plugin update checks by writing /Library/Preferences file

# Arrays to set the default /Library/Preferences PLIST pref values.
# Each PLIST, PLIST_PREF, and PREF_VALUE **MUST** be on the same line in each array

PLIST_PATH=('/Library/Preferences/.GlobalPreferences.plist' #1
'/Library/Preferences/.GlobalPreferences.plist' #2
'/Library/Preferences/.GlobalPreferences.plist' #3
'/Library/Preferences/com.apple.Bluetooth.plist' #4
'/Library/Preferences/com.apple.loginwindow.plist' #5
'/Library/Preferences/com.apple.TimeMachine.plist' #6
'/Library/Preferences/com.apple.timezone.auto.plist' #7
'/Library/Preferences/com.oracle.java.Java-Updater.plist') #8

PLIST_PREF=('NSDocumentSaveNewDocumentsToCloud' #1
'NSNavPanelExpandedStateForSaveMode' #2
'PMPrintingExpandedStateForPrint' #3
'ControllerPowerState' #4
'PasswordExpirationDays' #5
'DoNotOfferNewDisksForBackup' #6
'Active' #7
'JavaAutoUpdateEnabled') #8

PREF_VALUE=('-bool false' #1
'-bool true' #2
'-bool true' #3
'-int 0' #4
'-int 0' #5
'-bool true' #6
'-bool true' #7
'-bool false') #8

for ((i = 0; i < "${#PLIST_PATH[@]}"; i++))
do
	/usr/bin/defaults write ${PLIST_PATH[$i]} ${PLIST_PREF[$i]} ${PREF_VALUE[$i]}
	
	if [ $? = 0 ]; then
		/bin/echo "${PLIST_PREF[$i]} Preference Write to ${PLIST_PATH[$i]} Successful!"
	else
		/bin/echo "${PLIST_PREF[$i]} Preference Write to ${PLIST_PATH[$i]} Failed."
	fi
done

# Set Time Zone to New York
/usr/sbin/systemsetup -settimezone America/New_York

if [ $? = "0" ]; then
    /bin/echo "Set Time Zone to NY: Successful."
else
    /bin/echo "Set Time Zone to NY: Failed."
fi

# Turns on Remote Login
/usr/sbin/systemsetup -setremotelogin on

if [ $? = "0" ]; then
    /bin/echo "Enable SSH Login: Successful."
else
    /bin/echo "Enable SSH Login: Failed."
fi

# Create SSH group
/usr/sbin/dseditgroup -o create -q com.apple.access_ssh

if [ $? = "0" ]; then
    /bin/echo "Create SSH Login Group: Successful."
else
    /bin/echo "Create SSH Login Group: Failed."
fi

# Add the Administrators group to to remote login access group
# ***NOTE - the Administrators group does NOT show up in the list
# of specified users in the Remote Login section of the Sharing
# sys pref pane, but it is in fact enabled for admin users.***

/usr/sbin/dseditgroup -o edit -a admin -t group com.apple.access_ssh

if [ $? = "0" ]; then
    /bin/echo "Add Administrators Group to SSH Login Group: Successful."
else
    /bin/echo "Add Administrators Group to SSH Login Group: Failed."
fi

# Enables Remote Management, sets to run at startup, and sets access to only specified users.
# This command MUST be separate from the specified users who have management access.
"$kickstart" -activate -configure -allowAccessFor -specifiedUsers -verbose

# Give full management access to local arduser account
"$kickstart" -configure -access -on -privs -all -users arduser -targetdisk / -verbose

# Prevents GateKeeper prompt when launching ADPassMon.app from Applications folder
/usr/bin/xattr -dr com.apple.quarantine /Applications/ADPassMon.app

if [ $? = 0 ]; then
    /bin/echo "Prevent GateKeeper Prompt for ADPassMon: Successful."
else
    /bin/echo "Prevent GateKeeper Prompt for ADPassMon: Failed."
fi

# Prevents GateKeeper prompt when launching Gapminder World, if it exists, from Applications folder
if [ -d "/Applications/Gapminder World.app" ]; then
    /usr/bin/xattr -dr com.apple.quarantine "/Applications/Gapminder World.app"
    if [ $? = 0 ]; then
        /bin/echo "Prevent GateKeeper Prompt for Gapminder World: Successful."
    else
        /bin/echo "Prevent GateKeeper Prompt for Gapminder World: Failed."
    fi
fi

# Checks if Microsoft AutoUpdate is installed, if so changes permissions.
if [ -d "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app" ]; then
    /bin/echo "MAU Installed. Changing MAU.app permissions ..."
    sudo chmod 770 "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app"
    if [ $? = 0 ]; then
        /bin/echo "MAU Permissions Change: Successful."
    else
        /bin/echo "MAU Permissions Change: Failed."
    fi
else
    /bin/echo "MAU Not Installed. Will not change app permissions."
fi

# Checks if tccutil.py is installed, if so adds ADPassMon to Accessibility in Security & Privacy
if [ -f "$tccutil" ]; then
    /bin/echo "tccutil.py Installed. Adding ADPassMon to Accessbility ..."
    $tccutil --insert org.pmbuko.ADPassMon
    if [ "$( $tccutil --list | grep ADPassMon )" == "org.pmbuko.ADPassMon" ]; then
        /bin/echo "Add ADPassMon to Accessiblity: Successful!"
    else
        /bin/echo "Add ADPassMon to Accessiblity: Failed."
    fi
else
    /bin/echo "ERROR: tccutil.py not installed."
fi

########################################################
# Below is initial setup script for Mac OS X 10.10.x
# Rich Trouton, created August 20, 2014
# Last modified 11-21-2014
#
# Adapted from Initial setup script for Mac OS X 10.9.x
# Rich Trouton, created August 15, 2013
# Last modified 10-25-2013
#
# Many .GlobalPreferences.plist and other preferences added
# by AP Orlebeke - Last modified 10/18/16
#
#########################################################

# Get the system's UUID to set ByHost prefs

if [[ `ioreg -rd1 -c IOPlatformExpertDevice | grep -i "UUID" | cut -c27-50` == "00000000-0000-1000-8000-" ]]; then
	MAC_UUID=`ioreg -rd1 -c IOPlatformExpertDevice | grep -i "UUID" | cut -c51-62 | awk {'print tolower()'}`
elif [[ `ioreg -rd1 -c IOPlatformExpertDevice | grep -i "UUID" | cut -c27-50` != "00000000-0000-1000-8000-" ]]; then
	MAC_UUID=`ioreg -rd1 -c IOPlatformExpertDevice | grep -i "UUID" | cut -c27-62`
fi

# Disable root login by setting root's shell to /usr/bin/false
# Note: Setting this value has been known to cause issues seen
# by others when they used Casper's FileVault 2 management.
# If you are running Casper and see problems encrypting, the
# original UserShell value is as follows:
#
# /bin/sh
#
# To revert it back to /bin/sh, run the following command:
# /usr/bin/dscl . -change /Users/root UserShell /usr/bin/false /bin/sh

/usr/bin/dscl . -create /Users/root UserShell /usr/bin/false

if [ $? = "0" ]; then
    /bin/echo "Disable Root Shell Login: Successful."
else
    /bin/echo "Disable Root Shell Login: Failed."
fi

# Set separate power management settings for desktops and laptops
# If it's a laptop, the power management settings for "Battery" are set to have the computer sleep in 15 minutes, disk will spin down 
# in 10 minutes, the display will sleep in 5 minutes and the display itself will dim to half-brightness before sleeping. While plugged 
# into the AC adapter, the power management settings for "Charger" are set to have the computer never sleep, the disk doesn't spin down, 
# the display sleeps after 30 minutes, the display dims before sleeping, and Power Nap is enabled.
# 
# If it's not a laptop (i.e. a desktop), the power management settings are set to have the computer never sleep, the disk doesn't spin down,
# the display sleeps after 30 minutes and the display dims before sleeping.
#

# Detects if this Mac is a laptop or not by checking the model ID for the word "Book" in the name.
IS_LAPTOP=`/usr/sbin/system_profiler SPHardwareDataType | grep "Model Identifier" | grep "Book"`

if [ "$IS_LAPTOP" != "" ]; then
# Sets Laptop power settings
	/usr/bin/pmset -b sleep 15 disksleep 10 displaysleep 5 halfdim 1
	/usr/bin/pmset -c sleep 0 disksleep 0 displaysleep 30 halfdim 1 powernap 1
else
# Sets Desktop power settings, enables restart after power failure, and turns off Wifi
	/usr/bin/pmset sleep 0 disksleep 0 displaysleep 30 halfdim 1
	/usr/sbin/systemsetup -setrestartpowerfailure on
	/usr/sbin/networksetup -setairportpower en1 off
fi

###########################################
# Checks the system default user template for the presence of 
# the Library/Preferences directory. If the directory is not found, 
# it is created. A number of other user template preferences are configured.
###########################################

for USER_TEMPLATE in "/System/Library/User Template"/*
  do
     if [ ! -d "${USER_TEMPLATE}"/Library/Preferences ]; then
        /bin/mkdir -p "${USER_TEMPLATE}"/Library/Preferences
     fi
     if [ ! -d "${USER_TEMPLATE}"/Library/Preferences/ByHost ]; then
        /bin/mkdir -p "${USER_TEMPLATE}"/Library/Preferences/ByHost
     fi
     if [ -d "${USER_TEMPLATE}"/Library/Preferences/ByHost ]; then
        # Always shows Apple's scrollbar
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/.GlobalPreferences AppleShowScrollBars -string Always
        
        # Disables Apple's default "Natural" trackpad scrolling direction
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/.GlobalPreferences com.apple.swipescrolldirection -bool false
        
        # Sets the Desktop / Finder interface to dark mode
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/.GlobalPreferences AppleInterfaceStyle "Dark"
        
        # Sets Spaces to switch when an application is selected that exists in a different space
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/.GlobalPreferences AppleSpacesSwitchOnActivate -bool true
        
        # Sets preferences for enabling trackpad gestures
        # Sets Trackpad settings to enable 3-finger tap to lookup and 4-finger swipe for Mission Control & Expose
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.AppleMultitouchTrackpad TrackpadThreeFingerVertSwipeGesture -int 0
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.AppleMultitouchTrackpad TrackpadFourFingerVertSwipeGesture -int 2
        
        # 3-finger tap to lookup dictionary word gesture
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.AppleMultitouchTrackpad TrackpadThreeFingerTapGesture -int 2
        
        # Sets Dashboard.app to be a separate space
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.dashboard dashboard-enabled-state -int 2
        
        # Sets Dock prefs to enable Mission Control and Expose System Preference gestures
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.dock showAppExposeGestureEnabled -bool true
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.dock showMissionControlGestureEnabled -bool true
        
        # Trackpad tap to click
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
        
        # Sets Bluetooth Trackpad settings to enable 3-finger tap to lookup and 4-finger swipe for Mission Control & Expose
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerVertSwipeGesture -int 0
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerVertSwipeGesture -int 2
        
        # Disables writing .DS_Store files on network volumes
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.desktopservices DSDontWriteNetworkStores -bool true
        
        # Sets Finder to allow text selection in QuickLook window doesn't work as of 10.11 El Cap
        #/usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.finder QLEnableTextSelection -bool true
        
        # Sets Desktop & Finder settings for all users
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.finder ShowHardDrivesOnDesktop -bool true
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.finder ShowMountedServersOnDesktop -bool true
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.finder ShowPathbar -bool true
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.finder ShowRemovableMediaOnDesktop -bool true
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.finder ShowStatusBar -bool true
        
        # Sets default Finder search to Current Folder, rather than "This Mac"
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.finder FXDefaultSearchScope -string "SCcf"
        
        # Sets default Finder view to Column view
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.finder FXPreferredViewStyle -string "clmv"
        
        # New Finder windows open to user's home folder
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.finder NewWindowTarget -string "PfHm"
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.finder NewWindowTargetIsHome -bool true
        
        # Sets "Go To" shortcut field to home folder "~"
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.finder GoToField -string "~"
        
        # Shows Finder Preview pane along the right portion of Finder windows when a file is selected
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.finder ShowPreviewPane -bool true
        
        # As of 10.12 Sierra, can sort files by names but put Folders at the top of the list, just like Windows does.
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.finder FXSortFoldersFirst -bool true
        
        # Groups apps together in Mission Control
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.dock expose-group-apps -bool true
        
        # Disables drop-shadow from Apple Screenshots
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.screencapture disable-shadow -bool true
        
        # macOS Sierra - automatically removes items from the trash after being there for more than 30 days
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.finder FXRemoveOldTrashItems -bool true
        
        # Disables OS X Keychain Pass check at login for all users. ADPassMon handles this.
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.keychainaccess SyncLoginPassword -bool false
        
        # Disables AirDrop for all users, this also is disabled via JSS Config Profile
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.NetworkBrowser DisableAirDrop -bool true
        
        # Enables Show full URL path in search bar in Safari
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.Safari ShowFullURLInSmartSearchField -bool true
        
        # Sets default sidebar "Device" preferences. Requires reboot to apply
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.sidebarlists.plist systemitems -dict ShowEjectables -bool true ShowHardDisks -bool true ShowRemovable -bool true ShowServers -bool true
        
        # Sets displays to have separate spaces (Mission Control)
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.spaces spans-displays -bool false
        
        # Disables iCloud prompt for all users
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant DidSeeCloudSetup -bool true
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant GestureMovieSeen none
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant LastSeenCloudProductVersion "${sw_vers}"
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant LastSeenBuddyBuildVersion "${sw_build}"
        
        # Sets Setup Assistant as having already shown the macOS Sierra enable Siri prompt
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant DidSeeSiriSetup -bool true
        
        # Disables Siri from running on macOS Sierra
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.assistant.support "Assistant Enabled" -bool false
        
        # Blocks Siri's menubar icon
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.Siri StatusMenuVisible -bool false
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.Siri UserHasDeclinedEnable -bool true
        
        # Disables iCloud Drive & Document Syncing
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.applicationaccess allowCloudDocumentSync -bool false
        
        # Disables Microsoft Silverlight Update Check
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.microsoft.silverlight UpdateMode -int 2
     fi
  done
  
######################### 
# Creates preferences for already created users on machine.
# Should mirror the preferences in User Template
#########################

for USER_HOME in /Users/*
  do
    USER_UID=`basename "${USER_HOME}"`
    if [ ! "${USER_UID}" = "Shared" ]; then 
      if [ ! -d "${USER_HOME}"/Library/Preferences ]; then
        /bin/mkdir -p "${USER_HOME}"/Library/Preferences
        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library
        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences
      fi
      if [ ! -d "${USER_HOME}"/Library/Preferences/ByHost ]; then
        /bin/mkdir -p "${USER_HOME}"/Library/Preferences/ByHost
        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library
        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences
	    /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences/ByHost
      fi
      if [ -d "${USER_HOME}"/Library/Preferences/ByHost ]; then
        # Always shows scroll bars, disables "Natural" scroll direction, and sets theme to "Dark"
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/.GlobalPreferences AppleShowScrollBars -string Always
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/.GlobalPreferences com.apple.swipescrolldirection -bool false
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/.GlobalPreferences AppleInterfaceStyle "Dark"
        
        # Sets Spaces to switch when an application is selected that exists in a different space
        /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/.GlobalPreferences AppleSpacesSwitchOnActivate -bool true
        
        # Sets Trackpad settings to enable 3-finger tap to lookup and 4-finger swipe for Mission Control & Expose
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.AppleMultitouchTrackpad TrackpadThreeFingerVertSwipeGesture -int 0
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.AppleMultitouchTrackpad TrackpadFourFingerVertSwipeGesture -int 2
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.AppleMultitouchTrackpad TrackpadThreeFingerTapGesture -int 2
        
        # Sets Dashboard.app to be a separate space
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.dashboard dashboard-enabled-state -int 2
        
        # Prevents writing .DS_STORE files on network drives
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.desktopservices DSDontWriteNetworkStores -bool true
        
        # Sets Dock prefs to enable Mission Control and Expose System Preference gestures
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.dock showAppExposeGestureEnabled -bool true
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.dock showMissionControlGestureEnabled -bool true
        
        # Sets Bluetooth Trackpad settings to enable 3-finger tap to lookup and 4-finger swipe for Mission Control & Expose
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerVertSwipeGesture -int 0
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerVertSwipeGesture -int 2
        
        # Sets Finder to allow text selection in QuickLook window - doesn't work as of 10.11 El Cap
        #/usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.finder QLEnableTextSelection -bool true
        
        # Sets Finder to show all drives and shares on the Desktop & show the path and status bars in Finder windows
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.finder ShowHardDrivesOnDesktop -bool true
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.finder ShowMountedServersOnDesktop -bool true
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.finder ShowPathbar -bool true
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.finder ShowRemovableMediaOnDesktop -bool true
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.finder ShowStatusBar -bool true
        
        # Sets default Finder search to Current Folder, rather than "This Mac"
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.finder FXDefaultSearchScope -string "SCcf"
        
        # Sets default Finder view to Column view
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.finder FXPreferredViewStyle -string "clmv"
        
        # New Finder windows open to user's home folder
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.finder NewWindowTarget -string "PfHm"
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.finder NewWindowTargetIsHome -bool true
        
        # Sets "Go To" shortcut field to home folder "~"
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.finder GoToField -string "~"
        
        # Shows Finder Preview pane along the right portion of Finder windows when a file is selected
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.finder ShowPreviewPane -bool true
        
        # As of 10.12 Sierra, can sort files by names but put Folders at the top of the list, just like Windows does.
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.finder FXSortFoldersFirst -bool true
        
        # Groups apps together in Mission Control
        /usr/bin/defaults write "${USER_HOME}"//Library/Preferences/com.apple.dock expose-group-apps -bool true
        
        # Disables AirDrop, this also is disabled via JSS Config Profile
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.NetworkBrowser DisableAirDrop -bool true
        
        # Enables Show full URL path in search bar in Safari
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.Safari ShowFullURLInSmartSearchField -bool true
        
        # Sets default sidebar "Device" preferences. Requires reboot to apply
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.sidebarlists.plist systemitems -dict ShowEjectables -bool true ShowHardDisks -bool true ShowRemovable -bool true ShowServers -bool true
        
        # Sets Setup Assistant as having already shown the iCloud prompt
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant DidSeeCloudSetup -bool true
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant GestureMovieSeen none
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant LastSeenCloudProductVersion "${sw_vers}"
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant LastSeenBuddyBuildVersion "${sw_build}"
        
        # Disables drop-shadow from Apple Screenshots
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.screencapture disable-shadow -bool true
        
        # Sets displays to have separate spaces (Mission Control)
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.spaces spans-displays -bool false
        
        # Disables Microsoft Silverlight Update Check
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.microsoft.silverlight UpdateMode -int 2
        
        # Sets Setup Assistant as having already shown the macOS Sierra enable Siri prompt
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant DidSeeSiriSetup -bool true
        
        # Disables Siri from running on macOS Sierra
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.assistant.support "Assistant Enabled" -bool false
        
        # Blocks Siri's menubar icon
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.Siri StatusMenuVisible -bool false
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.Siri UserHasDeclinedEnable -bool true
        # Disables iCloud Drive & Document Syncing
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.applicationaccess allowCloudDocumentSync -bool false
        # Restores ownership of all above PLIST files to their original owners, as the preferences are configured as root
        # for the already created local user accounts.
        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences/.GlobalPreferences.plist
        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences/com.apple.AppleMultitouchTrackpad.plist
        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences/com.apple.applicationaccess.plist
        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences/com.apple.assistant.support.plist
        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences/com.apple.dashboard.plist
        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences/com.apple.desktopservices.plist
        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences/com.apple.dock.plist
        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences/com.apple.driver.AppleBluetoothMultitouch.trackpad.plist
        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences/com.apple.finder.plist
        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences/com.apple.NetworkBrowser.plist
        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences/com.apple.Safari.plist
        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant.plist
        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences/com.apple.sidebarlists.plist
        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences/com.apple.Siri.plist
        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences/com.apple.screencapture.plist
        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences/com.apple.spaces.plist
        /usr/sbin/chown "${USER_UID}" "${USER_HOME}"/Library/Preferences/com.microsoft.silverlight.plist
      fi
    fi
  done

exit
