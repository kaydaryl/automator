#!/bin/bash

set -e
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

function displaytime {
  local T=$1
  local D=$((T/60/60/24))
  local H=$((T/60/60%24))
  local M=$((T/60%60))
  local S=$((T%60))
  [[ $D > 0 ]] && printf '%d days ' $D
  [[ $H > 0 ]] && printf '%d hours ' $H
  [[ $M > 0 ]] && printf '%d minutes ' $M
  [[ $D > 0 || $H > 0 || $M > 0 ]] && printf 'and '
  printf '%d seconds\n' $S
}

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

echo "Files to process: $counter"

for i in $(cat "$folderToParse/.264files.log"); do
    if [[ $(mediainfo "$i" | grep "HEVC" | wc -l) < 1 ]]; then
	echo "Transcoding: $basename"$i""
	SECONDS=0
	nice -19 ffmpeg -y -i "$i" -movflags faststart -c:a aac -c:v libx265 -preset medium -crf 19 "$folderToParse/.tmpoutput.mp4" > /dev/null 2>&1 &
	sudo pv -pd $(pgrep -n "ffmpeg")
	NEWNAME=$(echo $i | rev | cut -c 4- | rev)
        NEWNAME+=mp4
        echo "Moving: $NEWNAME"
	rm "$i"
	mv "$folderToParse/.tmpoutput.mp4" "$NEWNAME"
	counter=$[$counter - 1]
	echo "Time to transcode: $SECONDS"
    echo ""
    echo ""
    fi
    echo "Files left to process: $counter"
done

rm -f "$folderToParse/.filestoconvert.log" "$folderToParse/.tmpoutput.mp4" "$folderToParse/.264files.log"

echo "Happy streaming!"

