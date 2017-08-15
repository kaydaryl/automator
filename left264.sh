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
echo -e "Looking for files in: $folderToParse\n"


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
    PERCENTLEFT=$(echo "scale = 2;$counterfour / $TOTAL * 100" | bc -l)
    echo -ne "\e[0K\rChecked: $RUNTOT of $TOTAL\t\t264: $counterfour\t\t265: $counterfive\t\tUnprocessed: $PERCENTLEFT%"
done

echo ""
