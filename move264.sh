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
    echo "Arg 2 needs to be the source folder"
    exit 1
fi

if [[ $3 != "" ]]; then
    FOLDERMAX="$3"
else
    FOLDERMAX=$(du -s "$COPYFOLDER" | awk '{print $1}')
fi


echo -e "Looking for 264 files in: $folderToParse\n"

SETSTATS () {
    FOLDERSIZE=$(du -s "$COPYFOLDER" | awk '{print $1}')
    FILESIZE=$(du -k "$fname" | cut -f 1)
    FILENAME=$(basename "$fname")
    let SPACELEFT=FOLDERMAX-FOLDERSIZE
    #let SPACELEFTGB=SPACELEFT/1000000
}

#FOLDERMAX=$(du -s "/mnt/" | awk '{print $1}')
#FOLDERMAX=260000000
TOTAL=0
#COPYFOLDER="/mnt/Daryl/264files/Movies/"
IFS=$'\n'
find "$folderToParse" -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.m4v" | sort -n | while read fname; do
    SETSTATS "$fname"
    echo -e "Free space left:\t$SPACELEFT KB"
    if [[ $FILESIZE -lt $SPACELEFT ]] && [[ $(ls "$COPYFOLDER" | grep "$FILENAME" | wc -l) -eq 0 ]]; then
	if [[ $(mediainfo "$fname" | grep "HEVC" | wc -l) -lt 1 ]]; then
	    if [[ $(basename "$fname" | cut -c 1) == "." ]]; then
		echo "I won't bother the transcoding going on in here :)"
	    else
		echo "$(basename "$fname") fits! Copying ..."
		cp "$fname" "$COPYFOLDER"
	    fi
	fi
    else
	echo "File too big or already there!"
    fi
done


