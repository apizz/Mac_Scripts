#!/bin/bash

#
# Script depends on 2 things:
# 1) Being connected to institution's network
# 2) Script being run as root
#
# Created by AP Orlebeke - 10/18/16
#
############### Initial Variables
DSEDITGROUP="/usr/sbin/dseditgroup"
# Local admin user account
LADMIN="admin"
LPADMIN="_lpadmin"
USER=`/bin/ls -l /dev/console | /usr/bin/awk '{print $3}'`
LOG="/Library/Logs/ADGroupPrinterCheck.log"

# Insert additional variables for AD Group checks
ADGROUP_ONE=""
ADGROUP_TWO=""
ADGROUP_THREE=""
################

writelog () {
	/bin/echo "${1}"
	/bin/echo $(date) "${1}" >> $LOG
}

# Create log if not present
if [ ! -f "$LOG" ]; then
	/usr/bin/touch "$LOG"
	
	chmod 777 $LOG
	
	if [ $? = 0 ]; then
		writelog "Creation Date & Time"
	else
		/bin/echo "Log Creation Failed."
	fi
fi

# dseditgroup membership check for _lpadmin
LPADMIN_CHK=`$DSEDITGROUP -o checkmember -m "$USER" "$LPADMIN" | /usr/bin/awk '{print $1}'`

if [ "$LPADMIN_CHK" = "yes" ]; then
	writelog "$USER is already a member of the _lpadmin group. Exiting script."
	exit
fi

# dseditgroup membership check for local admin user
LADMIN_CHK=`$DSEDITGROUP -o checkmember -m "$USER" "$LADMIN" | /usr/bin/awk '{print $1}'`

# Checks if user is already an admin user
if [ "$LADMIN_CHK" = "yes" ]; then
	writelog "$USER is already an admin and can add printers. Exiting script."
	exit
fi

# dseditgroup AD group membership checks
ADGROUP_ONE_CHK=`$DSEDITGROUP -o checkmember -m "$USER" "$ADGROUP_ONE" | /usr/bin/awk '{print $1}'`
ADGROUP_TWO_CHK=`$DSEDITGROUP -o checkmember -m "$USER" "$ADGROUP_TWO" | /usr/bin/awk '{print $1}'`
ADGROUP_THREE_CHK=`$DSEDITGROUP -o checkmember -m "$USER" "$ADGROUP_THREE" | /usr/bin/awk '{print $1}'`

# If user is a member of any of the above security groups, will add to _lpadmin group	
if [ "$ADGROUP_ONE_CHK" = "yes" ] || [ "$ADGROUP_TWO_CHK" = "yes" ] || [ "$ADGROUP_THREE_CHK" = "yes" ]; then
	writelog "Adding $USER to _lpadmin Group ..."
	
	# Adds user to _lpadmin group to be able to add printers as a non-admin
	$DSEDITGROUP -o edit -a "$USER" -t user "$LPADMIN"
	
	if [ $? = 0 ]; then
		writelog "Add $USER to _lpadmin Group: Successful!"
	else
		writelog "Add $USER to _lpadmin Group: Failed."
	fi
else
	writelog "$USER is not a member of required AD Groups to add printers. Exiting script."
fi

exit
