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

touch /RAID/filesthatfailed.log "$folderToParse/.filestoconvert.log"
rm -f "$folderToParse/.tmpoutput.mp4" "$folderToParse/.filestoconvert.log"

find "$folderToParse" -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" >> "$folderToParse/.filestoconvert.log"

while IFS='' read -r line || [[ -n "$line" ]]; do
    if [[ $(mediainfo "$line" | grep "HEVC" | wc -l) < 1 ]]; then
	echo "Transcoding: $basename"$line""
	ffmpeg -y -i "$line" -movflags faststart -c:a aac -c:v libx265 -preset medium -crf 19 -t 1 "$folderToParse/.tmpoutput.mp4" > /dev/null 2>&1
	if [[ "$?" == "0" ]]; then
	    echo "Moving: $basename"$line""
	    #mv "$folderToParse/.tmpoutput.mp4" "$line"
	fi
    fi
done < "$folderToParse/.filestoconvert.log"

#rm -f "$folderToParse/.filestoconvert.log" "$folderToParse/.tmpoutput.mp4"

