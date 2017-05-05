We deploy several different docks to machines and while a few applications get added or removed each year, packaging each one individually is time-consuming and prone to errors.

Written (poorly) in bash.

### Assumptions:

1. You deploy dockutil (https://github.com/kcrawford/dockutil) in your environment

2. You deploy outset (https://github.com/chilcote/outset) in your environment

### Requirements to run script:

1. A folder containing all of your dockutil scripts

2. A variable - PKG_BUILD_PREF - in each of your dockutil scripts which contains one of the following values to determine the outset directory structure to build the script into:

- boot-once
- boot-every
- login-once
- login-every
- login-priv-once
- login-priv-every
- on-demand

*ex. PKG_BUILD_PREF=login-once*

### What the script does:

1. Presents a dialog box for you to navigate to a folder containing all your dockutil scripts. All the steps completed will be written to a log file in this location (0_PKG_Build.log).
2. Once a folder is selected, lists all scripts (based on the file extension you specify in SCRIPT_FILE_EXT) and looks for a PKG_BUILD_PREF variable in each script to determine what outset directory structure to make for packaging
3. Creates the outset directory structure and copies the script to it
4. Creates a PKG
5. If the PKG is created succesfully, cleans up the created directories used to create the PKG.
6. Repeats steps 3 - 5 for all remaining dockutil scripts.
