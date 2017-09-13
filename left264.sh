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
echo -e "Looking for files in: $folderToParse\n"


counterfive=0
counterfour=0
TOTSIZE=0
TOTSIZEFOUR=0
TOTSIZEFIVE=0


IFS=$'\n'
let TOTAL=$(find "$folderToParse" -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.m4v" | grep -v ".tmpoutput*" | wc -l)

find "$folderToParse" -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.m4v" | grep -v ".tmpoutput*" | sort -n | while read fname; do
    FNAMESIZE=$(wc -c "$fname" | awk '{print $1}')
    if [[ $(basename "$fname" | cut -c 1) != "." ]]; then
	if [[ $(mediainfo "$fname" | grep "HEVC" | wc -l) != 0 ]]; then
	    let TOTSIZE=TOTSIZE+FNAMESIZE
	    let TOTSIZEFIVE=TOTSIZEFIVE+FNAMESIZE
	    let counterfive=counterfive+1
        else
	    let TOTSIZE=TOTSIZE+FNAMESIZE
	    let TOTSIZEFOUR=TOTSIZEFOUR+FNAMESIZE
            let counterfour=counterfour+1
        fi
    fi
    let RUNTOT=counterfive+counterfour
    PERCENTLEFT=$(echo "scale = 2;$counterfour / $TOTAL * 100" | bc -l)
    tput el1 && echo -ne "\e[0K\rChecked: $PERCENTLEFT%"
    if [[ $RUNTOT == $TOTAL ]]; then
	PERCENTSIZELEFT=$(echo "scale = 2;$TOTSIZEFOUR / $TOTSIZE * 100" | bc -l)
	GBLEFT=$(echo "scale = 0;$TOTSIZEFOUR / 1000000000" | bc -l)
	tput el1 && echo -ne "\e[0K\rSummary:\n" && echo -ne "\rFiles checked: $TOTAL\tFiles still x264: $PERCENTLEFT%\tBytes left x264:$PERCENTSIZELEFT%\tGB left: $GBLEFT\n\n"
	exit 0
    fi
done
