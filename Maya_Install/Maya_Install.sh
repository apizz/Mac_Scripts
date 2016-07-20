#!/bin/bash

# Script to install Maya 2016
# This script assumes you've placed the Install Maya 2016.app in the INSTALLDIR
# Make sure you change XXX-XXXXXXXX serial & product key.

INSTALLDIR="/Users/Shared"
MAYA="$INSTALLDIR/Install Maya 2016.app"
MAYASETUP="$MAYA/Contents/MacOS/setup"

/bin/echo "Beginning Maya 2016 install."

#Install Maya 2016
sudo "$MAYASETUP" --noui --force --serial_number=XXX-XXXXXXXX --product_key=XXXXX --license_type=<kStandalone or kNetwork> #--server_name=<name>

if [ $? = 0 ]; then
    /bin/echo "Maya 2016 Install: Successful."
    /bin/echo "Attempting to delete Maya installer."
    
    /bin/rm -rf "$MAYA"
    
    if [ ! -d "$MAYA" ]; then
        /bin/echo "Maya 2016 Installer Deletion: Successful."
    else
        /bin/echo "Maya 2016 Installer Deletion: Failed."
    fi
        
else
    /bin/echo "Maya 2016 Install: Failed."
fi

/bin/echo "DONE"

exit
