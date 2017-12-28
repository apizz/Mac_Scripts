## About the Script

While the unmap feature within Jamf Pro policies' Printer payload is very useful, in some cases it is necessary to swap printers that have the same name.  In my case, I work with a Windows print server and so I want to continue to use the same settings and Queue name and only remove the old printer and install the new on our users' computers with the printer installed.

As such, I use this script as part of a Jamf Pro policy to uninstall the old printer first and then install the new printer with the normal Printer payload.

More details on how this script is used as part of my larger printer swap workflow can be found below:
