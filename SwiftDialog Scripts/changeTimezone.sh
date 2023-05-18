#!/bin/zsh
###############################################################################
# Time Zone Selector
# Created by: @drtaru, May-07-2023
# Original script & inspiration: Mann Consulting (support@mann.com)
#
# Summary:  Prompt the employee with a list of available Time Zones on the system and allow them to change.
#
# Usage:   Run as part of a policy via Self Service.
#
###############################################################################

# 


APPLICATION="TimeZoneSelectorDialog"
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
currentUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ { print $3 }')
dialogApp="/Library/Application\ Support/Dialog/Dialog.app/Contents/MacOS/Dialog"
dialogBinary="/usr/local/bin/dialog"

####### Configuration
#
# To allow your users to select from a list of regions set regionChoice to true
# To lock a region set regionChoice to false and set regionFilter to one of the following
# Africa, America, Antarctica, Asia, Atlantic, Australia, Europe, GMT, Indian, Pacific
#
regionChoice="true"
regionFilter=""


# Functions

function dialogCheck() {

    # Get the URL of the latest PKG From the Dialog GitHub repo
    dialogURL=$(curl --silent --fail "https://api.github.com/repos/bartreardon/swiftDialog/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")

    # Expected Team ID of the downloaded PKG
    expectedDialogTeamID="PWA5E9TQ59"

    # Check for Dialog and install if not found
    if [ ! -e "/Library/Application Support/Dialog/Dialog.app" ]; then

        echo "Dialog not found. Installing..."

        # Create temporary working directory
        workDirectory=$( /usr/bin/basename "$0" )
        tempDirectory=$( /usr/bin/mktemp -d "/private/tmp/$workDirectory.XXXXXX" )

        # Download the installer package
        /usr/bin/curl --location --silent "$dialogURL" -o "$tempDirectory/Dialog.pkg"

        # Verify the download
        teamID=$(/usr/sbin/spctl -a -vv -t install "$tempDirectory/Dialog.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')

        # Install the package if Team ID validates
        if [[ "$expectedDialogTeamID" == "$teamID" ]]; then

            /usr/sbin/installer -pkg "$tempDirectory/Dialog.pkg" -target /
            sleep 2
            dialogVersion=$( /usr/local/bin/dialog --version )
            echo "swiftDialog version ${dialogVersion} installed; proceeding..."

        else

            # Display a so-called "simple" dialog if Team ID fails to validate
            echo "swiftDialog Team ID failed to validate"
            exit 1

        fi

        # Remove the temporary working directory when done
        /bin/rm -Rf "$tempDirectory"

    else

        echo "swiftDialog version $(/usr/local/bin/dialog --version) found; proceeding..."

    fi

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Parse JSON via osascript and JavaScript for the Welcome dialog (thanks, @bartreardon!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function get_json_value() {
    for var in "${@:2}"; do jsonkey="${jsonkey}['${var}']"; done
    JSON="$1" osascript -l 'JavaScript' \
        -e 'const env = $.NSProcessInfo.processInfo.environment.objectForKey("JSON").js' \
        -e "JSON.parse(env)$jsonkey"
}


# Main Program

dialogCheck

# Setup temp command file
regionCommandFile=$( mktemp /var/tmp/dialogRegion.XXX )
timeCommandFile=$( mktemp /var/tmp/dialogTime.XXX )

# Get Branding Image if exists. replace icon="none" with a url or path to icon if not using Jamf branding
if [[ -a "/Users/"$currentUser"/Library/Application Support/com.jamfsoftware.selfservice.mac/Documents/Images/brandingimage.png" ]]; then
    icon="/Users/"$currentUser"/Library/Application Support/com.jamfsoftware.selfservice.mac/Documents/Images/brandingimage.png"
else
    icon="none"
fi

if [[ $regionChoice == "true" ]]; then

    # Build the JSON for the Region Dialog
    regionJSON='{
        "title" : "Time Zone Update",
        "message" : "Please select a region from the following list and click Continue",
        "alignment" : "center",
        "selectitems" : [
            { "title" : "Region",
                "default" : "All",
                "values" : [
                    "All",
                    "Africa",
                    "America",
                    "Antarctica",
                    "Asia",
                    "Atlantic",
                    "Australia",
                    "Europe",
                    "GMT",
                    "Indian",
                    "Pacific"
                ]
            }
        ],
        "icon" : "'$icon'",
        "button1text" : "Continue",
        "button2text" : "Cancel",
        "titlefont" : "shadow=true, size=40",
        "messagefont" : "size=20",
        "height" : "200",
        "ontop" : 1
    }'

    echo "$regionJSON" > "$regionCommandFile"
    regionResults=$( eval "${dialogApp} --jsonfile ${regionCommandFile} --json" )

    # Evaluate User Input
    if [[ -z "${regionResults}" ]]; then
        regionReturnCode="2"
    else
        regionReturnCode="0"
    fi

    case "${regionReturnCode}" in
        0)  # Process exit code 0 scenario here

            selectedRegion=$(get_json_value "$regionResults" "Region" "selectedValue" )
            if [[ "$selectedRegion" == "All" ]]; then
                echo "User selected All regions and clicked Continue"
                regionFilter=""
            else
                echo "User selected $selectedRegion and clicked Continue"
                regionFilter="${selectedRegion}"
            fi
            ;;
        2)  # Process exit code 2 scenario here
            echo "User clicked Quit"
            ;;
    esac
fi

# Get Timezones and format them for dialog.
timezones=$( systemsetup -listtimezones | awk 'NR>1 {print $1}' | tr ' ' '\n' | grep "${regionFilter}" | sed -e 's/^/\"/' -e 's/$/",/' -e '$ s/.$//' )


# Build the JSON for the Timezone Dialog
timeJSON='{
    "title" : "Time Zone Update",
    "message" : "Please select the correct Time Zone from the following list and click Set",
    "alignment" : "center",
    "selectitems" : [
        { "title" : "Current Time Zone",
            "values" : [
                '${timezones}'
            ]
        }
    ],
    "icon" : "'$icon'",
    "button1text" : "Set",
    "button2text" : "Cancel",
    "titlefont" : "shadow=true, size=40",
    "messagefont" : "size=20",
    "height" : "200",
    "ontop" : 1
}'

echo "$timeJSON" > "$timeCommandFile"
timezoneResults=$( eval "${dialogApp} --jsonfile ${timeCommandFile} --json" )

# Evaluate User Input
if [[ -z "${timezoneResults}" ]]; then
    timezoneReturnCode="2"
else
    timezoneReturnCode="0"
fi

case "${timezoneReturnCode}" in
    0)  # Process exit code 0 scenario here
        
        selectedTimezone=$(get_json_value "$timezoneResults" "Current Time Zone" "selectedValue" )
        echo "User selected $selectedTimezone and clicked Set"
        systemsetup -settimezone ${selectedTimezone} 2>/dev/null
        currentTimezone=$(systemsetup -gettimezone | awk '{ print $3}')
        if [[ "$selectedTimezone" != "$currentTimezone" ]]; then
            echo "Something went wrong, System Timezone of $currentTimezone does not match selected timezone of $selectedTimezone"
            rm -rf $regionCommandFile
            rm -rf $timeCommandFile
            exit 1
        else
            echo "Timezone successfully set to $selectedTimezone"
        fi
        ;;
    2)  # Process exit code 2 scenario here
        echo "User clicked Quit"
        ;;
esac

rm -rf $regionCommandFile
rm -rf $timeCommandFile
exit 0