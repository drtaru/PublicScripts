#!/bin/bash

dialogApp="/Library/Application\ Support/Dialog/Dialog.app/Contents/MacOS/Dialog"
dialogBinary="/usr/local/bin/dialog"
testCommandFile=$( mktemp /var/tmp/dialogTest.XXX )
testJSON='{
    "title" : "Test",
    "message" : "Test",
    "icon" : "/Applications/Microsoft\ Word.app",
    "iconsize" : "198.0",
    "button1text" : "Continue",
    "infotext" : "Test",
    "titlefont" : "shadow=true, size=40",
    "messagefont" : "size=16",
    "height" : "700"
}'


echo "$testJSON" > "$testCommandFile"

eval "${dialogApp} --jsonfile ${testCommandFile} --json"


rm -rf $testCommandFile