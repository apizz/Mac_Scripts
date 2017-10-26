Remove Wifi Networks Selector

Scenario:
- Non-admin users have a number of saved Wi-Fi networks that are causing problems or that are being defaulted to undesirably

Script Process:
1. Script collects all saved preferred networks and removes the SSID specified in the `ExcludeSSID` variable
2. Presents a multi-selection list via AppleScript with all saved Wi-Fi networks.
3. User selects one or more Wi-Fi networks from the list and clicks the 'Remove' button.
4. Script takes the selections and removes each preferred network from the machine
