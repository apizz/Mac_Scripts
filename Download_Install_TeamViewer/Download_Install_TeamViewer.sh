#!/bin/bash

# Downloads TeamViewer 10/11/12/13 Host module package, effectively going to get.teamviewer.com/yourcustomURL in a browser.
#
# Script has been tested successfully with versions 10, 11, 12, & 13
# 
# To get the full module download link, enter your custom module link in a browser and right-click on link in the middle of
# the window.  You will need this for the curl command to download the install PKG using this script.
#

########################################################
# Log file script writes to using writelog function below
logfile="/path/to/TeamViewerInstall.log"
# Download location for TeamViewer module installer PKG
downloaddir="/Users/Shared"
# Leave as is to automatically open TeamViewer Host once installed
APP="TeamViewerHost"
# Name of TeamViewer module installer PKG
PKG="InstallTeamViewer-XXXXXXXXXX.pkg"
# In order to have your custom TeamViewer branding apply, the PKG variable MUST have the 10-digit 
# branding ID in the PKG name. In my testing I've found this to be necessary.
#
# More info about getting this URL here: https://www.jamf.com/jamf-nation/discussions/10366/customizing-deploying-teamviewer#responseChild148891
# Direct URL where X is the version - ex. /version_12x/
# ex. https://dl.tvcdn.de/download/version_12x/CustomDesign/Install%20TeamViewerHost-aaa1aa1aa1.pkg
URL='https://dl.tvcdn.de/download/version_1Xx/CustomDesign/Install....-XXXXXXXXXX.pkg'

# Create a function to echo output and write to a log file
writelog () {
	/bin/echo "${1}"
	/bin/echo $(/bin/date) "${1}" >> $logfile
}
########################################################

# Check for TeamViewer.log
if [ -f $logfile ]; then
    writelog "CHECK: TeamViewerInstall.log Present."
else
    /usr/bin/touch $logfile
    writelog "CREATED: TeamViewerInstall.log"
    # Bad practice to set file permission to 777, but it's a log, so I say w/e
    /bin/chmod 777 $logfile
    if [ $? = 0 ]; then
        writelog "SUCCESSFUL: Set TeamViewerInstall.log Permissions."
    else
        writelog "FAILED: Set TeamViewerInstall.log Permissions."
    fi
fi

writelog "------- START -------"

writelog "DOWNLOADING: TeamViewer Install PKG"

# Download TeamViewer Custom module
/usr/bin/curl "$URL" -o "${downloaddir}/${PKG}"

if [ -f "${downloaddir}/${PKG}" ]; then
    # Installs package
    writelog "INSTALLING: TeamViewer module ..."
    /usr/sbin/installer -pkg "${downloaddir}/${PKG}" -target /
    if [ $? = 0 ]; then
        writelog "TeamViewer Install: Successful!"
        # Deletes package after successful install
        writelog "DELETING: TeamViewer Host PKG ..."
        sudo /bin/rm -rf "${downloaddir}/${PKG}"

        if [ ! -f "$downloaddir/$PKG" ]; then
            writelog "TeamViewer Install PKG Deletion: Successful!"
        else
            writelog "TeamViewer Install PKG Deletion: Failed."
        fi
        
        writelog "Launching TeamViewer for the first time ..."
	# Open TeamViewer to get 
        /usr/bin/open -a "$APP"

        writelog "Script Complete: TeamViewer Installed!"
    else
        writelog "TeamViewer Install: Failed."
    fi
fi

writelog "------- DONE -------"

exit
