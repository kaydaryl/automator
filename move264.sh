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
echo -e "Looking for 264 files in: $folderToParse\n"

SETSTATS () {
    FOLDERSIZE=$(du -s "$COPYFOLDER" | awk '{print $1}')
    FILESIZE=$(du -k "$fname" | cut -f 1)
    let SPACELEFT=FOLDERMAX-FOLDERSIZE
    #let SPACELEFTGB=SPACELEFT/1000000
}

FOLDERMAX=260000000
TOTAL=0
COPYFOLDER="/RAID/265files/"
IFS=$'\n'
find "$folderToParse" -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.m4v" | sort -n | while read fname; do
    SETSTATS "$fname"
    echo -e "Free space left:\t$SPACELEFT GB"
    if [[ $FILESIZE -lt $SPACELEFT ]]; then
	if [[ $(mediainfo "$fname" | grep "HEVC" | wc -l) -lt 1 ]]; then
	    if [[ $(basename "$fname" | cut -c 1) == "." ]]; then
		echo "I won't bother the transcoding going on in here :)"
	    else
		echo "$(basename "$fname") fits! Copying ..."
		cp "$fname" "$COPYFOLDER"
	    fi
	fi
    fi
done


