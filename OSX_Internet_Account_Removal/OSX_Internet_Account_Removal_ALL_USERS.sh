#!/bin/bash

DB="Library/Accounts/Accounts3.sqlite"

for USER in /Users/*
do
	if [ -f "$USER/Library/Accounts/Accounts3.sqlite" ]; then
		/usr/bin/sqlite3 "$USER"/"$DB" 'DELETE FROM ZACCOUNT'
		
		if [ $? = 0 ]; then
    			/bin/echo "Successfully removed all Internet Accounts for $(basename $USER) from sqlite db!"
		else
    			/bin/echo "Failed to remove all Internet Accounts for $(basename $USER) from sqlite db."
		fi
	fi
done

exit
