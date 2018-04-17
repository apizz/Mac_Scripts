#!/bin/bash

####################
# ABOUT THE SCRIPT
# 
# Restores never-booted High Sierra OS images to an external machine connected via Target Disk Mode,
# automatically determining the optimal OS image filesystem based on the detected storage
# media (SSD = APFS, HDD = HFS, Fusion Drive = HFS).
#
# Requirements & Assumptions:
# 
#   1) The external machine to be restored already has the same version of High Sierra installed
#	   as the OS restore image.
#	     * Apple's firmware updates come solely via the macOS installer app & macOS updates
#
#   2) You are using AutoDMG (https://github.com/MagerValp/AutoDMG) to build never-boot OS images.
#
#	3) You intend to either restore an OS image of the same filesystem (HFS > HFS; APFS > APFS)
#	   or move from HFS to APFS (SSDs only) based on the drive storage media
#	     * See https://blog.macsales.com/43043-using-apfs-on-hdds-and-why-you-might-not-want-to
#
#	4) 
#
# Additional (Optional) Capabilities
#
#	1) Copy the jamf.log off a JAMF-managed machine prior to OS restore and copy it back afterward.
#		 * Similar to what you may have been used to with Jamf Imaging
#
#	2) Write a file with the desired computer hostname for collection & use later in your deployment
#	   workflow.
#
#	3) If you've restored an OS image via this script previously and used --compname / -c to write
#	   a file with your desired hostname, use this file instead of entering the same or different
#	   hostname.
#
#	4) Write the OS image restore start and end timestamps for collection & use later in your
#	   deployment workflow.
#		 * For example, I like to know how long it takes to go from base Mac to fully deployed
#
#

# Never-booted OS images
OS_IMAGE_PATH="/Users/admin/Downloads"
APFS_OS_IMAGE="osx_updated_180402-10.13.4-17E199.apfs.dmg"
HFS_OS_IMAGE="osx_updated_180402-10.13.4-17E199.hfs.dmg"

# Compname variables
# Computer hostname required (true)
REQUIRE_COMPNAME=1
# Computer hostname not required (false)
#REQUIRE_COMPNAME=0
# Path to write computer hostname file for later MDM collection
COMPNAME_FILE="/Library/Receipts/CompName.txt"

# Log & path based on computer name & date vs. date only to write output to
DATE=$(/bin/date "+%y%m%d_%H%M%S")
if [ "$REQUIRE_COMPNAME" = 1 ]; then
	LOGPATH="/Users/${USER}/Desktop/OS_RESTORE_LOGS/${COMPNAME}"
	LOG="${LOGPATH}/HighSierraOSRestore-${COMPNAME}-${DATE}.log"
else
	LOGPATH="/Users/${USER}/Desktop/OS_RESTORE_LOGS/"
	LOG="${LOGPATH}/HighSierraOSRestore-${DATE}.log"
fi

# JAMF variables: for use with --keepjamflog / -k
JAMFLOG="/var/log/jamf.log"
TMP_JAMFLOG="${LOGPATH}/jamf.log"

# Plist to write OS restore start and end timestamps to: for use with --timestamps / -t
PLIST="/Library/Receipts/OSRestore.plist"

######## DO NOT EDIT BELOW THIS LINE ########

# User variables
ROOT=$(/usr/bin/whoami)
USER=$(/bin/ls -l /dev/console | /usr/bin/awk '{print $3}')

# Program Info
PROGRAM="HighSierraOSRestore.sh"
AUTHOR="AP Orlebeke"
VERSION="1.0"
GITHUB="https://github.com/apizz/Mac_Scripts/HighSierraOSRestore"
LAST_UPDATE_DATE="4/16/18"

# Text formatting
TEXT_NORMAL='\033[0m'
TEXT_RED='\033[31m'
TEXT_GREEN='\033[32m'
TEXT_YELLOW='\033[33m'
TEXT_BLUE='\033[34m'

