#!/bin/bash

# Script to install Maya 2016
# This script assumes you've placed the Install Maya 2016.app in the INSTALLDIR
# Make sure you change XXX-XXXXXXXX serial & product key.

INSTALLDIR="/Users/Shared"
MAYA="Install Maya 2016.app"
MAYAINSTALLER="Install Maya 2016.app/Contents/MacOS/setup"

/bin/echo "Beginning Maya 2016 install."

#Install Maya 2016
"$INSTALLDIR"/"$MAYAINSTALLER" --noui --force --serial_number=XXX-XXXXXXXX --product_key=XXXXX --license_type=<kStandalone or kNetwork> #--server_name=<name>

if [ $? = 0 ]; then
    /bin/echo "Maya 2016 Install: Successful."
    /bin/echo "Attempting to delete Maya installer."
    
    /bin/rm -rf "$INSTALLDIR"/"$MAYA"
    
    if [ ! -d "$INSTALLDIR"/"$MAYA" ]; then
        /bin/echo "Maya 2016 Installer Deletion: Successful."
    else
        /bin/echo "Maya 2016 Installer Deletion: Failed."
    fi
        
else
    /bin/echo "Maya 2016 Install: Failed."
fi

/bin/echo "DONE"

exit
