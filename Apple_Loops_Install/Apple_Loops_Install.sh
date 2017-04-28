#!/bin/sh 

# Script assumes the following:
#
# 1) You're running this script from the command line
#
# 2) You've used the appleLoops.py script to download your Apple loops.
#    https://github.com/carlashley/appleLoops
#
# 3) You have copied the resulting garageband, logicpro, and/or mainstage folders
#    to a mounted volume (USB flash drive, or network volume) and specified this path
#    in the DIRNAME variable.
#
# NOTE: You do NOT need to have all 3 applications. The script checks to see if these
#       applications are already installed, and if not they are skipped.
#
# 4) You have specified a log file for the script to write the Apple loop install statuses
#    and check for duplicates.
#
# NOTE: If you want this log file in the root Library folder, you'll need to run the script
#       with sudo.
#
#
# USAGE:
#
# 1) Run (sudo) /path/to/Install_Apple_Loops.sh
#
# 2) At each prompt, type A(a) to choose to install all loops for the application, or R(r)
#    for only those that are required (apps not installed are skipped). If you have
#    previously installed the loops for the app, type S(s) to skip those loops.
#
# 3) Once all possible choices are made, type y(es) to install the chosen Apple loops.
#    At this point you can also navigate to your PKG_INSTALL_MANIFEST directory to review
#    exactly what's going to be installed.
#
#    Alternatively, you can type n(o) to not install anything and exit the script.
#
# 4) Walk a way while it runs.
#
#
# No warranties.  I wrote this script for me, but you are happy to use it if it helps!
#
# Written by AP Orlebeke - 4/27/17
#

############ VARIABLES TO SET ############

# Path to your garageband, logicpro, and/or mainstage directories - no trailing /
DIRNAME="/path/to/folder"
# Log for writing install statuses and checking for already installed PKGs
LOG="/path/to/AppleLoopsInstall.log"
# Path to package manifest for double-checking what will be installed before installing -
# no trailing /
PKG_INSTALL_MANIFEST="/path/to/desired/folder"

############ VARIABLES ############

GB="/Applications/GarageBand.app"
GB_PATH="${DIRNAME}/garageband*"
LP="/Applications/Logic Pro X.app"
LP_PATH="${DIRNAME}/logicpro*"
MS="/Applications/MainStage 3.app"
MS_PATH="${DIRNAME}/mainstage*"
COMPILED_PKG_LIST=()
# Function to write to your log file with custom date format that the JSS likes
writelog () {
	/bin/echo "${1}"
	/bin/echo $(date "+%Y-%m-%d %H:%M:%S") "${1}" >> "$LOG"
}

############ LOG ############

# Removes log if it already exists
if [ -f "$LOG" ]; then
	rm "$LOG"
fi

############ PROMPTS ############

# If GarageBand is installed, prompt user about installing all, or required only
if [ -d "$GB" ]; then
	GB_REQ_PKGS=$(find $GB_PATH/*/mandatory* -type f -name *.pkg)
	GB_ALL_PKGS=$(find $GB_PATH -type f -name *.pkg)

	/bin/echo
	/bin/echo "Which GarageBand Sound Loops would you like to install?"
	/bin/echo

	while true; do
		read -p "All, required, or skip? (A/a , R/r , S/s) " GB_RESPONSE
		case $GB_RESPONSE in
			[Aa])
				COMPILED_PKG_LIST+=($GB_ALL_PKGS)
				break
			;;
			[Rr])
				COMPILED_PKG_LIST+=($GB_REQ_PKGS)
				break
			;;
			[Ss])
				/bin/echo
				/bin/echo "OK. Skipping GarageBand."
				break
			;;
			*)
				/bin/echo
				/bin/echo "Invalid response."
				/bin/echo "Please enter A/a , R/r , or S/s ... "
				/bin/echo "Press Control + C to exit";;
		esac
	done
else
	/bin/echo
	/bin/echo "GarageBand Not Installed. Continuing ..."
	/bin/echo
fi

# If Logic Pro X is installed, prompt user about installing all, or required only
if [ -d "$LP" ]; then
	LP_REQ_PKGS=$(find $LP_PATH/*/mandatory* -type f -name *.pkg)
	LP_ALL_PKGS=$(find $LP_PATH -type f -name *.pkg)
	
	/bin/echo
	/bin/echo "Which Logic Pro X Sound Loops would you like to install?"
	/bin/echo

	while true; do
		read -p "All, required, or skip? (A/a , R/r , S/s) " LP_RESPONSE
		case $LP_RESPONSE in
			[Aa])
				COMPILED_PKG_LIST+=($LP_ALL_PKGS)
				break
			;;
			[Rr])
				COMPILED_PKG_LIST+=($LP_REQ_PKGS)
				break
			;;
			[Ss])
				/bin/echo
				/bin/echo "OK. Skipping Logic Pro X."
				break
			;;
			*)
				/bin/echo
				/bin/echo "Invalid response."
				/bin/echo "Please enter A/a , R/r , or S/s ... "
				/bin/echo "Press Control + C to exit";;
		esac
	done