##### FUNCTIONS

function writelog() {
	/bin/echo "${1}"
	/bin/echo $(/bin/date "+%Y-%m-%d %H:%M:%S") "${1}" >> "$LOG"
}

function showhelp() {
	/bin/echo "Usage:  sudo ./${PROGRAM} [-h] [-v] [-e] [--compname <compname>]

Arguments:
  --help, -h			Show this help message.
  --version, -v			Show version info.
  --exitcodes, -e       Prints exitcode list.



Optional Arguments:
  --dry-run, -d			Run through script workflow to test output & results.
  --compname, -c		Provide computer hostname to for use as part of MDM enrollment
  				and computer renaming.
  --reusecompname		Will attempt to use previous compname at ${COMPNAME_FILE}.
  --timestamps, -t		Write timestamps before and after OS image restore to external
  				machine PLIST (${PLIST}) for use as part of enrollment or larger deployment
  				calculation.
  --keepjamflog, -k		Will copy the jamf log off the external machine (if it exists) to
  				${LOGPATH} folder and copy it back after the restore.
  --force-hfs, -f		For opting to use an HFS OS image over an APFS image on SSDs."
}

function version() {
	echo "${TEXT_BLUE}${PROGRAM}: Written by ${AUTHOR} - version ${VERSION}.${TEXT_NORMAL}"
	echo "${TEXT_BLUE}Available on ${GITHUB}${TEXT_NORMAL}"
	echo "${TEXT_BLUE}Last updated on ${LAST_UPDATE_DATE}${TEXT_NORMAL}"
}

function exit_codes() {
	/bin/echo "Exit Codes:
	1: --reusecompname: No computer hostname found in ${COMPNAME_FILE}
	2: --reusecompname: No ${COMPNAME_FILE} found on external machine
	3: --keepjamflog: No jamf.log file found on external machine
	4: Filesystem unable to be determined on external machine
	5: Filesystem restore failed
	6: Script not run as 'root'
	7: One or more missing OS image files from ${OS_IMAGE_PATH}
	8: No external machine connected
	9: No external machine volume mounted
	10: Failed to write ${COMPNAME_FILE} file with computer hostname
	11: --compname / -c command supplied with no computer hostname defined; REQUIRE_COMPNAME set to required
	12: --compname / -c command supplied with no computer hostname defined; REQUIRE_COMPNAME set to not required
	13: Unkown command passed to script"
}

function apfs_mount_post_restore() {
	writelog "Mounting ${EXT_VOLUME} ..."
	
	# Mount to /Volumes/Macintosh HD 1
	/bin/mkdir "$EXT_VOLUME"
	/sbin/mount_apfs /dev/${EXT_DISK_DEVICENODE} "$EXT_VOLUME"
}

