#!/bin/sh

USER=`/bin/ls -l /dev/console | /usr/bin/awk '{print $3}}'`

rm -rf /Users/$USER/Library/Keychains/*

if [ $? = 0 ]; then
    /bin/echo "Successfully deleted ${USER}'s keychain!"
else
    /bin/echo "Failed to delete ${USER}'s keychain."
    exit 1
fi

exit 0