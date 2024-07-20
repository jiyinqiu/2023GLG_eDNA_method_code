#!/bin/bash
set -e
set -u
set -o pipefail
#######################################################################################
#######################################################################################
# a shell script to loop through a set of fastq files and run DAMe_sort
#######################################################################################
#######################################################################################

# Usage: bash _loop_DAMe_sort_12S_afterFastp.sh
# run on my macbook

PIPESTART=$(date)

HOMEFOLDER=$(pwd)

echo "Home folder is "${HOMEFOLDER}""

# set variables
INDEX=1

if [ ! -d DAMe_SORT_outputs_12S ] # if directory DAMe_SORT_outputs_12S does not exist
then
	mkdir DAMe_SORT_outputs_12S
fi

# read in folder list and make a bash array
find data/raw_data/12S/* -maxdepth 0 -type d | sed 's/^.*\///g' > librarylist.txt # find all libraries in the data folder
library_info=librarylist.txt # put librarylist.txt into variable
library_names=($(cut -f 1 "$library_info" | uniq)) # convert variable to array this way
# echo ${library_names[@]} # echo all array elements

echo "There are" ${#library_names[@]} "folders that will be processed." # echo number of elements in the array

for library in ${library_names[@]}  # ${library_names[@]} is the full bash array
do
	echo "Now on library" ${INDEX} of ${#library_names[@]}". Moved back to starting directory:"
	NUMBER=$(grep -E "${library}""\t" "${HOMEFOLDER}"/info/12S_pool_info.txt | cut -f 2)
	mkdir pool${NUMBER}
	pwd

	echo "**** start of DAMe_SORT"
	vsearch --fastq_filter analysis/fastp_outputs/${library}_mergedtrimmed.fq.gz --fastq_minlen 100 --fastqout pool${NUMBER}/${library}_mergedtrimmed_min100.fq
	cd pool${NUMBER}/
	gzip -9 ${library}_mergedtrimmed_min100.fq
	python2 ~/Downloads/DAMe-master-2/bin/sort.py -fq ${library}_mergedtrimmed_min100.fq.gz -p "${HOMEFOLDER}"/info/Primers_12S.txt -t "${HOMEFOLDER}"/info/Tags_eDNA_2023Jan.txt
	head -1 SummaryCounts.txt > SummaryCounts_sorted_${library}_Pool${NUMBER}.txt
	tail -n +2 SummaryCounts.txt | sed "s/Tag//g" | sort -k1,1n -k2,2n | awk 'BEGIN{OFS="\t";}{$1="Tag"$1;$2="Tag"$2; print $0;}' >> SummaryCounts_sorted_${library}_Pool${NUMBER}.txt
	python2 ~/Downloads/DAMe-master-2/bin/splitSummaryByPSInfo.py -p "${HOMEFOLDER}"/info/PCRsetsInfo_12S.txt -l ${NUMBER} -s SummaryCounts.txt -o splitSummaryByPSInfo_${library}_Pool${NUMBER}.txt

	echo "**** end of DAMe_SORT"
	cd ../
	mv pool${NUMBER} DAMe_SORT_outputs_12S/

	INDEX=$((INDEX+1))
	
	
### activate when i am happy with the loop code
	cd "${HOMEFOLDER}"

done

#mv DAMe_SORT_outputs_12S analysis/

echo "Pipeline started at $PIPESTART"
NOW=$(date)
echo "Pipeline ended at   $NOW"
