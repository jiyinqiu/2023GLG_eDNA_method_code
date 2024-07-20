#!/bin/bash
set -e
set -u
set -o pipefail
#######################################################################################
#######################################################################################
# a shell script to loop through a set of fastq files and run fastp
#######################################################################################
#######################################################################################

# Usage: bash _loop_fastp.sh

PIPESTART=$(date)

HOMEFOLDER=$(pwd)

echo "Home folder is "${HOMEFOLDER}""

# set variables
INDEX=1

if [ ! -d fastp_outputs ] # if directory fastp_outputs does not exist
then
	mkdir fastp_outputs
fi

# read in folder list and make a bash array
find data/raw_data/*/* -maxdepth 0 -type d | sed 's/^.*\///g' > librarylist.txt # find all libraries in the data folder
library_info=librarylist.txt # put folderlist.txt into variable
library_names=($(cut -f 1 "$library_info" | uniq)) # convert variable to array this way
# echo ${library_names[@]} # echo all array elements

echo "There are" ${#library_names[@]} "folders that will be processed." # echo number of elements in the array

for library in ${library_names[@]}  # ${library_names[@]} is the full bash array
do
	echo "Now on Library" ${INDEX} of ${#library_names[@]}". Moved back to starting directory:"
	INDEX=$((INDEX+1))
	pwd

	echo "**** start of fastp"
	fastp --merge -i data/raw_data/*/${library}/${library}_1.fq.gz -I data/raw_data/*/${library}/${library}_2.fq.gz --merged_out ${library}_mergedtrimmed.fq.gz --html ${library}fastp.html
	echo "**** end of fastp"

	mv ${library}* fastp_outputs/
	
### activate when i am happy with the loop code
	cd "${HOMEFOLDER}"

done

mv fastp_outputs analysis/

echo "Pipeline started at $PIPESTART"
NOW=$(date)
echo "Pipeline ended at   $NOW"
