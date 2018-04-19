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
LAST_UPDATE_DATE="4/19/18"

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
"4: --dry-run: OS restore imagescan failed"
"5: Filesystem unable to be determined on external machine"
"6: Filesystem restore failed"
"7: Script not run as 'root'"
"8: --force-hfs: Specified HFS image at OS_IMAGE_PATH (${OS_IMAGE_PATH}) does not exist"
"9: One or more missing OS image files from OS_IMAGE_PATH (${OS_IMAGE_PATH})"
"10: No external machine connected"
"11: No external machine volume mounted"
"12: Failed to write ${COMPNAME_FILE} file with computer hostname"
"13: --compname / -c: No computer hostname defined; REQUIRE_COMPNAME set to required"
"14: --compname / -c: No computer hostname defined; REQUIRE_COMPNAME set to not required"
"15: --log-path: No log path defined"
"16: Specified --log-path directory does not exist"
"17: Unknown argument passed to script"
"18: Unmount of external disk failed")

EXITCODE_HELP_ARRAY=("" # Dummy first line
"Please use --compname / -c instead" #1
"Please use --compname / -c instead" #2
"Please run again without --keepjamflog" #3
"" #4
"None .... sorry  ¯\_(ツ)_/¯" #5
"Please try again. If failures continue, you may have an issue with one of your OS image files" #6
"Please run again with 'sudo'" #7
"Verify your OS_IMAGE_PATH and HFS_OS_IMAGE variables are correct." #8
"Verify your APFS_OS_IMAGE and HFS_OS_IMAGE variables are correct" #9
"Please connect or reconnect your Target Disk Mode machine" #10
"Please connect or reconnect your Target Disk Mode machine" # 11
"Please try running again" #12
"Please supply a computer hostname: ex. --compname <compname> OR make REQUIRE_COMPNAME set to 0" #13
"Please either set REQUIRE_COMPNAME to 1 and provide a desired computer name, or remove your --compname argument" #14
"Please specify a path to an existing directory" #15
"Please specify a path to an existing directory" #16
"Please remove the unknown argument" #17
"None .... sorry  ¯\_(ツ)_/¯") #18

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
  --dry-run, -d		Run through script workflow to test output & results. Performs
  			ASR imagescan to verify your OS image is OK for restore.
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
  --log-path, -l	Specify an alternate path than the default set in the script.
  --no-imagescan	For use with --dry-run, will not perform an asr imagescan on
  			the applicable OS_IMAGE file."
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

function apfs_mount() {
	writelog "Mounting ${EXT_VOLUME} ..."
	
	# Mount to /Volumes/Macintosh HD 1
	/bin/mkdir "$EXT_VOLUME"
	/sbin/mount_apfs /dev/${EXT_DISK_DEVICENODE} "$EXT_VOLUME"
}

function mount_ext_disk() {
	# Mount disk partition
	/usr/sbin/diskutil mountDisk ${EXT_DISK_DEVICENODE}
}

function apfs_ssd_vars() {
	FS="APFS"
	OS_IMAGE="$APFS_OS_IMAGE"
	STORAGE_TYPE="an SSD"
}

function hfs_ssd_vars() {
	FS="HFS"
	OS_IMAGE="$HFS_OS_IMAGE"
	STORAGE_TYPE="an SSD"
}

function hfs_fusion_vars() {
	FS="HFS"
	OS_IMAGE="$HFS_OS_IMAGE"
	STORAGE_TYPE="a Fusion Drive"
}

function hfs_hdd_vars() {
	FS="HFS"
	OS_IMAGE="$HFS_OS_IMAGE"
	STORAGE_TYPE="an HDD"
}

function ext_disk_info() {
	EXT_DISK_DEVICEID=$(/usr/sbin/diskutil list external | /usr/bin/awk '/0:/{print $NF}' | /usr/bin/tail -1)
}

