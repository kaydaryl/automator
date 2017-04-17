#!/bin/bash

# General bash practice: Exits the script if any command along the way fails.
set -e

# Style: Keep then on the same line as if, keeps the presentation of commands
# being run clean.
if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root"
  # General bash practice: Exit with a code, it will return 0 otherwise.
  exit 1
fi

# What is this even doing? Nothing in this script is writing to tmplist, so add
# a comment to explain what's going on. I presume it's the python process
# writing to it?
rm tmplist
touch tmplist
chmod 777 tmplist

# 
currentmovie=0
mp4convertinstance=0

# By making a function, you can get the current count at any time, rather than
# having to re-run the same command. Same function, less typing.
getCount() {
  find /RAID/tmpvideoreencode/ -name "*.avi" -o -name "*.mkv" | wc -l
}

# Moving the random movie stuff up here as well.
getRandom() {
  find /RAID/tmpvideoreencode/ -name "*.avi" -o -name "*.mkv" |
    shuf -n 1 -e -
}

counter=getCount

# Converting to printf 
printf "\nNumber of files to process: %50s\n" "$counter"

# Using function above
while [ getCount > 0 ]; do
  # I'd convert this to a function, using pgrep.
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
	currentmovie=getRandom
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
