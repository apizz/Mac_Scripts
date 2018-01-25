Output of jamfHelper help page (<code>jamfHelpder -help</code>)

JAMF Helper Help Page

Usage: jamfHelper -windowType [-windowPostion] [-title] [-heading] [-description] [-icon] [-button1] [-button2] [-defaultButton] [-cancelButton] [-showDelayOptions] [-alignDescription] [-alignHeading] [-alignCountdown] [-timeout] [-countdown] [-iconSize] [-lockHUD] [-startLaunchd] [-fullScreenIcon] [-kill]

<code>-windowType</code> [hud | utility | fs]
	hud: creates an Apple "Heads Up Display" style window
	utility: creates an Apple "Utility" style window
	fs: creates a full screen window the restricts all user input
		WARNING: Remote access must be used to unlock machines in this mode

<code>-windowPosition</code> [ul | ll | ur | lr]
	Positions window in the upper right, upper left, lower right or lower left of the user's screen
	If no input is given, the window defaults to the center of the screen

<code>-title</code> "string"
	Sets the window's title to the specified string

<code>-heading</code> "string"
	Sets the heading of the window to the specified string

<code>-description</code> "string"
	Sets the main contents of the window to the specified string

<code>-icon<c/ode> path
	Sets the windows image filed to the image located at the specified path

<code>-button1</code> "string"
	Creates a button with the specified label

<code>-button2</code> "string"
	Creates a second button with the specified label

<code>-defaultButton</code> [1 | 2]
	Sets the default button of the window to the specified button. The Default Button will respond to "return"

<code>-cancelButton</code> [1 | 2]
	Sets the cancel button of the window to the specified button. The Cancel Button will respond to "escape"

<code>-showDelayOptions</code> "int, int, int,..."
	Enables the "Delay Options Mode". The window will display a dropdown with the values passed through the string

<code>-alignDescription</code> [right | left | center | justified | natural]
	Aligns the description to the specified alignment

<code>-alignHeading</code> [right | left | center | justified | natural]
	Aligns the heading to the specified alignment

<code>-alignCountdown</code> [right | left | center | justified | natural]
	Aligns the countdown to the specified alignment

<code>-timeout</code> int
	Causes the window to timeout after the specified amount of seconds
	Note: The timeout will cause the default button, button 1 or button 2 to be selected (in that order)

<code>-countdown</code>
	Displays a string notifying the user when the window will time out

<code>-iconSize</code> pixels
	Changes the image frame to the specified pixel size

<code>-lockHUD</code>
	Removes the ability to exit the HUD by selecting the close button
<code>-startlaunchd</code>
	Starts the JAMF Helper as a launchd process
<code>-kill</code>
	Kills the JAMF Helper when it has been started with launchd
<code>-fullScreenIcon</code>
	Scales the "icon" to the full size of the window
	Note: Only available in full screen mode


Return Values: The JAMF Helper will print the following return values to stdout...
	0 - Button 1 was clicked
	1 - The Jamf Helper was unable to launch
	2 - Button 2 was clicked
	3 - Process was started as a launchd task
	XX1 - Button 1 was clicked with a value of XX seconds selected in the drop-down
	XX2 - Button 2 was clicked with a value of XX seconds selected in the drop-down
	239 - The exit button was clicked
	243 - The window timed-out with no buttons on the screen
	250 - Bad "-windowType"
	255 - No "-windowType"