function assess_storage_type() {
	ext_disk_info
	FUSION_DRIVE=$(/usr/sbin/diskutil info ${EXT_DISK_DEVICEID} | /usr/bin/awk '/Fusion Drive/{print $NF}')
	
	if [ "$EXT_DISK_DEVICEID" != "" ]; then
		if [ "$FUSION_DRIVE" = "Yes" ]; then
			# Fusion Drive
			EXT_DISK_DEVICENODE="$EXT_DISK_DEVICEID"
			
		else
			SSD=$(/usr/sbin/diskutil info ${EXT_DISK_DEVICEID} | /usr/bin/grep "SSD")
			EXT_DISK_ID=$(/bin/ls -1 /dev | /usr/bin/grep "^${EXT_DISK_DEVICEID}" | /usr/bin/tail -1)
			EXT_DISK_FS=$(/usr/sbin/diskutil info ${EXT_DISK_ID} | /usr/bin/awk '/Type \(Bundle\)/{print $NF}')
			if [ "$SSD" != "" ]; then
				# If SSD is formated for APFS ...
				if [ "$EXT_DISK_FS" = "apfs" ]; then
					EXT_DISK_DEVICENODE="${EXT_DISK_DEVICEID}s1"
					if [ "$FORCE_HFS" = 1 ]; then
						# SSD & HFS
						hfs_ssd_vars
					else
						# SSD & APFS
						apfs_ssd_vars
					fi
				elif [ "$EXT_DISK_FS" = "hfs" ]; then
					EXT_DISK_DEVICENODE="${EXT_DISK_DEVICEID}s2"
					if [ "$FORCE_HFS" = 1 ]; then
						# SSD & HFS
						hfs_ssd_vars
					else
						# SSD & APFS
						apfs_ssd_vars
					fi
				fi
			else
				# HDD
				EXT_DISK_DEVICENODE="${EXT_DISK_DEVICEID}s2"
				hfs_hdd_vars
			fi
		fi
	
		# Print hardware storage info
		writelog "External storage type is ${STORAGE_TYPE}. Format: ${EXT_DISK_FS}."
		writelog "Will use ${FS} filesystem for OS restore ..."
		
		# Get volume info
		volume_path_info
	fi
}

