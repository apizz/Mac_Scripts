#!/bin/sh

#
# Runs a diskutil verifyVolume and writes output of results to a log and a Pass / Fail to PLIST
#
# Paired with EA to read the result of the volume verification.
#

PLIST="/Library/Receipts/JSSData.plist"
LOG="/Library/Logs/VolumeVerify.log"
P_KEY="volumeVerify"
P_RESULT="Passed"
DATE=$(date "+%Y-%m-%d %H:%M:%S")
VOLUME=$(diskutil list | grep "Macintosh HD" | tail -1 | awk '{print $7}')

# Create / Overwrite LOG file with date and time
/bin/echo "$DATE" > "$LOG"

# Verifies volume
volumeVerify=$(diskutil verifyVolume "$VOLUME")

# Writes volume verification info to LOG
/bin/echo "$volumeVerify" >> "$LOG"

# Puts LOG results into variable
#volumeStatus=$(/bin/cat "$LOG")

# Checks if LOG results contain corrupt to indicate a malfunctioning volume
if [[ "$volumeVerify" = *"corrupt"* ]]; then
	P_RESULT="Failed"
fi

# Write result to TMSJSSData.plist for extension attribute collection
defaults write "$PLIST" "$P_KEY" "$P_RESULT"

exit