#!/bin/bash

set -e
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  # General bash practice: Exit with a code, it will return 0 otherwise.
  exit 1
fi


if [[ $1 != "" ]]; then
    folderToParse="$1"
else
    folderToParse="$PWD"
fi
#rm -f /tmp/264to265list /RAID/tmpoutput.mp4
echo "Looking for files in: $folderToParse"
find "$folderToParse" -name "*.mkv" -o -name "*.mp4" -o -name "*.avi" > /tmp/264to265list

touch /tmp/264to265list

while read line; do
    if [[ $(mediainfo "$line" | grep "library" | grep 264 | wc -l) > 0 ]]; then
	echo "Transcoding: $(basename "$line")"
	ffmpeg -y -i "$line" -movflags faststart -c:a aac -c:v libx265 -preset medium -crf 19 "/RAID/tmpoutput.mp4"
	newfilesize=$(du -k "/RAID/tmpoutput.mp4" | cut -f1)
	origfilesize=$(du -k "$line" | cut -f1)
	echo "$line"
	echo "New: $newfilesize"
	echo "Old: $origfilesize"
	threshold=$(($origfilesize * 4 / 5))
	echo "Threshold: $threshold"
	if [[ $newfilesize < $threshold && $newfilesize > 0 ]]; then
	    echo "True"	
	    mv /RAID/tmpoutput.mp4 "$line"
	fi
	echo ""
	echo ""
    fi
done < /tmp/264to265list

#rm -f /tmp/264to265list
