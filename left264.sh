#!/bin/bash

set -e
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi


if [[ $1 != "" ]]; then
    folderToParse="$1"
else
    folderToParse="$PWD"
fi
echo "Looking for files in: $folderToParse"


counterfive=0
counterfour=0

IFS=$'\n'
find "$folderToParse" -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.m4v" | sort -n | while read fname; do
    let TOTAL=$(find "$folderToParse" -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.m4v" | wc -l)
    if [[ $(basename "$fname" | cut -c 1) == "." ]]; then
	let TOTAL=TOTAL-1
    fi
    if [[ $(basename "$fname" | cut -c 1) != "." ]]; then
	if [[ $(mediainfo "$fname" | grep "HEVC" | wc -l) != 0 ]]; then
	    let counterfive=counterfive+1
        else
            let counterfour=counterfour+1
        fi
    fi
    let RUNTOT=counterfive+counterfour
    if [[ $TOTAL == $RUNTOT ]]; then
	let PERCENTLEFT=$(($counterfour / $TOTAL))*100
	echo -e "\n$PERCENTLEFT% of $TOTAL files left\n"
    fi
done

