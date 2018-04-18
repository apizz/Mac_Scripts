#!/bin/bash

# Never-booted OS images
OS_IMAGE_PATH="/Users/admin/Downloads"
APFS_OS_IMAGE="osx_updated_180402-10.13.4-17E199.apfs.dmg"
HFS_OS_IMAGE="osx_updated_180402-10.13.4-17E199.hfs.dmg"

# Date & timestamp format for use with LOG
# Format: YYMMDD
LOGDATE=$(/bin/date "+%y%m%d")
# Log folder
LOGPATH="/Users/${USER}/Desktop/OS_RESTORE_LOGS"

# Compname variables
# Computer hostname required (true)
REQUIRE_COMPNAME=1
# Computer hostname not required (false)
#REQUIRE_COMPNAME=0
# Path to write computer hostname file for later MDM collection
COMPNAME_FILE="/Library/Receipts/CompName.txt"

# Plist to write OS restore start and end timestamps to: for use with --timestamps / -t
PLIST="/Library/Receipts/OSRestore.plist"

######## DO NOT EDIT BELOW THIS LINE ########

# User variables
ROOT=$(/usr/bin/whoami)
USER=$(/bin/ls -l /dev/console | /usr/bin/awk '{print $3}')

# Program Info
NAME="HighSierraOSRestore"
PROGRAM="${NAME}.sh"
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

EXITCODE_ARRAY=("" # Dummy first line to align array index to corresponding error code number
"1: --reusecompname: No computer hostname found in ${COMPNAME_FILE}"
"2: --reusecompname: No ${COMPNAME_FILE} found on external machine"
"3: --keepjamflog: No jamf.log file found on external machine"
"4: Filesystem unable to be determined on external machine"
"5: Filesystem restore failed"
"6: Script not run as 'root'"
"7: --force-hfs: Specified HFS image at OS_IMAGE_PATH (${OS_IMAGE_PATH}) does not exist"
"8: One or more missing OS image files from OS_IMAGE_PATH (${OS_IMAGE_PATH})"
"9: No external machine connected"
"10: No external machine volume mounted"
"11: Failed to write ${COMPNAME_FILE} file with computer hostname"
"12: --compname / -c: No computer hostname defined; REQUIRE_COMPNAME set to required"
"13: --compname / -c: No computer hostname defined; REQUIRE_COMPNAME set to not required"
"14: --log-path: No log path defined"
"15: Specified --log-path directory does not exist"
"16: No arguments passed to script"
"17: Unknown argument passed to script")

EXITCODE_HELP_ARRAY=("" # Dummy first line
"Please use --compname / -c instead" #1
"Please use --compname / -c instead" #2
"Please run again without --keepjamflog" #3
"None .... sorry  ¯\_(ツ)_/¯" #4
"Please try again. If failures continue, you may have an issue with one of your OS image files" #5
"Please run again with 'sudo'" #6
"Verify your OS_IMAGE_PATH and HFS_OS_IMAGE variables are correct." #7
"Verify your APFS_OS_IMAGE and HFS_OS_IMAGE variables are correct" #8
"Please connect or reconnect your Target Disk Mode machine" #9
"Please connect or reconnect your Target Disk Mode machine" # 10
"Please try running again" #11
"Please supply a computer hostname: ex. --compname <compname> OR make REQUIRE_COMPNAME set to 0" #12
"Please either set REQUIRE_COMPNAME to 1 and provide a desired computer name, or remove your --compname argument" #13
"Please specify a path to an existing directory" #14
"Please specify a path to an existing directory" #15
"Please provide an argument, or use --dry-run to test" #16
"Please remove the unknown argument") #17

##### FUNCTIONS

function writelog() {
	echo "${1}"
	echo $(/bin/date "+%Y-%m-%d %H:%M:%S") "${1}" >> "$LOG"
}

function showhelp() {
	/bin/echo "Usage:  sudo ./${PROGRAM} [--help] [--version] [--exitcodes] 
			[--dry-run] [--force-hfs] [--compname <compname>]
			[--reusecompname] [--timestamps] [--keepjamflog]
			[--log-path <pathtologfolder>]

Arguments:
  --help, -h		Show this help message.
  --version, -v		Show version info.
  --exitcodes, -e	Show the exit code error list.
  --dry-run, -d		Run through script workflow to test output & results.
  --force-hfs, -f	For opting to use an HFS OS image over an APFS image on SSDs.



Optional Arguments:
  --compname, -c	Provide computer hostname for use as part of MDM enrollment
  			and computer renaming.
  --reusecompname	Will attempt to use previous compname at COMPNAME_FILE
  			(${COMPNAME_FILE}), if it exists.
  --timestamps, -t	Write timestamps before and after OS image restore to external
  			machine PLIST (${PLIST}) for use as part
  			of enrollment or larger deployment calculation.	
  --keepjamflog, -k	Will copy the jamf log off the external machine (if it exists) to
  			${LOGPATH} folder and copy it back after
  			the restore.
  --log-path, -l	Specify an alternate path than the default set in the script."
}

function version() {
	echo "${TEXT_BLUE}${PROGRAM}: Written by ${AUTHOR} - version ${VERSION}.${TEXT_NORMAL}"
	echo "${TEXT_BLUE}Available on ${GITHUB}${TEXT_NORMAL}"
	echo "${TEXT_BLUE}Last updated on ${LAST_UPDATE_DATE}${TEXT_NORMAL}"
}

function exit_codes() {
	/bin/echo "Exit Codes:"
	/usr/bin/printf '%s\n' "${EXITCODE_ARRAY[@]}"
}

