## Script Assumptions

1. You're running this script from the command line

2. You've used the appleLoops.py script to download your Apple loops - https://github.com/carlashley/appleLoops

3. You have copied the resulting garageband, logicpro, and/or mainstage folders to a mounted volume (USB flash drive, external hard drive, or network volume) and specified this path in the `DIRNAME` variable.

- **Note:** You do not need to have all 3 applications installed or their corresponding loops. The script checks to see if these applications are already installed, and if not they are skipped.

4. You have specified a log file for the script to write the Apple loop install statuses and check for duplicates.

- **Note:** If you want this log file in the root Library folder, you'll need to run the script with `sudo`.

## Usage

1. Run (`sudo`) /path/to/Apple_Loops_Install.sh

2. At each prompt, type "A" (not case sensitive) to choose to install all loops for the application, or "R" (not case sensitive) for only those that are required.  Apps not installed are skipped.
- If you have previously installed the loops for the app, you can instead type "S" (not case sensitive) to skip installing those loops.

3. Once all possible choices are made, type "Y" (not case sensitive) to install the chosen Apple loops. At this point you can also navigate to your PKG_INSTALL_MANIFEST directory to review exactly what's going to be installed.  Alternatively, you can type n(o) to not install anything and exit the script.

4. Walk a way while it runs and installs your desired loops.

### Warranty

No warranties.  I wrote this script for me and my environment, but you are happy to use it if it helps!