function assess_storage_type() {
	EXT_DISK_DEVICEID=$(/usr/sbin/diskutil list external | /usr/bin/awk '/0:/{print $NF}' | /usr/bin/tail -1)
	FUSION_DRIVE=$(/usr/sbin/diskutil info ${EXT_DISK_DEVICEID} | /usr/bin/awk '/Fusion Drive/{print $NF}')
	
	if [ "$FUSION_DRIVE" = "Yes" ]; then
		# Fusion Drive
		EXT_DISK_DEVICENODE="$EXT_DISK_DEVICEID"
		FILESYSTEM="HFS"
		OS_IMAGE="$HFS_OS_IMAGE"
		STORAGE_TYPE="a Fusion Drive"
	else
		SSD=$(/usr/sbin/diskutil info ${EXT_DISK_DEVICEID} | /usr/bin/grep "SSD")
		### NEED WORK HERE FOR DIFFERENTIATING HFS vs. APFS FORMATTED DRIVES ###
		EXT_DISK_ID=$(/bin/ls -1 /dev | /usr/bin/grep "^${EXT_DISK_DEVICEID}" | /bin/tail -1)
		EXT_DISK_FS=$(/usr/sbin/diskutil info ${EXT_DISK_ID} | /usr/bin/awk '/Type (Bundle)/{print $NF}')
		if [ "$SSD" != "" ]; then
			if [ "$FORCE_HFS" = 1 ]; then
				# SSD & HFS
				EXT_DISK_DEVICENODE="${EXT_DISK_DEVICEID}s2"
				FILESYSTEM="HFS"
				OS_IMAGE="$HFS_OS_IMAGE"
				STORAGE_TYPE="an SSD"
			else
				# SSD & APFS
				EXT_DISK_DEVICENODE="${EXT_DISK_DEVICEID}s1"
				FILESYSTEM="APFS"
				OS_IMAGE="$APFS_OS_IMAGE"
				STORAGE_TYPE="an SSD"
			fi
		else
			# HDD
			EXT_DISK_DEVICENODE="${EXT_DISK_DEVICEID}s2"
			FILESYSTEM="HFS"
			OS_IMAGE="$HFS_OS_IMAGE"
			STORAGE_TYPE="an HDD"
		fi
	fi
	
	# Print hardware storage info
	writelog "Storage type is ${STORAGE_TYPE}. Will use ${FILESYSTEM} filesystem for OS restore ..."
	
	VOLUMEPATH=$(/usr/sbin/diskutil info ${EXT_DISK_DEVICENODE} | /usr/bin/grep "Mount Point" | /usr/bin/sed 's/^[^/]*//')
	EXT_VOLUME="$VOLUMEPATH"
}

function check_compname() {
	if [ -f "${EXT_VOLUME}/${COMPNAME_FILE}" ]; then
		COMPNAME=$(/bin/cat "${EXT_VOLUME}/${COMPNAME_FILE}")
		writelog "${COMPNAME_FILE} file detected ..."
		if [ "$COMPNAME" != "" ]; then
			writelog "Will set computer hostname to ${COMPNAME} ..."
		else
			writelog "No computer hostname found in ${COMPNAME_FILE}."
			exit 1
		fi
	else
		writelog "Could not find ${COMPNAME_FILE} file on external machine."
		writelog "Please specify a computer hostname with --compname / -c <compname>"
		exit 2
	fi
}

function jamf_log_copy() {
	# If jamf.log file exists, copy it off before restoring
	if [ -f "${EXT_VOLUME}${JAMFLOG}" ]; then
		writelog "Found jamf.log on external machine."
		writelog "Copying ..."
		# Dry-run
		if [ "$DRY_RUN" = 1 ]; then
			writelog "Dry-run: jamf.log copy"
		else
			# Make 
			/bin/mkdir -p "${LOGPATH}"
			/bin/cp "${EXT_VOLUME}""${JAMFLOG}" "$TMP_JAMFLOG"

			# Verify successful copy
			if [ "$(/bin/echo $?)" = 0 ]; then
				writelog "jamf.log copy successful!"
			else
				writelog "${TEXT_RED}jamf.log copy failed.${TEXT_NORMAL}"
			fi
		fi
	else
		writelog "jamf.log does not exist on target machine."
		writelog "Please rerun script without --keepjamflog. Exiting ..."
		exit 3
	fi
}

function jamf_log_copyback() {
	writelog "Copying jamf.log back to machine ..."
	
	# Copy jamf.log back, if it exists
	if [ -f "$TMP_JAMFLOG" ]; then
		/bin/cp "$TMP_JAMFLOG" "${EXT_VOLUME}${JAMFLOG}"
	
		# Set ownership & permissions
		/usr/sbin/chown 0:0 "${EXT_VOLUME}${JAMFLOG}"
		/bin/chmod 755 "${EXT_VOLUME}${JAMFLOG}"
	fi
}

