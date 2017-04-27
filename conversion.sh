#!/bin/bash

# 1. Sequential reencoding
# 2. 
# 3. 
# 4. 
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
getCPU() {
    cpuUsage=$(top -bn 1 | awk '{print $9}' | tail -n +8 | awk '{s+=$1} END {print s}')
}

getCount() {
    counter=$(find /RAID/tmpvideoreencode/ -name "*.avi" -o -name "*.mkv" -o -name "*.mp4" | wc -l)
}

# Moving the random movie stuff up here as well.
# Eventually will want it sequential so that i can better lost how many are left
getRandom() {
    randomfile=$(find /RAID/tmpvideoreencode/ -name "*.avi" -o -name "*.mkv" -o -name "*.mp4" | shuf -n 1)
}

getFilesworked() {
    filesworked=$(more /tmp/tmplist | wc -l)
}

getThreads() {
    threads=$(pgrep ffmpeg | wc -l)
}

getCurrentthread() {
    getThreads
    printf "Threads: $threads of $nproc \n"
}

startEndgame() {
    echo "Final files started"
    while [ $threads > 0 ]; do
	#this breaks once all atarted but not done yet
	getThreads
	#add function to only print if change
	printf "\nFiles left: $threads"
	if [[ $threads == 0 ]]; then
	    printf "\nRe-encoding is done!\n"
	    exit
	fi
	sleep 10
	done  
}

cpuIdle() { 
    echo "CPU maxed, wating to start more"
    while [[ $cpuUsage > $(($nproc * 85)) ]]; do
	sleep 5
	getCPU
    done
}
#if I don't touch tmplist, it is not initialized. Removing @ beginning script ensures clean run
rm -f /tmp/tmplist
touch /tmp/tmplist

getCount
getRandom
getFilesworked
getThreads
getCPU
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
	getCPU
	if [[ $cpuUsage > $(($nproc * 85)) ]]; then
	    cpuIdle
	fi
	if [[ "$filesworked" == "$countertotal" ]]; then
	    startEndgame
	fi
	if ! grep -Fxq "$(basename "$randomfile")" /tmp/tmplist ; then
	    filesworkedon=$(more /tmp/tmplist | wc -l)
	    echo "Found a new file to edit!"
	    echo "Setting up:		$(basename "$randomfile")"
	    echo $(basename "$randomfile") >> /tmp/tmplist
	    nice -19 python /RAID/sickbeardmp4automator/all.py -i "$randomfile" -a &> /dev/null &
	    sleep 5
	fi
	getCount
done
printf "\nRe-encoding is done!\n"