function check_compname() {
	if [ -f "${EXT_VOLUME}/${COMPNAME_FILE}" ]; then
		COMPNAME=$(/bin/cat "${EXT_VOLUME}/${COMPNAME_FILE}")
		writelog "${COMPNAME_FILE} file detected ..."
		if [ "$COMPNAME" != "" ]; then
			writelog "Will set computer hostname to ${COMPNAME} ..."
		else
			errorcode=1
			print_exitcode
		fi
	else
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
		writelog "Found jamf.log on external machine. Copying ..."
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
	
	# Erase & Restore w/ no prompt
	if [ "$FS" != "" ]; then
		# If dry-run enabled, run an imagescan on the OS image
		if [ "$DRY_RUN" = 1 ]; then
			writelog "Dry-run: OS image restore"
			if [ "$IMAGESCAN" = 0 ]; then
				writelog "Dry-run: Will not perform asr imagescan ..."
				exitcode=0
			else		
				writelog "Dry-run: Performing asr imagescan ..."
				# Perform ASR imagescan
				/usr/sbin/asr imagescan --source "${OS_IMAGE_PATH}/${OS_IMAGE}"
				exitcode=$(/bin/echo $?)
			fi
		else
			writelog "Beginning erase & restore ..."
			writelog "Restoring $OS_IMAGE ..."
			# Fully unmount HFS disk
			if [ "$EXT_DISK_FS" = "hfs" ]; then
				writelog "Unmounting external disk ..."
				unmount_disk
			fi
			# Restore
			if [ "$EXT_DISK_FS" = "APFS" ]; then
				/usr/sbin/asr restore --source "${OS_IMAGE_PATH}/${OS_IMAGE}" --target /dev/${EXT_DISK_DEVICEID} --erase --noprompt
				exitcode=$(/bin/echo $?)
			else
				/usr/sbin/asr restore --source "${OS_IMAGE_PATH}/${OS_IMAGE}" --target /dev/${EXT_DISK_DEVICENODE} --erase --noprompt
				exitcode=$(/bin/echo $?)
			fi
		fi
	else
		errorcode=4
		print_exitcode
	fi

	# Error check
	if [ "$DRY_RUN" = 1 ] && [ "$IMAGESCAN" != 0 ]; then
		if [ "$exitcode" != 0 ]; then
			errorcode=4
			print_exitcode
		else
			# Get OS imagescan end timestamp
			restore_end_time
			echo "${TEXT_GREEN}${RESTORE_END}${TEXT_NORMAL}"
		fi
	elif [ "$DRY_RUN" != 1 ]; then
		if [ "$exitcode" != 0 ]; then
			echo "${TEXT_RED}Failed to Restore. Exiting ...${TEXT_NORMAL}"
			errorcode=5
			print_exitcode
		else
			# Get OS restore end timestamp
			restore_end_time
			echo "${TEXT_GREEN}${RESTORE_END}${TEXT_NORMAL}"
		fi
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

function volume_path_info() {
	VOLUMEPATH=$(/usr/sbin/diskutil info ${EXT_DISK_DEVICENODE} | /usr/bin/grep "Mount Point" | /usr/bin/sed 's/^[^/]*//')
	EXT_VOLUME="$VOLUMEPATH"
}

function restore_done() {
	if [ "$DRY_RUN" = 1 ]; then
		writelog ""
		writelog "Dry run complete."

		# State completion
		/usr/bin/say "Dry run complete."
	else
		writelog ""
		writelog "DONE! Safe to unplug external machine."

		# State completion
		/usr/bin/say "OS restore complete. Please disconnect."
	fi
}

function unmount_disk() {
	/usr/sbin/diskutil unmountDisk /dev/${EXT_DISK_DEVICEID}
	unmountstatus=$(/bin/echo $?)
	
	if [ "$unmountstatus" != 0 ]; then
		errorcode=18
		print_exitcode
	fi
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
		errorcode=7
		print_exitcode
	fi
}

function verify_os_images() {
	if [ "$FORCE_HFS" = 1 ]; then
		if [ ! -f "${OS_IMAGE_PATH}/${HFS_OS_IMAGE}" ]; then
			errorcode=8
			print_exitcode
		fi
	elif [ ! -f "${OS_IMAGE_PATH}/${APFS_OS_IMAGE}" ] || [ ! -f "${OS_IMAGE_PATH}/${HFS_OS_IMAGE}" ]; then
		errorcode=9
		print_exitcode
	fi
}

function verify_ext_disk() {
	if [ "$EXT_DISK_DEVICEID" = "" ]; then
		errorcode=10
		print_exitcode
	elif [ ! -d "$EXT_VOLUME" ]; then
		errorcode=11
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
	# Write file
	if [ "$DRY_RUN" = 1 ]; then
		writelog "Dry-run: Write ${EXT_VOLUME}${COMPNAME_FILE}"
	else
		writelog "Writing ${COMPNAME} to ${COMPNAME_FILE} ..."
		/bin/echo "$COMPNAME" > "${EXT_VOLUME}${COMPNAME_FILE}"
	fi

	if [ "$DRY_RUN" = 1 ]; then
		writelog "Dry-run: Successful write of ${COMPNAME_FILE}!"
	elif [ -f "${EXT_VOLUME}${COMPNAME_FILE}" ]; then
		writelog "Successfully wrote ${COMPNAME_FILE}!"
	else
		errorcode=12
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
		--no-imagescan)
			IMAGESCAN=0
			;;
      	--reusecompname)
    		REUSE_COMPNAME=1
    		;;
    	--compname | -c)
    		COMPNAME="$2"
    		if [[ "$COMPNAME" == -* ]] && [ "$REQUIRE_COMPNAME" = 1 ]; then
				errorcode=13
				print_exitcode
			elif [ "$COMPNAME" = "" ] && [ "$REQUIRE_COMPNAME" = 1 ]; then
				errorcode=13
				print_exitcode
			elif [[ "$COMPNAME" == -* ]] && [ "$REQUIRE_COMPNAME" != 1 ]; then
				errorcode=14
				print_exitcode
			elif [ "$COMPNAME" = "" ] && [ "$REQUIRE_COMPNAME" != 1 ]; then
				errorcode=14
				print_exitcode
			fi
    		writelog "Will set computer hostname to ${COMPNAME} ..."
    		shift
      		;;
      	--log-path | -l)
			LOGPATH="$2"
			if [ "$LOGPATH" = "" ] || [[ "$LOGPATH" == -* ]]; then
				errorcode=15
				print_exitcode
			elif [ ! -d "$LOGPATH" ]; then
				errorcode=16
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
if [ "$FS" = "APFS" ]; then
	# If external disk was previously hfs, override HFS devicenode with APFS one
 	if [ "$EXT_DISK_FS" = "hfs" ]; then
 		unmount_disk
 		EXT_DISK_DEVICENODE="disk3s1"
		apfs_mount
 	else
		unmount_disk
		apfs_mount
 	fi
else
	mount_ext_disk
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
elif [ "$DRY_RUN" = 1 ]; then
	writelog "Dry-run: Will not unmount external machine"
else
	unmount_disk
fi

##### DONE
# Announce completion
restore_done

exit