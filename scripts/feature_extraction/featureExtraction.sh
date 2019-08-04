#!/bin/bash

if  [ $# != 9 ]; then
	echo "Arg1: WaveFiles list"
	echo "Arg2: FeatureName (mfcc/mgd/lpcc)"
	echo "Arg3: deltaFlag (0/1)"
	echo "Arg4: DeltaDelta Flag (0/1)"
	echo "Arg5: dataType (dev/train/eval)"
	echo "Arg6: dataNature (genuine/spoofed)"
	echo "Arg7: frameLogEnergy (0/1)"
	echo "Arg8: cepstralCoefficients count (13-29)"
	echo "Arg9: Attack type"
	exit
fi

wdir=.
waveList=$1
featName=$2
deltaFlag=$3
deltaDeltaFlag=$4
dataType=$5
dataNature=$6
frameLogEnergy=$7
cepstrumCount=$8
attackType=$9

featRootDir=$wdir/features
featExtractBin=$wdir/bin/ComputeFeatures
confFile=$wdir/conf/fe-ctrl.base

#sed 's!cepstrumCount!'$cepstrumCount'!' $wdir/conf/fe-ctrl.base.template > $confFile

if [ ! -d "$featRootDir" ]; then
	mkdir $featRootDir
fi



shopt -s nocasematch
########################## To extract mfcc feature ##############################################
if [ $featName == "mfcc" ] || [ $featName  == "lfcc" ]; then
	if [ $deltaDeltaFlag == 1 ] && [ $frameLogEnergy == 1 ] ; then
		featType=frameLogEnergy+frameDeltaLogEnergy+frameDeltaDeltaLogEnergy+frameCepstrum+frameDeltaCepstrum+frameDeltaDeltaCepstrum
		featDir=$featRootDir/"$featName"_"$cepstrumCount"_ZSDA
		echo featDir: $featDir
	        if [ ! -d "$featDir" ]; then
        	        mkdir $featDir	
	        fi
	elif [ $deltaDeltaFlag == 1 ] && [ $frameLogEnergy == 0 ]; then
                featType=frameCepstrum+frameDeltaCepstrum+frameDeltaDeltaCepstrum
		featDir=$featRootDir/"$featName"_"$cepstrumCount"_SDA
		echo featDir: $featDir
                if [ ! -d "$featDir" ]; then
                        mkdir $featDir  
                fi
	elif [ $deltaDeltaFlag == 0 ] && [ $frameLogEnergy == 0 ] && [ $deltaFlag == 1 ]; then
        	featType=frameCepstrum+frameDeltaCepstrum
		featDir=$featRootDir/"$featName"_"$cepstrumCount"_SD
		echo featDir: $featDir
	        if [ ! -d "$featDir" ]; then
        	        mkdir $featDir
	        fi	
	else
                featType=frameCepstrum
                featDir=$featRootDir/"$featName"_"$cepstrumCount"_S
                echo featDir: $featDir
                if [ ! -d "$featDir" ]; then
                        mkdir $featDir
                fi		
	fi
elif [ $featName == "mgd" ]; then
        if [ $deltaDeltaFlag == 1 ] && [ $frameLogEnergy == 1 ] ; then
                featType=frameLogEnergy+frameDeltaLogEnergy+frameDeltaDeltaLogEnergy+frameModGdCepstrumDCT+frameModGdDeltaCepstrumDCT+frameModGdDeltaDeltaCepstrumDCT
		featDir=$featRootDir/mgd_"$cepstrumCount"_ZSDA
                if [ ! -d "$featDir" ]; then
                        mkdir $featDir
                fi
        elif [ $deltaDeltaFlag == 1 ] && [ $frameLogEnergy == 0 ] ; then
                featType=frameModGdCepstrumDCT+frameModGdDeltaCepstrumDCT+frameModGdDeltaDeltaCepstrumDCT
                featDir=$featRootDir/mgd_"$cepstrumCount"_SDA
                if [ ! -d "$featDir" ]; then
                        mkdir $featDir
                fi
        else
		featType=frameModGdCepstrumDCT+frameModGdDeltaCepstrumDCT
                featDir=$featRootDir/mgd_"$cepstrumCount"_SD
                if [ ! -d "$featDir" ]; then
                        mkdir $featDir
                fi		
        fi
elif [ $featName == "lpcc" ]; then
        if [ $deltaDeltaFlag == 1 ] && [ $frameLogEnergy == 1 ] ; then
                featType=frameLogEnergy+frameDeltaLogEnergy+frameDeltaDeltaLogEnergy+frameLinearCepstrum+frameLinearDeltaCepstrum+frameLinearDeltaDeltaCepstrum
		featDir=$featRootDir/lpcc_"$cepstrumCount"_ZSDA
                if [ ! -d "$featDir" ]; then
                        mkdir $featDir
                fi
        elif [ $deltaDeltaFlag == 1 ] && [ $frameLogEnergy == 0 ] ; then
                featType=frameLinearCepstrum+frameLinearDeltaCepstrum+frameLinearDeltaDeltaCepstrum
                featDir=$featRootDir/lpcc_"$cepstrumCount"_SDA
                if [ ! -d "$featDir" ]; then
                        mkdir $featDir
                fi	
	else
	        featType=frameLinearCepstrum+frameLinearDeltaCepstrum
		featDir=$featRootDir/lpcc_"$cepstrumCount"_SD
                if [ ! -d "$featDir" ]; then
                        mkdir $featDir
                fi
        fi
elif [ $featName == "lfbe" ]; then
		featType=frameFilterbankEnergy
		featDir=$featRootDir/lfbe_"$cepstrumCount"_S/$attackType
        if [ ! -d "$featDir" ]; then
            mkdir -p $featDir
        fi
         
else
	echo "Check featureName in second argument"
	exit
fi

if [ ! -d "$featDir/$attackType" ]; then
        mkdir $featDir/$attackType
fi

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
		if [ ! -d "$featDir_train" ]; then 
			mkdir $featDir_train
		fi
                if [ ! -d "$featDir1" ]; then
                        mkdir $featDir1
                fi
     	less $waveList | head -3 | parallel -v --dryrun "$featExtractBin $confFile {1} $featType $featDir1/{1/.}.$featName 0.06 A"
		less $waveList | parallel -v -j30 "$featExtractBin $confFile {1} $featType $featDir1/{1/.}.$featName 0.06 A"        
		
	;;
	eval)
		featDir1=$featDir/$attackType/dev
                if [ ! -d "$featDir1" ]; then
                        mkdir $featDir1
                fi
		less $waveList | parallel -v -j30 "$featExtractBin $confFile {1} $featType $featDir1/{1/.}.$featName 0.06 A"
		featDir1=$featDir/$attackType/eval
                if [ ! -d "$featDir1" ]; then
                        mkdir $featDir1
                fi
	;;
	dev)
        featDir1=$featDir/$attackType/dev/bonafide
        if [ ! -d "$featDir1" ]; then
                mkdir -p $featDir1
        fi
        less $waveList | grep "bonafide" | head -3 | parallel -v --dryrun "$featExtractBin $confFile {1} $featType $featDir1/{1/.}.$featName 0.06 A"
		less $waveList | grep "bonafide" | parallel -v -j30 "$featExtractBin $confFile {1} $featType $featDir1/{1/.}.$featName 0.06 A"

		featDir1=$featDir/$attackType/dev/spoofed
        if [ ! -d "$featDir1" ]; then
                mkdir -p $featDir1
        fi
		less $waveList | grep "spoofed" | head -3 | parallel -v --dryrun "$featExtractBin $confFile {1} $featType $featDir1/{1/.}.$featName 0.06 A"
		less $waveList | grep "spoofed" | parallel -v -j30 "$featExtractBin $confFile {1} $featType $featDir1/{1/.}.$featName 0.06 A"
	;;
	*)
		echo "Check the fourth argument"
		exit 1
esac
shopt -u nocasematch
## "./bin/ComputeFeatures conf/fe-ctrl.base {1} frameCepstrum+frameDeltaCepstrum temp.mfcc 0.06 A"

