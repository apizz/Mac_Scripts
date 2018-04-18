
# ABOUT THE SCRIPT

As quickly as possible, restore a never-booted High Sierra OS image to an external machine
connected via Target Disk Mode.  Will automatically determine the optimal OS image filesystem
based on the detected storage media (SSD = APFS, HDD = HFS, Fusion Drive = HFS).

## Requirements & Assumptions:

1. The external machine to be restored already has the same version of High Sierra installed
as the OS restore image.
	- Apple's firmware updates come solely via the macOS installer app & macOS updates

2. You are using AutoDMG (https://github.com/MagerValp/AutoDMG) to build never-boot OS images.

3. You intend to either restore an OS image of the same filesystem (HFS > HFS; APFS > APFS)
or move from HFS to APFS (SSDs only) based on the drive storage media.
	- See https://blog.macsales.com/43043-using-apfs-on-hdds-and-why-you-might-not-want-to

4. An APFS and/or HFS image lives on the local machine
	- Image restoring over the network has not been tested, nor is it intended

5. There is only 1 external computer connected via Target Disk Mode to the machine running this script.  

## Additional (Optional) Capabilities

- Use `--force-hfs` to prevent restoring an APFS OS image to an SSD.

- Use `--keepjamflog` to copy the jamf.log off a JAMF-managed machine prior to OS restore and copy it back afterward. Similar to what you may be used to with Jamf Imaging.

- Use `--compname`Write a file with the desired computer hostname for collection & use later in your deployment workflow.

- If you've restored an OS image via this script previously and used `--compname / -c` to write a file with your desired hostname, use `--reusecompname` to refer to this file instead of entering the same or different hostname.

- Use `--timestamps` to write the OS image restore start and end date and time for collection & use later in your deployment workflow.  For example, I like to know how long it takes to go from base Mac to fully deployed and use this as part of the calculation.

- Use `--log-path` to specify an alternate path from the script's default LOGPATH.

## Usage

`./HighSierraOSRestore.sh --help`
- Show help message

`./HighSierraOSRestore.sh --version`
- Show version information

`./HighSierraOSRestore.sh --exitcodes`
- Show the exit code error list

### Examples

`sudo ./HighSierraOSRestore.sh [argument] --dry-run`
- Runs script printing all output given supplied arguments, but does not complete a restore or write any files to the external machine. Will instead perform an imagescan on the OS_IMAGE file. Great for testing!

`sudo ./HighSierraOSRestore.sh --compname <compname>`
- Following OS restore, writes file (COMPNAME_FILE) with the computer name

`sudo ./HighSierraOSRestore.sh --reusecompname`
- Checks for pre-existing COMPNAME_FILE on external machine, and if found will collect it and write it back following successful OS restore.

`sudo ./HighSierraOSRestore.sh --keepjamflog`
- Prior to OS restore, copies the /var/log/jamf.log file off the exernal machine and copies it back following successful OS restore.

`sudo ./HighSierraOSRestore.sh --log-path /path/to/log/folder`
- Writes log output to the specified path.

`sudo ./HighSierraOSRestore.sh --timestamps`
- Following OS restore, will write the collected restore start and end timestamps to a PLIST on the external machine.
