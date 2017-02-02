#!/bin/bash

USER=$(/bin/ls -l /dev/console | /usr/bin/awk '{print $3}')
DB="/Users/$USER/Library/Accounts/Accounts3.sqlite"

/usr/bin/sqlite3 "$DB" 'DELETE FROM ZACCOUNT'

if [ $? = 0 ]; then
    /bin/echo "Successfully removed all Internet Accounts for ${USER} from sqlite db!"
else
    /bin/echo "Failed to remove all Internet Accounts for ${USER} from sqlite db."
fi

exit