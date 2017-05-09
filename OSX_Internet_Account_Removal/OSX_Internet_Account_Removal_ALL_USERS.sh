#!/bin/bash

osvers=$(sw_vers -productVersion | awk -F. '{print $2}')

if [ "$osvers" = "11" ]; then
	DB="Library/Accounts/Accounts3.sqlite"
elif [ "$osvers" = "12" ]; then
	DB="Library/Accounts/Accounts4.sqlite"
fi

for USER in /Users/* ;
do
	if [ -f "$USER/${DB}" ]; then
		/usr/bin/sqlite3 "$USER"/"$DB" 'DELETE FROM ZACCOUNT'
		
		if [ $? = 0 ]; then
    			/bin/echo "Successfully removed all Internet Accounts for $(basename $USER) from sqlite db!"
		else
    			/bin/echo "Failed to remove all Internet Accounts for $(basename $USER) from sqlite db."
		fi
	fi
done

exit
