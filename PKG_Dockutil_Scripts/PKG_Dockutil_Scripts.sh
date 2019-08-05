#!/bin/bash

#####################################################
# Assumptions:
#
# 1) You deploy dockutil (https://github.com/kcrawford/dockutil) in your environment
#
# 2) You deploy outset (https://github.com/chilcote/outset) in your environment
#
# Requirements to run script:
#
# 1) A folder containing all of your dockutil scripts
#
# 2) A variable - PKG_BUILD_PREF - in each of your dockutil scripts which contains one
# of the following values to determine the outset directory structure to build the script
# into:
#
#     boot-once
#     boot-every
#     login-once
#     login-every
#     login-priv-once
#     login-priv-every
#     on-demand
#
#     ex. PKG_BUILD_PREF=login-once
#
# What this script does:
#
# Quickly builds individual PKGs for each of your dockutil scripts so you don't have to
# do this manually.  We deploy several different docks to machines and while a few 
# applications get added or removed each year, packaging each one individually is
# time-consuming and prone to errors.
#
# Written (poorly) in bash by AP Orlebeke - 4/4/17
#
#####################################################

# Present dialog window and prompt user to navigate to a folder with contained dockutil scripts
REPO_DIR=$(osascript -e 'try
tell application "SystemUIServer"
   choose folder with prompt "Where are your dockutil scripts?"
  set folderPath to POSIX path of result
end
end')
# Should be updated for each build / year
VERSION="2019"
# Cert must be installed in keychain
CERT="Developer ID Installer: The Masters School (4JKASQ9RJ4)"
ORG="org.mastersny"
# For specifiying the file extension of your dockutil scripts
SCRIPT_FILE_EXT=".sh"
SCRIPT_LIST=$(ls -1 "$REPO_DIR" | grep $SCRIPT_FILE_EXT)
# By default creates log file in previously selected folder
LOG="${REPO_DIR}/0_PKG_Build.log"

############ OUTSET DIRECTORY STRUCTURE TEMPLATES ############

OUTSET_DIR="/usr/local/outset"
BOOT_ONCE="${OUTSET_DIR}/boot-once"
BOOT_EVERY="${OUTSET_DIR}/boot-every"
LOGIN_ONCE="${OUTSET_DIR}/login-once"
LOGIN_EVERY="${OUTSET_DIR}/login-every"
LOGIN_PRIV_ONCE="${OUTSET_DIR}/login-privileged-once"
LOGIN_PRIV_EVERY="${OUTSET_DIR}/login-privileged-every"
ON_DEMAND="${OUTSET_DIR}/on-demand"

############ FUNCTIONS ############

writelog () {
	/bin/echo "${1}"
	/bin/echo $(date) "${1}" >> "$LOG"
}

mkdir_boot_once () {
	mkdir -p "${REPO_DIR}"/"${NAME}"/"${BOOT_ONCE}"
}

mkdir_boot_every () {
	mkdir -p "${REPO_DIR}"/"${NAME}"/"${BOOT_EVERY}"
}

mkdir_login_once () {
	mkdir -p "${REPO_DIR}"/"${NAME}"/"${LOGIN_ONCE}"
}

mkdir_login_every () {
	mkdir -p "${REPO_DIR}"/"${NAME}"/"${LOGIN_EVERY}"
}

mkdir_login_priv_once () {
	mkdir -p "${REPO_DIR}"/"${NAME}"/"${LOGIN_PRIV_ONCE}"
}

mkdir_login_priv_every () {
	mkdir -p "${REPO_DIR}"/"${NAME}"/"${LOGIN_PRIV_EVERY}"
}

mkdir_on_demand () {
	mkdir -p "${REPO_DIR}"/"${NAME}"/"${ON_DEMAND}"
}

mkdir_error_check () {
	if [ -d "${REPO_DIR}/${NAME}/${OUTSET_DIR}/${BUILD_PREF}" ]; then
		writelog "DIR BUILD: Successfully created outset ${BUILD_PREF} directory structure for ${SCRIPT}."
	else
		writelog "DIR BUILD: Failed to create outset ${BUILD_PREF} directory structure for ${SCRIPT}."
		exit 1
	fi
}

cp_script () {
	cp "${REPO_DIR}"/"${SCRIPT}" "${REPO_DIR}""${NAME}""${OUTSET_DIR}"/"${BUILD_PREF}"/
}

cp_error_check () {
	if [ -f "${REPO_DIR}${NAME}/${OUTSET_DIR}/${BUILD_PREF}/${SCRIPT}" ]; then
		writelog "SCRIPT: Successfully copied ${SCRIPT} to outset ${BUILD_PREF} directory structure."
	else
		writelog "SCRIPT: Failed to copy ${SCRIPT} to outset ${BUILD_PREF} directory structure."
		exit 1
	fi
}

chmod_script () {
	chmod 755 "${REPO_DIR}""${NAME}""${OUTSET_DIR}"/"${BUILD_PREF}"/"${SCRIPT}"
}

build_pkg () {
	pkgbuild --root "${REPO_DIR}""${NAME}" --identifier "${ORG}"."${NAME}" --version "$VERSION" --sign "$CERT" "${REPO_DIR}""${NAME}".pkg
}

build_cleanup () {
	rm -rf "${REPO_DIR}""${NAME}"
}

build_error_check () {
	if [ $? = 0 ]; then
		writelog "PKG BUILD: Successfully built ${NAME}.pkg!"
		
		# Cleanup directories created for package building
		build_cleanup
		
		if [ $? = 0 ]; then
			writelog "CLEANUP: Package build cleanup successful!"
		else
			writelog "CLEANUP: Package build cleanup failed."
		fi
	else
		writelog "PKG BUILD: Failed to build ${NAME}.pkg."
	fi
}

############ RUN SCRIPT ############

for SCRIPT in $SCRIPT_LIST ; do
	BUILD_PREF=$(cat "${REPO_DIR}"/"${SCRIPT}" | grep PKG_BUILD_PREF | sed 's/PKG_BUILD_PREF\=//')
	NAME=$(echo $SCRIPT | sed 's/.sh//')

	if [ "$BUILD_PREF" = "" ]; then
		writelog "SCRIPT ERROR: No PKG_BUILD_PREF variable found in ${SCRIPT}. "
				
	elif [ "$BUILD_PREF" = "boot-once" ]; then
		mkdir_boot_once
		mkdir_error_check
		
		cp_script
		cp_error_check
		
		chmod_script
		
		build_pkg
		build_error_check
		
	elif [ "$BUILD_PREF" = "boot-every" ]; then
		mkdir_boot_every
		mkdir_error_check
		
		cp_script
		cp_error_check
		
		chmod_script
		
		build_pkg
		build_error_check
		
	elif [ "$BUILD_PREF" = "login-once" ]; then
		mkdir_login_once
		mkdir_error_check
		
		cp_script
		cp_error_check
		
		chmod_script
		
		build_pkg
		build_error_check
		
	elif [ "$BUILD_PREF" = "login-every" ]; then
		mkdir_login_every
		mkdir_error_check
		
		cp_script
		cp_error_check
		
		chmod_script
		
		build_pkg
		build_error_check
		
	elif [ "$BUILD_PREF" = "login-priv-once" ]; then
		mkdir_login_priv_once
		mkdir_error_check
		
		cp_script
		cp_error_check
		
		chmod_script
		
		build_pkg
		build_error_check
		
	elif [ "$BUILD_PREF" = "login-priv-every" ]; then
		mkdir_login_priv_every
		mkdir_error_check
		
		cp_script
		cp_error_check
		
		chmod_script
		
		build_pkg
		build_error_check
		
	elif [ "$BUILD_PREF" = "on-demand" ]; then
		mkdir_on_demand
		mkdir_error_check
		
		cp_script
		cp_error_check
		
		chmod_script
		
		build_pkg
		build_error_check
		
	else
		writelog "SCRIPT ERROR: One of the following has occurred processing ${SCRIPT}:"
		writelog "1) An unrecognized PKG_BUILD_PREF value"
		writelog "2) Some other error"
		writelog "Check your script and try again."
	fi
done

exit
