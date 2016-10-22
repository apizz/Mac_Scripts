Script to check the logging in user's Active Directory group membership to determine if they need to be added to the _lpadmin group in order to add printers.

1) Checks if user is already in _lpadmin group, and exits if true

2) Checks if user is a member of the admin group, and exits if true

3) If user is not in either the above groups, checks for membership in several administrator and faculty Active Directory security groups, which if any are true, adds the user to the _lpadmin group.

LaunchAgent used to trigger script on user login
