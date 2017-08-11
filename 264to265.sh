#!/bin/bash


function CLEANUP {
   find "$folderToParse" -name ".tmpoutput.mp4" -o -name ".264files.log" -o -name ".filestoconvert.log" | while read fname; do rm "$fname"; done
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

CLEANUP

counter=0
find "$folderToParse" -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.m4v" | sort >> "$folderToParse/.filestoconvert.log"

IFS=$'\n'
for i in $(cat "$folderToParse/.filestoconvert.log"); do
    if [[ $(mediainfo "$i" | grep "HEVC" | wc -l) < 1 ]]; then
       echo "$i" >> "$folderToParse/.264files.log"
       counter=$((counter + 1))
    fi
done
if [[ $counter == 0 ]]; then
    echo "This folder is all x265!"
    exit 0
fi

echo "Total Files to be processed: $counter"

for i in $(cat "$folderToParse/.264files.log"); do
    if [[ $(mediainfo "$i" | grep "HEVC" | wc -l) < 1 ]]; then
    	echo "Transcoding: $(basename "$i")"
	sudo nice -n 19 ffmpeg -y -i "$i" -movflags faststart -c:a aac -c:v libx265 -preset veryslow -crf 19 "$folderToParse/.tmpoutput.mp4" > /dev/null 2>&1
    	if [[ "$?" == "0" ]]; then
	    mv "$folderToParse/.tmpoutput.mp4" "$i"
	    if [[ "$i" != *.mp4 ]]; then
	        mv "$i" "${i%.*}.mp4"
            fi
	counter=$((counter - 1))
    	fi
    echo ""
    echo ""
    fi
    echo "Files left to process: $counter"
done

CLEANUP

echo "Happy streaming!"
