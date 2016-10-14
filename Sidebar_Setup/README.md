This is a script I've cobbled together taking functionality from other Github scripts and combining them into something that does the following:

* Utilizes mysides (https://github.com/mosen/mysides) to remove ALL existing sidebar favorites, whatever the defaults may be.
* Adds the desired sidebar favorites utilizing two arrays (inspiration from jacobsalma's GarageBand Loop PKG Download script - https://github.com/jacobsalmela/adminscripts/blob/master/downloadGarageBandContentPkgs.sh)
* Determines the user's ADHOME folder (thanks ENTIRELY to amsys SMBHome mount script - https://github.com/amsysuk/public_scripts/blob/master/mount_SMBHome/mounthome.sh), if they have one, and checks if their ADHOME is mounted. If not, it is mounted before being added to the sidebar.

NOTE: If you have trouble with the ADHOME folder portion, I did have to make some tweaks to how the ADHOME variable is gathered compared to the original amsys script for my environment.
