#!/bin/bash

dialogApp="/Library/Application\ Support/Dialog/Dialog.app/Contents/MacOS/Dialog"
dialogBinary="/usr/local/bin/dialog"
testJSONFile=$( mktemp /var/tmp/dialogTestJSON.XXX )
testCommandFile=$( mktemp /var/tmp/dialogTestCommand.XXX )

function get_json_value() {
    for var in "${@:2}"; do jsonkey="${jsonkey}['${var}']"; done
    JSON="$1" osascript -l 'JavaScript' \
        -e 'const env = $.NSProcessInfo.processInfo.environment.objectForKey("JSON").js' \
        -e "JSON.parse(env)$jsonkey"
}

testJSON='{
    "title" : "Test Dialog",
    "message" : "Test Message",
    "icon" : "none",
    "iconsize" : "1",
    "infobox" : "TEST Infobox",
    "button1text" : "Continue",
    "button2text" : "Quit",
    "infotext" : "Test InfoText",
    "titlefont" : "shadow=true, size=40",
    "selectitems" : [
    {"title" : "Select 1", 
    "style" : "radio",
    "values" : ["one","two","three"]},
    {"title" : "Select 2", "values" : ["red","green","blue"], "default" : "red"}
        ],
    "messagefont" : "size=16",
    "height" : "500",
}'

# Write JSON to file
echo "$testJSON" > "$testJSONFile"


# Run dialog and store results in variable
dialogResults=$( eval "${dialogApp} --jsonfile ${testJSONFile} --commandfile ${testCommandFile} --json" )

# Evaluate User Input
if [[ -z "${dialogResults}" ]]; then
    dialogReturnCode="2"
else
    dialogReturnCode="0"
fi

case "${dialogReturnCode}" in
    0)  # Process exit code 0 scenario here
        echo "User clicked Continue"
        # Do Stuff
        # jamf policy -event CUSTOMTRIGGER
        ;;
    2)  # Process exit code 2 scenario here
        echo "User clicked Quit"
        # Do Stuff
        ;;
esac


# Clean up
sleep 1
rm -rf $testJSONFile
rm -rf $testCommandFile