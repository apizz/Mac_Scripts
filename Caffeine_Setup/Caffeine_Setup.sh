#!/bin/bash
USER=$(/bin/ls -l /dev/console | /usr/bin/awk '{print $3}')
CAFFPREF="/Users/$USER/Library/Preferences/com.lightheadsw.caffeine.plist"
LOG="/Library/Logs/TMSTech/CaffeineSetup.log"

writelog() {
	echo "${1}" "${2}" "${3}" "${4}"
	echo $(date) "${1}" "${2}" "${3}" "${4}" >> $LOG
}

writelog "---------- START ----------"

if [ ! -f "$CAFFPREF" ]; then
    writelog "No Caffeine preference exists for ${USER}. Creating preference ..."
    
    /usr/bin/defaults write "$CAFFPREF" caffeine "caffeine"
    
    if [ $? = 0 ]; then
        writelog "SUCCESS: Caffeine preference created for ${USER}."
        writelog "Removing dummy preference key/value pair for ${USER} ..."
        
        /usr/bin/defaults remove "$CAFFPREF" caffeine
        
        if [ $? = 0 ]; then
            writelog "SUCCESS: Dummy preference key/value removed for ${USER}."
            
            writelog "Suppressing Caffeine Launch Message ..."
            
            /usr/bin/defaults write "$CAFFPREF" SuppressLaunchMessage -bool true
            
            if [ $? = 0 ]; then
            	writelog "SUCCESS: Caffeine Launch Message Suppressed for ${USER}."
            else
            	writelog "FAILED: Caffeine Launch Message Not Suppressed for ${USER}."
            fi
            
            writelog "Creating Caffeine login item for ${USER} ..."
            
            osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/Caffeine.app", hidden:false}'
            
            if [ $? = 0 ]; then
                writelog "SUCCESS: Caffeine login item created for ${USER}."
            else
                writelog "FAILED: Caffeine login item not created for ${USER}."
            fi
            
            writelog "Launching Caffeine for the first time ..."
            /usr/bin/open -a Caffeine

        else
            writelog "FAILED: Dummy preference key/value not removed for ${USER}."
        fi
    else
        writelog "FAILED: Caffeine preference not created for ${USER}."
    fi
    writelog "---------- DONE ----------"
else
    writelog "Caffeine preference exists for ${USER}. Checking for login item ..."
    
    osascript -e 'tell application "System Events" to get the name of every login item' | grep Caffeine
    
    if [ $? = 0 ]; then
        writelog "FOUND: Caffeine login item for ${USER}."
        
        writelog "Checking for Caffeine suppress launch preference ..."
        
        if [ "$(/usr/bin/defaults read "$CAFFPREF" SuppressLaunchMessage)" = "1" ]; then
        	writelog "SUCCESS: Caffeine Launch Message is suppressed for ${USER}."
        else
        	writelog "Caffeine Launch Message is not suppressed for ${USER}. Suppressing ..."
        	
        	/usr/bin/defaults write "$CAFFPREF" SuppressLaunchMessage -bool true
            
            if [ $? = 0 ]; then
            	writelog "SUCCESS: Caffeine Launch Message Suppressed for ${USER}."
            else
            	writelog "FAILED: Caffeine Launch Message Not Suppressed for ${USER}."
            fi
        fi
        
        writelog "Caffeine check completed successfully for ${USER}!"
        writelog "---------- DONE ----------"
    else
        writelog "NOT FOUND: Caffeine login item does not exist. Creating ..."
        
        osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/Caffeine.app", hidden:false}'
        
        if [ $? = 0 ]; then
            writelog "SUCCESS: Caffeine login item created for ${USER}."
        else
            writelog "FAILED: Caffeine login item not created for ${USER}."
        fi
        writelog "---------- DONE ----------"
    fi
fi

exit
