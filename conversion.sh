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

currentmovie=0
mp4convertinstance=0

# By making a function, you can get the current count at any time, rather than
# having to re-run the same command. Same function, less typing.
getCount() {
    counter=$(find /RAID/tmpvideoreencode/ -name "*.avi" , -name "*.mkv" , -name "*.mp4" , -name "*.m4v" | wc -l)
}

# Moving the random movie stuff up here as well.
getRandom() {
    randomfile=$(find /RAID/tmpvideoreencode/ -name "*.avi" , -name "*.mkv" , -name "*.mp4" , -name "*.m4v" | shuf -n 1)
}

getFilesworked() {
    filesworked=$(more /tmp/tmplist | wc -l)
}

getThreads() {
    threads=$(ps ax | grep "sudo python" | grep "sickbeardmp4automator" | wc -l)
}

getCurrentthread() {
    getThreads
    printf "Threads: $threads of $nproc \n"
}

#if I don't touch tmplist, it is not initialized. Removing @ beginning script ensures clean run
rm -f /tmp/tmplist
touch /tmp/tmplist

getCount
getRandom
getFilesworked
getThreads
nproc=$(nproc)
countertotal=$counter
# Converting to printf 
printf "\nNumber of files to process: %10s\n" "$counter"

# Using function above
while [ $counter > 0 ]; do
  # I'd convert this to a function, using pgrep.
	getFilesworked
	getRandom
	getThreads
	getCount
	echo $threads
	if [[ $counter == 0 ]]; then
	    break
	fi
	if [[ $threads > $nproc ]]; then
	    echo "CPU maxed, wating to start more"
	    echo "Max Threads: $nproc"
	    while [[ ( $threads > $nproc ) ]]; do
		sleep 5
		getThreads
	    done
	fi
	if [[ "$filesworked" == "$countertotal" ]]; then
	    echo "Final files started"
	    while [ $threads > 0 ]; do
		getThreads
		printf "\nFiles left: $threads"
		if [ $threads == 0 ]; then
		    break
		fi
		sleep 10
	    done  
	fi
	if ! grep -Fxq "$(basename "$randomfile")" /tmp/tmplist ; then
	    filesworkedon=$(more /tmp/tmplist | wc -l)
	    echo "Found a new file to edit!"
	    echo "Setting up:		$(basename "$randomfile")"
	    echo $(basename "$randomfile") >> /tmp/tmplist
	    sudo nice -19 python /RAID/sickbeardmp4automator/all.py -i "$randomfile" -a &> /dev/null &
	    sleep 1
	fi
	getCount
done
printf "\nRe-encoding is done!\n"
