#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

counter=$(find /RAID/tmpvideoreencode/ -name "*.avi" -o -name "*.mkv" | wc -l)
echo "Starting display timer"
echo "Current count: $counter"
echo ""
while [ $(find /RAID/tmpvideoreencode/ -name "*.avi" -o -name "*.mkv" | wc -l) > 0 ]; do
	#counter=$(find /RAID/tmpvideoreencode/ -name "*.avi" | wc -l)
	#echo $counter
	if [[ $(find /RAID/tmpvideoreencode/ -name "*.avi" -o -name "*.mkv" | wc -l) < $counter ]]; then
		counter=$(find /RAID/tmpvideoreencode/ -name "*.avi" -o -name "*.mkv" | wc -l)
		echo "Files left to process: $counter"
		echo ""
	fi
	sleep 5
	if [[ $(find /RAID/tmpvideoreencode/ -name "*.avi" -o -name "*.mkv" | wc -l) == 0 ]]; then
		break
	fi
done

echo "Re-encoding is done!"
