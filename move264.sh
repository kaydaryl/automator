#!/bin/bash

set -e
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi


if [[ $1 != "" ]]; then
    folderToParse="$1"
else
    echo "Arg 1 needs to be the source folder"
    exit 1
fi

if [[ $2 != "" ]]; then
    COPYFOLDER="$2"
else
    echo "Arg 2 needs to be the destination folder"
    exit 1
fi

if [[ $3 != "" ]]; then
    FOLDERMAX="$3"
else
    FOLDERMAX=$(df "$COPYFOLDER" | tail -n 1 | awk '{print $4}')
fi


echo -e "Looking for 264 files in: $folderToParse\n"

SETSTATS () {
    FOLDERSIZE=$(df "$COPYFOLDER" | tail -n 1 | awk '{print $4}')
    FILESIZE=$(du -k "$fname" | cut -f 1)
    FILENAME=$(basename "$fname")
    SPACELEFT=$( echo "$FOLDERMAX - $FOLDERSIZE" | bc)
}

TOTAL=0
IFS=$'\n'
find "$folderToParse" -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.m4v" | sort -n | while read fname; do
    SETSTATS "$fname"
    if [[ $FILESIZE -lt $SPACELEFT ]] && [[ $(ls "$COPYFOLDER" | grep "$FILENAME" | wc -l) -eq 0 ]]; then
	if [[ $(mediainfo "$fname" | grep "HEVC" | wc -l) -lt 1 ]]; then
	    if [[ $(basename "$fname" | cut -c 1) == "." ]]; then
		echo "I won't bother the transcoding going on in here :)"
	    else
		echo "$(basename "$fname") fits! Copying ..."
		cp "$fname" "$COPYFOLDER"
		echo -e "Free space left:\t$SPACELEFT KB"
	    fi
	fi
    else
	echo "File too big or already there!"
    fi
done


