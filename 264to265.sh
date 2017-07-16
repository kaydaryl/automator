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

rm -f "$folderToParse/.filestoconvert.log" "$folderToParse/.tmpoutput.mp4" "$folderToParse/.264files.log"

counter=0
find "$folderToParse" -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.m4v" | sort >> "$folderToParse/.filestoconvert.log"

IFS=$'\n'
for i in $(cat "$folderToParse/.filestoconvert.log"); do
    if [[ $(mediainfo "$i" | grep "HEVC" | wc -l) < 1 ]]; then
	echo "$i" >> "$folderToParse/.264files.log"
	counter=$[$counter + 1]
    fi
done

echo $counter

for i in $(cat "$folderToParse/.264files.log"); do
    if [[ $(mediainfo "$i" | grep "HEVC" | wc -l) < 1 ]]; then
	echo "Transcoding: $basename"$i""
	ffmpeg -y -i "$i" -movflags faststart -c:a aac -c:v libx265 -preset medium -crf 19 "$folderToParse/.tmpoutput.mp4" > /dev/null 2>&1
	if [[ "$?" == "0" ]]; then
	    echo "Moving: $basename"$i""
	    mv "$folderToParse/.tmpoutput.mp4" "$i"
	    counter=$[$counter - 1]
	fi
    echo ""
    echo ""
    fi
    echo "Files left to process: $counter"
done

rm -f "$folderToParse/.filestoconvert.log" "$folderToParse/.tmpoutput.mp4" "$folderToParse/.264files.log"

echo "Happy streaming!"