function os_image_restore() {
	# Get OS restore start timestamp
	restore_start_time
	echo "${TEXT_GREEN}${RESTORE_START}${TEXT_NORMAL}"
	
	writelog "Beginning erase & restore ..."
	writelog "Restoring $OS_IMAGE ..."
	
	# Erase & Restore w/ no prompt
	if [ "$FILESYSTEM" != "" ]; then

		if [ "$DRY_RUN" = 1 ]; then
			writelog "Dry-run: OS image restore"
		else
			/usr/sbin/asr restore --source "${OS_IMAGE_PATH}/${OS_IMAGE}" --target /dev/${EXT_DISK_DEVICENODE} --erase --noprompt
			exitcode=$(/bin/echo $?)
		fi
	else
		writelog "ERROR: Unsure what filesystem is to be configured. Exiting ..."
		exit 4
	fi

	# Error check
	if [ "$exitcode" != 0 ]; then
		echo "${TEXT_RED}Failed to Restore. Exiting ...${TEXT_NORMAL}"
		exit 5
	else
		# Get OS restore end timestamp
		restore_end_time
		echo "${TEXT_GREEN}${RESTORE_END}${TEXT_NORMAL}"
	fi
}

function restore_start_time() {
	RESTORE_START=$(/bin/date "+%Y-%m-%d %H:%M:%S")
}

function restore_end_time() {
	RESTORE_END=$(/bin/date "+%Y-%m-%d %H:%M:%S")
}

function restore_done() {
	writelog ""
	writelog "DONE! Safe to unplug target machine."

	# State completion
	/usr/bin/say "OS restore complete for ${COMPNAME}. Please disconnect."
}

function unmount_disk() {
	/usr/sbin/diskutil unmountDisk /dev/${EXT_DISK_DEVICEID}
}

function unmount_post_jamflogcopy() {
	writelog "Unmounting post jamf log copy ..."
	
	# Unmount
	/usr/sbin/diskutil unmount ${EXT_DISK_DEVICENODE}
	unmountcode=$(/bin/echo $?)

	# Only remove the created /Volumes directory if unmount successful
	if [ "$unmountcode" = 0 ]; then
		/bin/rm -rf "$EXT_VOLUME"
	fi
}

function verify_root() {
	if [ "$ROOT" != "root" ]; then
		writelog "This script must be run as root - add 'sudo'"
		exit 6
	fi
}

function verify_os_images() {
	if [ ! -f "${OS_IMAGE_PATH}/${APFS_OS_IMAGE}" ] || [ ! -f "${OS_IMAGE_PATH}/${HFS_OS_IMAGE}" ]; then
		writelog "Specified OS Image file(s) does not exist. Exiting ..."
		exit 7
	fi
}

function verify_ext_disk() {
	if [ "$EXT_DISK_DEVICEID" = "" ]; then
		writelog "No external disk detected. Disconnect and reconnect the external computer."
		writelog "Exiting ..."
		exit 8
	elif [ ! -d "$EXT_VOLUME" ]; then
		writelog "No mounted external disk volume detected. Disconnect and reconnect the external computer."
		writelog "Exiting ..."
		exit 9
	fi
}

function write_restore_timestamps() {
	# Write OS Restore Start & End Timestamps
	if [ "$DRY_RUN" = 1 ]; then
		writelog "Dry-run: Write OS restore start & end timestamps to ${EXT_VOLUME}${PLIST}"
	else
		writelog "Writing OS restore start & end timestamps to ${EXT_VOLUME}${PLIST} ..."
		/usr/bin/defaults write "${EXT_VOLUME}${PLIST}" os_restore_start "$RESTORE_START"
		/usr/bin/defaults write "${EXT_VOLUME}${PLIST}" os_restore_end "$RESTORE_END"
	fi
}

