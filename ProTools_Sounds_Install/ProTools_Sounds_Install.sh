#!/bin/bash

## postinstall
#
# The following postinstall script is designed to be used with a combined PKG installer for installing all
# ProTools Plugins available from the Avid website.
#
# Must download all sound files from ProTools website, mount DMG files, and extract Install PKGs yourself to make
# your compiled PKG installer.
#
# See comments below for more details.
# 

downloaddir="/path/to/desired/download/directory"
airEffectdir="Name of Folder that contains AIR Effect install PKG"
airEffect="$airEffectdir/AvidSound_First_AIR_Effect_Bundle.pkg"
airInstrumentsdir="Name of Folder that contains AIR Instruments install PKG"
airInstruments="$airInstrumentsdir/AvidSound_First_AIR_Instruments_Bundle.pkg"
xpandIIdir="Name of Folder that contains XPandII install PKG"
xpandII="$xpandIIdir/AvidSound_XPand_II.pkg"

# Renamed all the plugin install PKGs that were self-contained installers to remove spaces.
protoolsPlugins=('AvidSound_BBD_Delay.pkg'
'AvidSound_Black_Op_Distortion.pkg'
'AvidSound_Black_Shiny_Wah.pkg'
'AvidSound_Black_Spring.pkg'
'AvidSound_C1_Chorus.pkg'
'AvidSound_DC_Distortion.pkg'
'AvidSound_Flanger.pkg'
'AvidSound_Gray_Compressor.pkg'
'AvidSound_Green_JRC_Overdrive.pkg'
'AvidSound_Orange_Phaser.pkg'
'AvidSound_Roto_Speaker.pkg'
'AvidSound_Space.pkg'
'AvidSound_Studio_Reverb.pkg'
'AvidSound_Tape_Echo.pkg'
'AvidSound_Tri-Knob_Fuzz.pkg'
'AvidSound_Vibe_Phaser.pkg'
'AvidSound_White_Boost.pkg')

# Goes through and installs each PKG. If install is successful, deletes the PKG and continues.
for ((i = 0; i < "${#protoolsPlugins[@]}"; i++))
do
	if [ -f "$downloaddir"/"${protoolsPlugins[$i]}" ]; then

		/bin/echo "${protoolsPlugins[$i]} found. Installing …"

		/usr/sbin/installer -pkg "$downloaddir"/"${protoolsPlugins[$i]}" -target /

		if [ $? = 0 ]; then
			/bin/echo "${protoolsPlugins[$i]} Install: Successful."

			/bin/rm -rf "$downloaddir"/"${protoolsPlugins[$i]}"

			if [ ! -f "$downloaddir"/"${protoolsPlugins[$i]}" ]; then
				/bin/echo "${protoolsPlugins[$i]} Deletion: Successful."
			else
				/bin/echo "${protoolsPlugins[$i]} Deletion: Failed."
			fi
		else
		/bin/echo "${protoolsPlugins[$i]} Install: Failed."
		/bin/echo "${protoolsPlugins[$i]} available for examination in ${downloaddir}."
		fi
	else
		/bin/echo "${protoolsPlugins[$i]} not found."
	fi
done

#
# There are two PKG installers that require extra work. Rather than put all the necessary files in the 
# PKG installer, the AIR Instruments Bundle and XPand II install PKGs rely on a hidden folder "Program Files 64".
# 
# Run `defaults write com.apple.finder AppleShowAllFiles` && `killall Finder` to show hidden files.
# Then copy both the install PKG and Program Files 64 folder from the downloaded DMG file
# into separate directories that contain the install PKG within the desired download directory.
#
# See the image in this repo to see the compiled plugin install PKG with Composer
#

if [ -f "$downloaddir/$airEffect" ]; then
	/bin/echo "Installing AIR Effect Bundle.pkg …"

	/usr/sbin/installer -pkg "$downloaddir/$airEffect" -target /

	if [ $? = 0 ]; then
		/bin/echo "AIR Effect Bundle Install Successful."

		/bin/rm -rf "$downloaddir"/"$airEffectdir"

		if [ ! -d "$downloaddir/$airEffectdir" ]; then
			/bin/echo "AIR Effect Bundle Deletion: Successful."
		else
			/bin/echo "AIR Effect Bundle Deletion: Failed."
		fi
	else
		/bin/echo "AIR Effect Bundle Install Failed."
	fi
else
	/bin/echo "AIR Effect Bundle not found."
fi

if [ -f "$downloaddir/$xpandII" ]; then
	/bin/echo "Installing XPand II.pkg …"

	/usr/sbin/installer -pkg "$downloaddir/$xpandII" -target /

	if [ $? = 0 ]; then
		/bin/echo "XPand II Install Successful."

		/bin/rm -rf "$downloaddir/$xpandIIdir"

		if [ ! -d "$downloaddir/$xpandIIdir" ]; then
			/bin/echo "XPand II Deletion: Successful."
		else
			/bin/echo "XPand II Deletion: Failed."
		fi
	else
		/bin/echo "XPand II Install Failed."
	fi
else
	/bin/echo "XPand II not found."
fi

if [ -f "$downloaddir/$airInstruments" ]; then
	/bin/echo "Installing AIR Instruments Bundle.pkg …"

	/usr/sbin/installer -pkg "$downloaddir/$airInstruments" -target /

	if [ $? = 0 ]; then
		/bin/echo "AIR Instruments Bundle Install Successful."

		/bin/rm -rf "$downloaddir/$airInstrumentsdir"

		if [ ! -d "$downloaddir/$airInstrumentsdir" ]; then
			/bin/echo "AIR Instruments Bundle Deletion: Successful."
		else
			/bin/echo "AIR Instruments Bundle Deletion: Failed."
		fi
	else
		/bin/echo "AIR Instruments Bundle Install Failed."
	fi
else
	/bin/echo "AIR Instruments Bundle not found."
fi

/bin/echo "Complete"

exit 0
