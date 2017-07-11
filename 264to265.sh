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
rm -f /tmp/264to265list /RAID/tmpoutput.mp4
echo "Looking for files in: $folderToParse"

find "/RAID/tmpvideoreencode/" -type f -name "*.mkv" -o -name "*.mp4" -o -name "*.avi" > /tmp/264to265list
touch /RAID/filesleftas264

while read line; do
    if [[ $(mediainfo "$line" | grep "HEVC" | wc -l) > 0 && $(grep -rnw "$line" /RAID/filesleftas264 | wc -l) == 0 ]]; then
	echo "Transcoding: $(basename "$line")"
	ffmpeg -y -i "$line" -movflags faststart -c:a aac -c:v libx265 -preset medium -crf 19 "/RAID/tmpoutput.mp4" > /dev/null 2>&1
	newfilesize=$(du -k "/RAID/tmpoutput.mp4" | cut -f1)
	origfilesize=$(du -k "$line" | cut -f1)
	threshold=$(($origfilesize * 4 / 5))
	#if newfilesize > threshold && newfilesize > 0 && $? ==0
	if [[ "$?" == "0" ]]; then
	    if [[ $newfilesize < $threshold && $newfilesize > 0 ]]; then
		mv /RAID/tmpoutput.mp4 "$line"
	    else
		echo "$line" >> /RAID/filesleftas264.log
	    fi
	else
	    echo "$(basename "$line") failed"
	    echo "$lines" >> /RAID/filesthatfailed.log
	fi
	echo ""
	echo ""
    fi
    done < /tmp/264to265list
