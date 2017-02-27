#!/bin/sh

#
# Runs a diskutil verifyDisk and writes output of results to a log and a Pass / Fail to PLIST
#
# Paired with EA to read the result of the disk verification.
#

PLIST="/Library/Receipts/JSSData.plist"
LOG="/Library/Logs/DiskVerify.log"
P_KEY="diskVerify"
P_RESULT="Passed"
DATE=$(date "+%Y-%m-%d %H:%M:%S")
DISK=$(diskutil list | grep internal | grep -v virtual | awk '{print $1}')

# Create / Overwrite LOG file with date and time
/bin/echo "$DATE" > "$LOG"

# Verifies disk. In the case of Fusion Drives, checks both the SSD and HDD portions.
for d in $DISK
do
	diskVerify=$(diskutil verifyDisk $(basename $d))
	
	/bin/echo "$diskVerify" >> "$LOG"
done

# Checks if LOG results contain corrupt to indicate a malfunctioning volume
if [[ "$diskVerify" = *"corrupt"* ]]; then
	P_RESULT="Failed"
fi

# Write result to TMSJSSData.plist for extension attribute collection
defaults write "$PLIST" "$P_KEY" "$P_RESULT"

exit