# Not currently implemented
function exit_codes_help() {
	/bin/echo "Exit Codes:"
	/usr/bin/printf '%s\n' "${EXITCODE_ARRAY[@]}"
	/bin/echo "Recommendations:"
	/usr/bin/printf '%s\n' "${EXITCODE_HELP_ARRAY[@]}"
}

function print_exitcode() {
	EXITRESULT=$(/usr/bin/printf '%s\n' "${EXITCODE_ARRAY[$errorcode]}")
	EXITHELP=$(/usr/bin/printf '%s\n' "${EXITCODE_HELP_ARRAY[$errorcode]}")
	writelog "Error Code:  $EXITRESULT"
	writelog "Recommendation:  $EXITHELP"
	exit $errorcode
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
		EXT_DISK_ID=$(/bin/ls -1 /dev | /usr/bin/grep "^${EXT_DISK_DEVICEID}" | /usr/bin/tail -1)
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
			errorcode=1
			print_exitcode
		fi
	else
		writelog "Could not find ${COMPNAME_FILE} file on external machine."
		writelog "Please specify a computer hostname with --compname / -c <compname>"
		errorcode=2
		print_exitcode
	fi
}

function jamf_log_copy() {
	# JAMF variables: for use with --keepjamflog / -k
	JAMFLOG="/var/log/jamf.log"
	TMP_JAMFLOG="${LOGPATH}/jamf.log"

	# If jamf.log file exists, copy it off before restoring
	if [ -f "${EXT_VOLUME}${JAMFLOG}" ]; then
		writelog "Found jamf.log on external machine."
		writelog "Copying ..."
		# Dry-run
		if [ "$DRY_RUN" = 1 ]; then
			writelog "Dry-run: jamf.log copy"
		else
			# Copy
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
		errorcode=3
		print_exitcode
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

function make_log() {
	# Make LOGPATH if it doesn't exist
	if [ ! -d "$LOGPATH" ]; then
		/bin/mkdir -p "${LOGPATH}"
	fi
	# Set default LOG destination if it doesn't exist
	if [ "$LOG" = "" ]; then
		LOG="${LOGPATH}/${NAME}-${LOGDATE}.log"
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
		errorcode=4
		print_exitcode
	fi

	# Error check
	if [ "$exitcode" != 0 ]; then
		echo "${TEXT_RED}Failed to Restore. Exiting ...${TEXT_NORMAL}"
		errorcode=5
		print_exitcode
	else
		# Get OS restore end timestamp
		restore_end_time
		echo "${TEXT_GREEN}${RESTORE_END}${TEXT_NORMAL}"
	fi
}

function restore_start_time() {
	# Use UTC to account for timezone variance
	RESTORE_START=$(/bin/date -u "+%Y-%m-%d %H:%M:%S")
}

function restore_end_time() {
	# Use UTC to account for timezone variance
	RESTORE_END=$(/bin/date -u "+%Y-%m-%d %H:%M:%S")
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
		errorcode=6
		print_exitcode
	fi
}

function verify_os_images() {
	if [ "$FORCE_HFS" = 1 ]; then
		if [ ! -f "${OS_IMAGE_PATH}/${HFS_OS_IMAGE}" ]; then
			errorcode=7
			print_exitcode
		fi
	elif [ ! -f "${OS_IMAGE_PATH}/${APFS_OS_IMAGE}" ] || [ ! -f "${OS_IMAGE_PATH}/${HFS_OS_IMAGE}" ]; then
		errorcode=8
		print_exitcode
	fi
}

function verify_ext_disk() {
	if [ "$EXT_DISK_DEVICEID" = "" ]; then
		writelog "No external disk detected. Disconnect and reconnect the external computer."
		writelog "Exiting ..."
		errorcode=9
		print_exitcode
	elif [ ! -d "$EXT_VOLUME" ]; then
		writelog "No mounted external disk volume detected. Disconnect and reconnect the external computer."
		writelog "Exiting ..."
		errorcode=10
		print_exitcode
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
		errorcode=11
		print_exitcode
	fi
}

######## CHECKS & SCRIPT ########

# Make LOGPATH if it doesn't exist
make_log

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
    			writelog "Error: No computer hostname provided."
    			writelog "You must specify a name for the machine - ex. ./${PROGRAM} -c <compname>"
				errorcode=12
				print_exitcode
			elif [[ "$COMPNAME" == -* ]] && [ "$REQUIRE_COMPNAME" != 1 ]; then
				writelog "Error: While you have made setting a computer hostname not \
				required, you have not provided a computer hostname"
				errorcode=13
				print_exitcode
			fi
    		writelog "Will set computer hostname to ${COMPNAME} ..."
    		shift
      		;;
      	--log-path | -l)
			LOGPATH="$2"
			if [ "$LOGPATH" = "" ] || [[ "$LOGPATH" == -* ]]; then
				writelog "Error: no directory specified for --log-path"
				errorcode=14
				print_exitcode
			elif [ ! -d "$LOGPATH" ]; then
				writelog "Error: specified --log-path does not exist."
				errorcode=15
				print_exitcode
			fi
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
      		writelog "Unknown argument provided '${1}'"
      		errorcode=17
      		print_exitcode
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

# Unmount
if [ "$FUSION_DRIVE" = "Yes" ]; then
	# Wait a bit for the Fusion Drive before unmounting
	/bin/sleep 5
	unmount_disk
else
	unmount_disk
fi

##### DONE
# Announce completion
restore_done

exit