#!/bin/bash

# Downloads TeamViewer 10/11 Host module package, effectively going to get.teamviewer.com/yourcustomURL in a browser.
#
# Script has been tested successfully with versions 10 & 11.  Needs testing on version 12.
# 
# To get the full module download link, enter your custom module link in a browser and right-click on link in the middle of
# the window.  You will need this for the curl command to download the install PKG using this script.
#

########################################################
logfile="/path/to/TeamViewerInstall.log"
downloaddir="/Users/Shared"
PKG="InstallTeamViewer-XXXXXXXXXX.pkg"

# Create a function to echo output and write to a log file
writelog () {
	/bin/echo "${1}"
	/bin/echo $(date) "${1}" >> $logfile
}
########################################################

# Check for TeamViewer.log
if [ -f $logfile ]; then
    writelog "CHECK: TeamViewerInstall.log Present."
else
    /usr/bin/touch $logfile
    writelog "CREATED: TeamViewerInstall.log"
    /bin/chmod 777 $logfile
    if [ $? = 0 ]; then
        writelog "SUCCESSFUL: Set TeamViewerInstall.log Permissions."
    else
        writelog "FAILED: Set TeamViewerInstall.log Permissions."
    fi
fi

writelog "------- START -------"

# Set download directory to working directory.
/usr/bin/cd "$downloaddir"

if [ "$(pwd)" = "$downloaddir" ]; then
    writelog "Working Directory Set to Download Directory: Successful."
else
    writelog "Working Directory Set to Download Directory: Failed."
fi

writelog "DOWNLOADING: TeamViewer Install PKG"

# Enter your full TeamViewer download link in the single quotes.
# If you are on version 10 of TeamViewer, it will be ../version_10x/.. rather than version_11x
#
# ex. https://download.teamviewer.com/download/version_11x/CustomDesign/Install%20TeamViewerHost-XXXXXXXXXX.pkg
#
# In order to have your custom TeamViewer branding apply, the PKG variable MUST have 10-digit 
# branding ID in the PKG name.

/usr/bin/curl 'https://download.teamviewer.com/download/version_1Xx/CustomDesign/Install....-XXXXXXXXXX.pkg' -o $PKG

if [ -f "$downloaddir/$PKG" ]; then
    # Installs package
    writelog "INSTALLING: TeamViewer module ..."
    /usr/sbin/installer -pkg "$downloaddir/$PKG" -target /
    if [ $? = 0 ]; then
        writelog "TeamViewer Install: Successful."
        
        writelog "DELETING: TeamViewer Host PKG ..."
        sudo /bin/rm -rf "$downloaddir/$PKG"

        if [ ! -f "$downloaddir/$PKG" ]; then
            writelog "TeamViewer Install PKG Deletion: Successful."
        else
            writelog "TeamViewer Install PKG Deletion: Failed."
        fi
        
        writelog "Launching TeamViewer for the first time ..."
        # If using TeamViewer Host, put TeamViewerHost in double quotes. This will launch TeamViewer and
	# and display the unattended password screen.
        /usr/bin/open -a "TeamViewer"

        writelog "Script Complete: TeamViewer Installed!"
    else
        writelog "TeamViewer Install: Failed."
    fi
fi

writelog "------- DONE -------"

exit
