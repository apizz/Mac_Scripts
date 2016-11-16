<h2>Purpose</h2>

Restrict users within Active Directory groups from logging into certain machines.

<h2>What the Script Does</h2>

1) Identify the logging-in restricted user and collect all loginwindow process IDs in the event multiple users are logged in
2) Run a for-do loop match the loginwindow process ID to the user logging in
3) Present the user with a message about the restricted login
4) kill the user's loginwindow process
5) once killed, remove any trace the user logged into the machine - remove from user database and delete the created home folder
6) Echos actions taken for JSS policy log and writes to local log file

<h2>Requirements</h2>

* JSS / jamf Pro
* jamf binary & jamfHelper installed on local machine
* Policy scoped to the machine(s) you wish to restrict, triggered at login (required for collecting username and AD group membership), ongoing frequency
* The Active Directory groups you wish restrict on said machine(s) set as "Limitations" in the above policy
* Script in your JSS assigned to your login restriction policy

<h2>Additional options</h2>

If you wish to restrict logins to certain days and/or times, add a Client-Side Limitation to your policy.
