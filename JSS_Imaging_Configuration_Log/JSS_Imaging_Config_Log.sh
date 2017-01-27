#!/bin/bash

#########################################
# Created by AP Orlebeke - 01/27/17
# 
# Script designed to be used in Casper Imaging workflow, or as a part of a separate policy
# depending on how you've configured your environment.
#
# As of this writing, there is no way to automatically gather the selected imaging
# configuration used on a machine. The result is this script, which must be assigned
# to each individual imaging configuration (or policy). 
#
# Writes the desired imaging configuration name to a log file in /var/log
# along with a date & time stamp. Subsequent imaging will append (not replace) this file.
#
# NOTE: Because of how scripts are treated in Casper Imaging vs. in policies, there are
# two different potential log paths. For use with Casper Imaging, you need to explicitly
# include the $1 variable to point to the internal hard drive volume.
#
# (Optional) Use with a JSS extension attribute and tail the last line of the file
# to read it.  You can find this EA here: 
# https://github.com/apizz/JSS_Extension_Attributes/blob/master/JSS_Imaging_Configuration_EA/JSS_Imaging_Config_EA.sh
#########################################

# Imaging Configuration Name
IMG_CFG="ENTER IMAGING CONFIGURATION NAME HERE"

# Date & Time Stamp
DATE=$(date "+%Y-%m-%d %H:%M %p")

# Path to Log File for use with Casper Imaging workflow
LOG="$1/var/log/imagingconfig.log"
# Path to Log File for use with a policy
# LOG="/var/log/imagingconfig.log"

# Creates log file if it does not already exist
if [ ! -f "$LOG" ]; then
    /usr/bin/touch "$LOG"
fi

# Appends Date & Time Stamp along with config name to log file
/bin/echo "$DATE $IMG_CFG" >> "$LOG"

exit
