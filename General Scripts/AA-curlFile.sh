#!/bin/bash

###############################################################################
# Curl file to disk
# Created by: @drtaru, May-23-2023
#
# Summary:  Create a local copy of a hosted file for use in scripts, etc
#
# Usage:    Script name in Jamf Pro should start with AA- to make sure the script
#           runs before others in the same policy. That way you can supply updated
#           files to subsequent scripts in the same policy if needed
#           └ (Set parameter 6, overwrite to "true")
#
###############################################################################

fetch_from="$4"             # Parameter 4: Full URL
save_to="$5"                # Parameter 5: Full filesystem path including extension, ex: /var/tmp/icon.png
overwrite="${6:-"false"}"   # Parameter 6: Overwrite file if it already exists [ true | false (default) ]


# Check for the file and grab it if it does not exist
if [[ ! -f "${save_to}" || "${overwrite}" == "true" ]]; then
	curl -o "$save_to" "$fetch_from"
fi