else
	/bin/echo
	/bin/echo "Logic Pro X Not Installed. Continuing ..."
	/bin/echo
fi

# If MainStage 3 is installed, prompt user about installing all, or required only
if [ -d "$MS" ]; then
	MS_REQ_PKGS=$(find $MS_PATH/*/mandatory* -type f -name *.pkg)
	MS_ALL_PKGS=$(find $MS_PATH -type f -name *.pkg)
	
	/bin/echo
	/bin/echo "Which MainStage 3 Sound Loops would you like to install?"
	/bin/echo

	while true; do
		read -p "All, required, or skip? (A/a , R/r , S/s) " MS_RESPONSE
		case $MS_RESPONSE in
			[Aa])
				COMPILED_PKG_LIST+=($MS_ALL_PKGS)
				break
			;;
			[Rr])
				COMPILED_PKG_LIST+=($MS_REQ_PKGS)
				break
			;;
			[Ss])
				/bin/echo
				/bin/echo "OK. Skipping MainStage 3."
				break
			;;
			*)
				/bin/echo
				/bin/echo "Invalid response."
				/bin/echo "Please enter A/a , R/r , or S/s ... "
				/bin/echo "Press Control + C to exit";;
		esac
	done
else
	/bin/echo
	/bin/echo "MainStage 3 Not Installed. Continuing ..."
	/bin/echo
fi

# If none of the applications are installed, inform the user that no loops were installed
# and exit
if [ ! -d "$GB" ] && [ ! -d "$LP" ] && [ ! -d "$MS" ]; then
	echo "No Apple Sound Loops installed."
	exit
fi

# If all Apple loops have been skipped, inform the user that no loop were selected
# and exit
if [ "$COMPILED_PKG_LIST" = "" ]; then
	echo "No Apple Sound Loops chosen to be installed. Exiting."
	exit
fi

# Sort COMPILED_PKG_LIST array, write full list and deduped short list to manifests
PKG_INSTALL_LIST=$(/bin/echo ${COMPILED_PKG_LIST[@]} 2>&1 | tr ' ' '\n' | sort)
SHORTLIST=$(basename ${PKG_INSTALL_LIST[@]} | tr ' ' '\n' | sort | uniq > ${PKG_INSTALL_MANIFEST}/pkg_pruned_install_list.txt)
FULLLIST=$(/bin/echo ${PKG_INSTALL_LIST[@]} | tr ' ' '\n' | sort | uniq > ${PKG_INSTALL_MANIFEST}/pkg_full_install_list.txt)

# Inform user about PKG_INSTALL_MANIFEST
/bin/echo "Apple Loop install manifest written to ${PKG_INSTALL_MANIFEST} for your review ..."
/bin/echo

# Before installing chosen loops, prompt user to confirm the install.
while true; do
	read -p "Ready to install chosen Apple Sound Loops? " RESPONSE
	case $RESPONSE in
		[Yy] | [Yy][Ee][Ss])
			break
		;;
		[Nn] | [Nn][Oo])
			/bin/echo "OK. Exiting script."
			exit
		;;
		*)
			/bin/echo "Please answer y or n" ;;
	esac
done

############ INSTALL ############

writelog "Start of Apple Loop Installs"

IFS=$'\n'

for PKG in $PKG_INSTALL_LIST ;
do
	PKG_SHORT_NAME=$(basename $PKG)
	
	if [ "$(cat $LOG | grep $PKG_SHORT_NAME)" = "" ]; then
	
		writelog "Installing ${PKG_SHORT_NAME} ..."
	
		installer -pkg "$PKG" -target /
	
		if [ $? = 0 ]; then
			writelog "${PKG_SHORT_NAME} Install: Successful!"
		else
			writelog "${PKG_SHORT_NAME} Install: Failed."
		fi
	else
		writelog "${PKG_SHORT_NAME} already installed. Skipping ..."
	fi
done

unset $IFS

############ INSTALL VERIFICATION ############

if [ "$(cat $LOG | grep Failed)" = "" ]; then
	/bin/echo
	writelog "All Apple Loops installed successfully! Script complete."
else
	/bin/echo
	/bin/echo "Uh oh ... At least 1 install failed. Check your log file for details."
fi

exit