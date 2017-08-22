#!/bin/bash

function HOWMANY {
    COUNTER=$(find "$folderToParse" -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.m4v" | wc -l)
}

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


red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
reset=`tput sgr0`

IFS=$'\n'
if [[ $(find "$folderToParse" -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.m4v" | wc -l) == 0 ]]; then
    echo "This folder is all x265!"
    exit 0
else
    HOWMANY
fi


for i in $(find "$folderToParse" -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.m4v" | sort -n); do
    if [[ $(mediainfo "$i" | grep "HEVC" | wc -l) < 1 ]]; then
    	echo -e "${yellow}Transcoding: $(basename "$i")${reset}"
	sudo nice -n 19 ffmpeg -y -i "$i" -xerror -movflags faststart -c:a aac -c:v libx265 -preset medium -crf 19 "$folderToParse/.tmpoutput.mp4" > /dev/null 2>&1
    	if [[ "$?" == "0" ]]; then
	    mv "$folderToParse/.tmpoutput.mp4" "$i"
	    if [[ "$i" != *.mp4 ]]; then
	        mv "$i" "${i%.*}.mp4"
		echo -ne "\e[0K\r${green}Transcoding: $(basename "$i"): CCOMPLETE${reset}"
	      fi
	else
		echo -ne "\e[0K\r${red}Transcoding: $(basename "$i"): FAIL${reset}"
		rm -r "$folderToParse/.tmpoutput.mp4"
	fi
    COUNTER=$((COUNTER - 1))
    echo ""
    echo ""
    fi
    echo "Files left to process: $COUNTER"
done

echo "Happy streaming!"
