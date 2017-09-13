#!/bin/bash

function HOWMANY {
    COUNTER=$(find "$folderToParse" -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.m4v" | wc -l)
}

set -e
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

if ! [ -x "$(command -v mediainfo)" ]; then
    echo "Installing mediainfo"
    apt-get install -y mediainfo -qq
fi

if ! [ -x "$(command -v ffmpeg)" ]; then
    echo "Installing ffmpeg"
    apt-get install -y ffmpeg -qq
fi

if [[ $1 != "" ]]; then
    folderToParse="$1"
else
    folderToParse="$PWD"
fi


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

echo "Looking for files in: $folderToParse"
for i in $(find "$folderToParse" -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.m4v" | sort -n); do
    TEMPCHECK=0
    if [[ $(mediainfo "$i" | grep "HEVC" | wc -l) < 1 ]]; then
    	echo -e "${yellow}Transcoding: $(basename "$i")${reset}"
    	sudo nice -n 19 ffmpeg -y -i "$i" -xerror -movflags faststart -c:a aac -c:v libx265 -preset ultrafast -crf 19 "$folderToParse/.tmpoutput.mp4" > /dev/null 2>&1
    	if [[ "$?" == "0" ]]; then
            if [[ "$i" != *.mp4 ]]; then
            	mv "$i" "${i%.*}.mp4"
	    else
		mv "$folderToParse/.tmpoutput.mp4" "$i"
  	    fi
	    tput cuu 1 && tput el && echo -ne "${green}Transcoding: $(basename "$i"):\tCOMPLETE${reset}"
	else
	    rm -r "$folderToParse/.tmpoutput.mp4"
	    tput cuu 1 && tput el && echo -ne "${red}Transcoding: $(basename "$i"):\tFAILED${reset}"
    	fi
	let TEMPCHECK=1
    fi
    COUNTER=$((COUNTER - 1))   
    if [[ $TEMPCHECK == 1 ]]; then
	echo -e "\t${green}Files left to process: $COUNTER${reset}"
    fi
done

echo "Happy streaming!"
