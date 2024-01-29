#!/bin/bash

####################################################################################################
#
# Setup Your Mac - Wait For Dock
# This script adds an additional wait for the Dock process
# that runs before the main SYM Policy / Script, this has alleviated
# issues with the enrollmentComplete trigger for my org.
#
####################################################################################################
#
# HISTORY
#
#   Version 2.0, 22-Jan-2024, Andrew Clark (@drtaru)
#   - Full rewrite
#   - Add logging
#   - Add policy parameters for policy trigger
#
####################################################################################################



scriptVersion="2.0"
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
scriptLog="${4:-"/var/log/org.myOrg.log"}"    # Parameter 4: Script Log Location [ /var/log/org.company.log ] ( This sould match what is set in your Setup Your Mac policy / script )
policyTrigger="${5}"                            # Parameter 5: Policy Trigger [ This should match the custom trigger set for your main Setup Your Mac policy in Jamf Pro, leave blank if this script is in the same policy as your setupYourMac policy **Not Recommended** )

####################################################################################################
#
# Pre-flight Checks
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Client-side Logging
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ! -f "${scriptLog}" ]]; then
    touch "${scriptLog}"
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Client-side Script Logging Function
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function updateScriptLog() {
    echo -e "$( date +%Y-%m-%d\ %H:%M:%S ) - ${1}" | tee -a "${scriptLog}"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Logging Preamble
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "\n\n###\n# Setup Your Mac - Wait For Dock (${scriptVersion})\n###\n"
updateScriptLog "Wait For Dock: Initiating …"


####################################################################################################
#
# Main Script
#
####################################################################################################

# Check for Dock process
dockStatus=$(pgrep -x Dock)
updateScriptLog "Wait For Dock: Waiting for Dock"
try=1

if [ "$dockStatus" == "" ]; then
	updateScriptLog "Wait For Dock: Dock process not running. Waiting..."
    while [ "$dockStatus" == "" ]; do
        sleep 2
        # Check for Dock Process
        (( try++ ))
        dockStatus=$(pgrep -x Dock)
    done
    tries=$((try * 2))
    updateScriptLog "Wait For Dock: Dock process running. Waited for $tries seconds."

else 
    updateScriptLog "Wait For Dock: Dock process already running. Continuing..."
fi


# Run Setup Your Mac custom trigger
if [ -n $policyTrigger ]; then
    updateScriptLog "Wait For Dock: Running Setup Your Mac custom policy trigger $policyTrigger..."
    /usr/local/bin/jamf policy -event $policyTrigger
else
    exit 0
fi