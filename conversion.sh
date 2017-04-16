#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi
rm tmplist
touch tmplist
chmod 777 tmplist
currentmovie=0
mp4convertinstance=0
counter=$(find /RAID/tmpvideoreencode/ -name "*.avi" -o -name "*.mkv" | wc -l)
echo ""
echo "Number of files to process:       $counter"
echo ""
while [ $(find /RAID/tmpvideoreencode/ -name "*.avi" -o -name "*.mkv" | wc -l) > 0 ]; do
	threads=$(ps ax | grep "sudo python" | grep "sickbeardmp4automator" | wc -l)
	filesworkedon=$(more tmplist | wc -l)
	if [ $threads > 12 ]; then
	    echo "Waiting for a few files to finish!"
	    while [[ ( $threads > 8 ) ]]; do
		echo "process max loop:"
		echo $threads
		sleep 5
	    done
	fi
	currentmovie="$(shuf -n 1 -e $( find /RAID/tmpvideoreencode/ -name "*.avi" -o -name "*.mkv" ))"
	if ! grep -Fxq "$(basename $currentmovie)" tmplist ; then
	    echo "Found a new file to edit!"
	    echo "Setting up:		$(basename $currentmovie)"
	    echo $(basename $currentmovie) >> tmplist
	    sudo python /RAID/sickbeardmp4automator/manual.py -i "$currentmovie" -a &> /dev/null &
	    sleep 1
	fi
	echo "test"
done
echo "Re-encoding is done!"
