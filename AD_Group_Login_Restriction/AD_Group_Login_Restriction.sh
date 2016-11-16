#!/bin/bash

#Script to prevent login of users in specific AD groups
#As of OS X 10.9 MCX- and profile-based methods for this do not seem to be working
#Code borrowed from https://jamfnation.jamfsoftware.com/discussion.html?id=4591

USER=`/bin/ls -l /dev/console | /usr/bin/awk '{print $3}'`
LOG="/Library/Logs/TMSTech/TMSRestrictedLogins.log"
JAMFHELPER="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
windowtype="fs"
heading="Restricted Login"
icon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns"
description="Student logins on this computer are restricted. Please use a different computer.

This computer will return to the login window in 10 seconds."

writelog () {
    /bin/echo "${1}"
    /bin/echo $(date) "${1}" >> $LOG
}

writelog "${USER} is a student. Killing login session ..."

for LOGWINPID in $(/usr/bin/pgrep loginwindow) ; do
    P_OWNER=`/bin/ps -eo user,pid | /usr/bin/grep ${LOGWINPID} | /usr/bin/awk '{print $1}'`
    	
    if [ "$P_OWNER" = "$USER" ]; then
     
        "$JAMFHELPER" -windowType "$windowtype" -heading "$heading" -icon "$icon" -description "$description" & sleep 10
        
        /usr/bin/killall jamfHelper
        
        /bin/kill -3 ${LOGWINPID}
        
        if [ $? = 0 ]; then
            writelog "${USER}'s login session successfully killed!"
            
            if [ -d "/Users/${USER}" ]; then
                writelog "${USER} home folder detected. Removing ..."
            
                /usr/bin/dscl localhost -delete /Local/Default/Users/${USER}
                
                /bin/rm -rf /Users/${USER}
                
                if [ ! -d "/Users/${USER}" ]; then
                    writelog "${USER}'s home folder successfully removed!"
                else
                    writelog "${USER}'s home folder removal failed."
                fi
            fi
            
        else
            writelog "${USER}'s login session was not killed."
        fi
    fi
done

exit