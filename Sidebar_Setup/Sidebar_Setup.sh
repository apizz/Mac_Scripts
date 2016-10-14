#!/bin/bash

#
# Based on Network folder mount script created by Amsys
#
# Edited and tested for use at The Masters School
#
############## Set Variables

# Set the path to your log file
log="/path/to/log.log"

# Use "afp" or "smb"
mount_protocol="smb"
	
USER=`/bin/ls -l /dev/console | /usr/bin/awk '{print $3}'`	

# Create a function to echo output and to write to a log file
writelog() {
	/bin/echo "${1}"
	/bin/echo $(date) "${1}" >> $log
}

############## START

/bin/echo "--------- START SIDEBAR SETUP SCRIPT ---------" >> $log

############## Remove Existing Sidebar Items and set the new default Sidebar
writelog "Removing all Sidebar items for ${USER} ..."

/usr/local/bin/mysides remove all

if [ $? = 0 ]; then
	writelog "Remove Successful for ${USER}!"
else
	writelog "Remove Failed for ${USER}."
fi

DEFAULT_SIDEBAR_NAME=('All My Files'
'Applications'
'Desktop'
"$USER"
'Documents'
'Pictures'
'Downloads')

DEFAULT_SIDEBAR_FILE=('file:///System/Library/CoreServices/Finder.app/Contents/Resources/MyLibraries/myDocuments.cannedSearch'
'file:///Applications'
"file:///Users/$USER/Desktop"
"file:///Users/$USER"
"file:///Users/$USER/Documents"
"file:///Users/$USER/Pictures"
"file:///Users/$USER/Downloads")

writelog "Adding default Sidebar Items for ${USER} ..."

for ((i = 0; i < "${#DEFAULT_SIDEBAR_NAME[@]}"; i++)); do
	/usr/bin/sfltool add-item -n "${DEFAULT_SIDEBAR_NAME[$i]}" com.apple.LSSharedFileList.FavoriteItems "${DEFAULT_SIDEBAR_FILE[$i]}"
	if [ $? = 0 ]; then
		writelog "${DEFAULT_SIDEBAR_NAME[$i]} Added Successfully for ${USER}!"
	else
		writelog "${DEFAULT_SIDEBAR_NAME[$i]} Failed to be Added for ${USER}."
	fi
done

############## Get the SMBHome Attribute Value
writelog "RETRIEVING: SMBHome attribute for ${USER}."

# Original script specified the dscl search path which made the script fail to acquire
# the SMBHome when connected to Masters remotely.

ADHOME=$(dscl . -read /Users/$USER \
		| grep -e "ENTER_DOMAIN_KEYWORD_HERE" | head -n 1 \
		| sed 's|SMBHome:||g' \
		| sed 's|dsAttrTypeNative:original_smb_home:||g' \
		| sed 's/^[\\]*//' \
		| sed 's:\\:/:g' \
		| sed 's/ \/\///g' \
		| tr -d '\n' \
		| sed 's/ /%20/g')
# Find the user's SMBHome attribute, strip the leading \\ and swap the remaining \ in the path to /
# The result is to turn \\server.domain.com\path\to\home into server.domain.com/path/to/home
	
ADHOMEUSER=$( /usr/bin/basename $ADHOME )

function create_user_adhome_sidebar () {
	/usr/bin/sfltool add-item -n "$ADHOMEUSER" com.apple.LSSharedFileList.FavoriteItems file:///Volumes/$ADHOMEUSER
		
	if [ $? = 0 ]; then
		writelog "Successfully added ${USER}'s ADHOME folder to the sidebar!"
	else
		writelog "Failed to add ${USER}'s ADHOME folder to the sidebar."
	fi
}

# We perform a quick check to make sure that the SMBHome attribute is populated
case "$ADHOME" in 
"" ) 
	writelog "ERROR: User ${USER} does not have an SMBHome attribute.  Exiting script."
	;;
* ) 
	writelog "FOUND: SMBHome identified for ${USER}."
	
	# Checks if sidebar item already exists for user, otherwise checks if Panther folder is mounted,
	# and if not, mounts their Panther folder before adding the sidebar item.
	if [ -d "/Volumes/$ADHOMEUSER" ]; then
		writelog "MOUNT CHECK: ADHOME folder already mounted for ${USER}. Adding to Sidebar ..."
		create_user_adhome_sidebar
	else
		writelog "MOUNT CHECK: ADHOME folder not mounted. Mounting ${USER}'s ADHOME folder to add Sidebar item ..."
	
		mount_script=`/usr/bin/osascript > /dev/null << EOT
		tell application "Finder"
		mount volume "${mount_protocol}://${ADHOME}"
		end tell
		EOT`
	
		sleep 3
	
		if [ -d "/Volumes/$ADHOMEUSER" ]; then
			create_user_adhome_sidebar
		fi
	fi
	;;
esac

/bin/echo "--------- SIDEBAR SETUP SCRIPT COMPLETE ---------" >> $log