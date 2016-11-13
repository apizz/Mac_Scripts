#!/bin/bash

SMART_UNINSTALL_APP="/Applications/SMART Technologies/SMART Uninstaller.app"
SMART_UNINSTALL="/Applications/SMART Technologies/SMART Uninstaller.app/Contents/Resources/uninstall"

if [ -d "$SMART_UNINSTALL_APP" ]; then
    /bin/echo "SMART Software Install Detected."
    /bin/echo "Uninstalling SMART Software Completely ..."

    "$SMART_UNINSTALL" --all

    if [ $? = 0 ]; then
        /bin/echo "SMART Software Uninstall: Successful!"
    else
        /bin/echo "SMART Software Uninstall: Failed."
        exit 1
    fi
else
    /bin/echo "SMART Software Not Installed. Exiting Script ..."
fi

exit