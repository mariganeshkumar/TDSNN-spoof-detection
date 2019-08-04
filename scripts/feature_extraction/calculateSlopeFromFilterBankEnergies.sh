#!/bin/bash

if [ $# != 9 ]; then
	echo " Arg1: List of matlab features "
	echo " Arg2: Feature Name"
	echo " Arg3: DataType (train/dev/eval)"
	echo " Arg4: DataNature (genuine/spoofed/unknown)"
	echo " Arg5: Reference File list with propoer fileNames"
	echo " Arg6: Flag to remove first column or not (0/1)"
	echo " Arg7: featID"
	echo " Arg8: filterCount"
	echo " Arg9: attackType (LA/PA)"
	exit
fi

wdir=.
featRootDir=$wdir/features
matlabFeatList=$1
featName=$2
attackType=$9

if [ ! -d "$featRootDir" ]; then
	mkdir $featRootDir
fi

featID=$7
filterCount=$8
featDir=$featRootDir/$featName"_"$filterCount"Filters_"$featID
echo "FeatDir: $featDir"

if [ ! -d "$featDir" ]; then
	mkdir $featDir
	if [ ! -d "$featDir/$attackType" ]; then
		mkdir $featDir/$attackType
	fi
else
	if [ ! -d "$featDir/$attackType" ]; then
		mkdir $featDir/$attackType
	fi
fi
dataType=$3
dataNature=$4

shopt -s nocasematch
case "$dataType" in 
	train) 
		featDir_train=$featDir/$attackType/train
		featDir_genuine=$featDir_train/bonafide
		featDir_spoof=$featDir_train/spoofed
		if [ $dataNature == "spoofed" ]; then
			featDir1=$featDir_spoof
		else
			featDir1=$featDir_genuine
		fi
		mkdir $featDir_train
                mkdir $featDir1
                
	;;
	eval)
		featDir1=$featDir/$attackType/eval
                if [ ! -d "$featDir1" ]; then
                        mkdir $featDir1
                fi
	;;
	dev)
                featDir1=$featDir/$attackType/dev
		directorypathList=lists/devData_directoryNames.lst
                if [ ! -d "$featDir1" ]; then
                        mkdir $featDir1
                fi

	;;
	*)
		echo "Check the fourth argument"
		exit 1
esac
shopt -u nocasematch

referenceFileList=$5
removeEnergyFlag=$6
featExtn=$7
fileCount=`less $matlabFeatList | sort -u | wc -l`

less $matlabFeatList | head -3 | parallel -v -j25 --colsep " " --dryrun "python2.7 scripts/mfsExtract.py {1} $featDir1/{1/.}.$featName"                        
less $matlabFeatList | parallel -v -j25 --colsep " " "python2.7 scripts/mfsExtract.py {1} $featDir1/{1/.}.$featName" 