function write_compname_txt() {
	writelog "Writing ${COMPNAME} to ${COMPNAME_FILE} ..."

	# Write file
	if [ "$DRY_RUN" = 1 ]; then
		writelog "Dry-run: Write ${EXT_VOLUME}${COMPNAME_FILE}"
	else
		writelog "$COMPNAME" > "${EXT_VOLUME}${COMPNAME_FILE}"
	fi

	if [ "$DRY_RUN" = 1 ]; then
		writelog "Dry-run: Successful write of ${COMPNAME_FILE}!"
	elif [ -f "${EXT_VOLUME}${COMPNAME_FILE}" ]; then
		writelog "Successfully wrote ${COMPNAME_FILE}!"
	else
		writelog "No ${COMPNAME_FILE} file detected. File write failed. Exiting ..."
		exit 10
	fi
}

######## CHECKS & SCRIPT ########

# Parse commands
while [ ${#} -gt 0 ]; do
    case "${1}" in
		--help | -h)
			showhelp
			exit
			;;
		--version | -v)
      		version
      		exit
      		;;
      	--exitcodes | -e)
			exit_codes
			exit
			;;
		--dry-run | -d)
			DRY_RUN=1
			writelog "${TEXT_GREEN}Dry-run enabled${TEXT_NORMAL}"
			;;
      	--reusecompname)
    		REUSE_COMPNAME=1
    		;;
    	--compname | -c)
    		COMPNAME="$2"
    		if [[ "$COMPNAME" == -* ]] && [ "$REQUIRE_COMPNAME" = 1 ]; then
    			wr "Error: No computer hostname provided."
    			writelog "You must specify a name for the machine - ex. ./${PROGRAM} -c <compname>"
				exit 11
			elif [[ "$COMPNAME" == -* ]] && [ "$REQUIRE_COMPNAME" != 1 ]; then
				writelog "Error: While you have made setting a computer hostname not \
				required, you have not provided a computer hostname"
				exit 12
			fi
    		writelog "Will set computer hostname to ${COMPNAME} ..."
    		shift
      		;;
    	--keepjamflog | -k)
    		KEEPJAMFLOG=1
    		writelog "Will attempt to copy jamf.log from machine ..."
      		;;
      	--timestamps | -t)
      		TIMESTAMPS=1
      		writelog "Will write timestamps for OS image restore to ${PLIST} ..."
      		;;
      	--force-hfs | -f)
			FORCE_HFS=1
			writelog "Will use HFS image instead of APFS image ..."
			;;
      	*)
      		writelog "Unknown command / parameter '${1}'"
      		exit 13
      		;;
    esac
    shift 1
done

# Verify running script as root
verify_root

# Verify OS image file exists at defined path
verify_os_images

# Assess storage hardware type
assess_storage_type

# Only if using --reusecompname: Verify $COMPNAME_FILE exists and $COMPNAME is not empty
if [ "$REUSE_COMPNAME" = 1 ]; then
	check_compname
fi

# Verify an external disk is detected and a volume is mounted
verify_ext_disk

####### SCRIPT
			
##### Step 1 - Copy jamf.log off machine before erase, if desired (if it exists)

# Only if using --keepjamflog
if [ "$KEEPJAMFLOG" = 1 ]; then
	jamf_log_copy
fi

##### Step 2 - Restore

os_image_restore

##### Step 3 - Maybe write some things to external disk

# Need to fully unmount APFS disk and remount to potentially do other things
if [ "$FILESYSTEM" = "APFS" ]; then
 	unmount_disk
 	apfs_mount_post_restore
fi

# Only if using --keepjamflog: write jamf.log back
if [ "$KEEPJAMFLOG" = 1 ]; then
	jamf_log_copyback
fi

# Only if using --timestamps: write start & end restore timestamps to $PLIST
if [ "$TIMESTAMPS" = 1 ]; then
	write_restore_timestamps
fi

##### Step 4 - Maybe write computer hostname file & Unmount
if [ "$REQUIRE_COMPNAME" = 1 ]; then
	write_compname_txt
fi

if [ "$FUSION_DRIVE" = "Yes" ]; then
	# Wait a bit for the Fusion Drive before unmounting
	/bin/sleep 5
	unmount_disk
else
	unmount_disk
fi

##### DONE

restore_done

exit