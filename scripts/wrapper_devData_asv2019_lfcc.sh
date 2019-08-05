#!/bin/bash

if [ $# != 11 ]; then
	echo "Arg1: FeatureName (mfcc/mgd/mfs/cqcc/gfcc)"
	echo "Arg2: number of cepstral Coefficients (13/14/.../29)"
	echo "Arg3: FeatExtraction Delta Flag (0/1)"
	echo "Arg4: FeatExtraction DeltaDelta Flag (0/1)"
	echo "Arg5: FeatExtraction frameLogEnergy Flag (0/1)"
	echo "Arg6: Flag to extract features are not (0/1)"
	echo "Arg7: HiddenLayer1 config"
	echo "Arg8: HiddenLayer2 config"
	echo "Arg9: xvector dimension"
	echo "Arg10: train NN or not (0/1)"
	echo "Arg11: Attack type (LA/PA)"
	exit
fi

wdir=.
featName=$1
cepstrumCount=$2
deltaFlag=$3
deltaDeltaFlag=$4
logEnergyFlag=$5
featExtractFlag=$6
hLayer1=$7
hLayer2=$8
xvectorDim=$9
testNNFlag=${10}
attackType=${11}

if [ $deltaDeltaFlag == 1 ] && [ $deltaFlag == 1 ] && [ $logEnergyFlag == 1 ]; then
	featID=ZSDA
elif [ $deltaDeltaFlag == 1 ] && [ $deltaFlag == 1 ] && [ $logEnergyFlag == 0 ]; then
	featID=SDA
elif [ $deltaDeltaFlag == 0 ] && [ $deltaFlag == 1 ] && [ $logEnergyFlag == 1 ]; then
	featID=ZSD
elif [ $deltaDeltaFlag == 0 ] && [ $deltaFlag == 1 ] && [ $logEnergyFlag == 0 ]; then
	featID=SD	
elif [ $deltaDeltaFlag == 0 ] && [ $deltaFlag == 0 ] && [ $logEnergyFlag == 1 ]; then
	featID=ZS
elif [ $deltaDeltaFlag == 0 ] && [ $deltaFlag == 0 ] && [ $logEnergyFlag == 0 ]; then
	featID=S
else
	echo "Check all of your flag options"
	exit 1
fi

shopt -s nocasematch
devTestWavList=$wdir/lists/asv2019_"$attackType"_dev_wav.lst #asv2019_"$attackType"_dev_wav.lst
evalTestWavList=$wdir/lists/asv2019_"$attackType"_eval_wav.lst
genuineTrainWavList=$wdir/lists/asv2019_"$attackType"_genuineTrain_wav.lst
spoofedTrainWavList=$wdir/lists/asv2019_"$attackType"_spoofedTrain_wav.lst
devTestDataType=dev
evalTestDataType=eval

featureExtractionScript=$wdir/scripts/feature_extraction/featureExtraction.sh
windowSize=400


if [ $featName == "lfs" ]; then
        filterCount=30
        filterShape=0.9
        warpVal=0.0
        cepstrumCount="$filterCount"Filters
        configFile=$wdir/conf/fe-ctrl.base.lfs
        sed 's!filterCount!'$filterCount'!' $wdir/conf/fe-ctrl.base.lfs.template > $configFile
        dirName=lfs_"$filterCount"Filters_"$featID" ## lfs_40Filters_0.2Warp

        ########################## STEP - 1: Feature Extraction #################################################################
        if [ $featExtractFlag == 1 ]; then
                echo  "bash scripts/feature_extraction/lfs_extraction.sh $dirName $featID $attackType"
                bash scripts/feature_extraction/lfs_extraction.sh $dirName $featID $attackType
        else
                echo "Feature extraction skipped....! Existing features are used"
        fi

elif [ $featName == "mfs" ]; then
	filterCount=30
	warpVal=0.2
	#preEmphVal=1.0
	cepstrumCount="$filterCount"Filters
	configFile=$wdir/conf/fe-ctrl.base.mfs
	sed 's!filterCount!'$filterCount'!' $wdir/conf/fe-ctrl.base.mfs.template > $configFile
	#sed 's!warpVal!'$warpVal'!' temp.confFile > $configFile	
	dirName=mfs_"$filterCount"Filters_$featID ## mfs_40Filters_0.2Warp
	
	########################## STEP - 1: Feature Extraction #################################################################
	if [ $featExtractFlag == 1 ]; then
		echo  "bash scripts/feature_extraction/mfs_extraction.sh $dirName $featID $attackType"
		bash scripts/feature_extraction/mfs_extraction.sh $dirName $featID	$attackType
	else
		echo "Feature extraction skipped....! Existing features are used"
	fi

elif [ $featName == "imfs" ]; then
        echo "featName: $featName ; featID: $featID"
        filterCount=30
        cepstrumCount="$filterCount"Filters
        featName1="imfbe_"$filterCount"Filters_"$featID
        tempFeatName=imfbe
      	if [ $featExtractFlag == 1 ]; then
               	echo "matlab -nodesktop -nosplash -r \"cd scripts/feature_extraction/ ; inverseMelFilterBanks_devData('../$genuineTrainWavList','../$spoofedTrainWavList','../$devTestWavList','$tempFeatName','"$filterCount"Filters_"$featID"'); exit;\""
                matlab -nodesktop -nosplash -r "cd scripts/feature_extraction/ ; inverseMelFilterBanks_devData('../$genuineTrainWavList','../$spoofedTrainWavList','../$devTestWavList','$tempFeatName','"$filterCount"Filters_"$featID"'); exit;"
#              	echo "matlab -nodesktop -nosplash -r \"cd scripts/feature_extraction/ ; inverseMelFilterBanks_evalData('../$evalTestWavList','$tempFeatName','"$filterCount"Filters_"$featID"'); exit;\""
#               matlab -nodesktop -nosplash -r "cd scripts/feature_extraction/ ; inverseMelFilterBanks_devData('../$evalTestWavList','$tempFeatName','"$filterCount"Filters_"$featID"'); exit;"
                echo "FilterBank Log energies calcuated...! \n calculating frame slope now..."
                find scripts/feature_extraction/IMFBE_"$filterCount"Filters_"$featID"/train/bonafide/ -type f | sort -u > lists/matlab.imfbe.S.genuineFeats.lst
                find scripts/feature_extraction/IMFBE_"$filterCount"Filters_"$featID"/train/spoofed/ -type f | sort -u > lists/matlab.imfbe.S.replayedFeats.lst
                find scripts/feature_extraction/IMFBE_"$filterCount"Filters_"$featID"/dev/ -type f | sort -u > lists/matlab.imfbe.S.devTestFeats.lst
#                find scripts/feature_extraction/IMFBE_"$filterCount"Filters_"$featID"/eval/ -type f | sort -u > lists/matlab.imfbe.S.evalTestFeats.lst
                echo "bash scripts/feature_extraction/calculateSlopeFromFilterBankEnergies.sh lists/matlab.imfbe.S.genuineFeats.lst imfs train genuine $genuineTrainWavList 0 $featID $filterCount $attackType"
                bash scripts/feature_extraction/calculateSlopeFromFilterBankEnergies.sh lists/matlab.imfbe.S.genuineFeats.lst imfs train genuine $genuineTrainWavList 0 $featID $filterCount $attackType
                echo "bash scripts/feature_extraction/calculateSlopeFromFilterBankEnergies.sh lists/matlab.imfbe.S.replayedFeats.lst imfs train spoofed $spoofedTrainWavList 0 $featID $filterCount $attackType"
                bash scripts/feature_extraction/calculateSlopeFromFilterBankEnergies.sh lists/matlab.imfbe.S.replayedFeats.lst imfs train spoofed $spoofedTrainWavList 0 $featID $filterCount $attackType
                echo "bash scripts/feature_extraction/calculateSlopeFromFilterBankEnergies.sh lists/matlab.imfbe.S.devTestFeats.lst imfs dev unknown $devTestWavList 0 $featID $filterCount $attackType"
                bash scripts/feature_extraction/calculateSlopeFromFilterBankEnergies.sh lists/matlab.imfbe.S.devTestFeats.lst imfs dev unknown $devTestWavList 0 $featID $filterCount $attackType
#                echo "bash scripts/feature_extraction/calculateSlopeFromFilterBankEnergies.sh lists/matlab.imfbe.S.evalTestFeats.lst imfs eval $evalTestWavList 0 $featID $filterCount $attackType"
#                bash scripts/feature_extraction/calculateSlopeFromFilterBankEnergies.sh lists/matlab.imfbe.S.evalTestFeats.lst imfs eval unknown $evalTestWavList 0 $featID $filterCount $attackType
#		mv scripts/feature_extraction/IMFBE_"$cepstrumCount"_"$featID"/eval $wdir/features/"$featName"_"$cepstrumCount"_"$featID/"
        else
                echo "Feature extraction skipped....! Existing features are used"
        fi

elif [ $featName == "imfcc" ]; then
        echo "featName: $featName ; featID: $featID"
        filterCount=40
        featName1="imfcc_"$cepstrumCount"_"$featID
        tempFeatName=imfcc
        if [ $featExtractFlag == 1 ]; then
        	echo "matlab -nodesktop -nosplash -r \"cd scripts/feature_extraction/ ; imfcc_devData('../$genuineTrainWavList','../$spoofedTrainWavList','../$devTestWavList','$tempFeatName','"$cepstrumCount"_"$featID"','$filterCount'); exit;\""
                matlab -nodesktop -nosplash -r "cd scripts/feature_extraction/ ; imfcc_devData('../$genuineTrainWavList','../$spoofedTrainWavList','../$devTestWavList','$tempFeatName','"$cepstrumCount"_"$featID"','$filterCount'); exit;"
                #echo "matlab -nodesktop -nosplash -r \"cd scripts/feature_extraction/ ; imfcc_evalData('../$evalTestWavList','$tempFeatName','"$cepstrumCount"_"$featID"','$filterCount'); exit;\""
                #matlab -nodesktop -nosplash -r "cd scripts/feature_extraction/ ; imfcc_evalData('../$evalTestWavList','$tempFeatName','"$cepstrumCount"_"$featID"','$filterCount'); exit;"
                echo "IMFCC Features are extracted..."
        else
                echo "Feature extraction skipped....! Existing features are used"
        fi
	dirName="$featName"_"$cepstrumCount"_"$featID"
	mkdir $wdir/features/"$featName"_"$cepstrumCount"_"$featID"
	mkdir $wdir/features/"$featName"_"$cepstrumCount"_"$featID"/$attackType
	echo "mv scripts/feature_extraction/IMFCC_"$cepstrumCount"_"$featID"/* $wdir/features/"$featName"_"$cepstrumCount"_"$featID"/"$attackType/
	mv scripts/feature_extraction/IMFCC_"$cepstrumCount"_"$featID"/* $wdir/features/"$featName"_"$cepstrumCount"_"$featID/"$attackType/

elif [ $featName == "lfbe" ]; then
        echo "featName: $featName ; featID: $featID"
        filterCount=60
        cepstrumCount="$filterCount"Filters
        featName1="lfbe_"$filterCount"Filters_"$featID
        tempFeatName=lfbe
        if [ $featExtractFlag == 1 ]; then
                echo "matlab -nodesktop -nosplash -r \"cd scripts/feature_extraction/ ; lfbe_devData('../$genuineTrainWavList','../$spoofedTrainWavList','../$devTestWavList','$tempFeatName','"$cepstrumCount"_"$featID"','$filterCount'); exit;\""
                #matlab -nodesktop -nosplash -r "cd scripts/feature_extraction/ ; lfbe_devData('../$genuineTrainWavList','../$spoofedTrainWavList','../$devTestWavList','$tempFeatName','"$cepstrumCount"_"$featID"','$filterCount'); exit;"
                #echo "matlab -nodesktop -nosplash -r \"cd scripts/feature_extraction/ ; lfbe_evalData('../$evalTestWavList','$tempFeatName','"$cepstrumCount"_"$featID"','$filterCount'); exit;\""
                #matlab -nodesktop -nosplash -r "cd scripts/feature_extraction/ ; lfbe_evalData('../$evalTestWavList','$tempFeatName','"$cepstrumCount"_"$featID"','$filterCount'); exit;"
                echo "LFBE Features are extracted..."
        else
                echo "Feature extraction skipped....! Existing features are used"
        fi
        dirName="$featName"_"$cepstrumCount"_"$featID"
        mkdir $wdir/features/"$featName"_"$cepstrumCount"_"$featID"
        mkdir $wdir/features/"$featName"_"$cepstrumCount"_"$featID"/$attackType
        echo "mv scripts/feature_extraction/LFBE_"$cepstrumCount"_"$featID"/* $wdir/features/"$featName"_"$cepstrumCount"_"$featID"/"$attackType/
        mv scripts/feature_extraction/LFBE_"$cepstrumCount"_"$featID"/* $wdir/features/"$featName"_"$cepstrumCount"_"$featID/"$attackType/

elif [ $featName == "lfcc" ]; then
        echo "featName: $featName ; featID: $featID"
        filterCount=20
        featName1="lfcc_"$cepstrumCount"_"$featID
        tempFeatName=lfcc
        if [ $featExtractFlag == 1 ]; then
                echo "matlab -nodesktop -nosplash -r \"cd scripts/feature_extraction/ ; lfcc_devData('../$genuineTrainWavList','../$spoofedTrainWavList','../$devTestWavList','$tempFeatName','"$cepstrumCount"_"$featID"','$filterCount'); exit;\""
                matlab -nodesktop -nosplash -r "cd scripts/feature_extraction/ ; lfcc_devData('../$genuineTrainWavList','../$spoofedTrainWavList','../$devTestWavList','$tempFeatName','"$cepstrumCount"_"$featID"','$filterCount'); exit;"
                #echo "matlab -nodesktop -nosplash -r \"cd scripts/feature_extraction/ ; lfcc_evalData('../$evalTestWavList','$tempFeatName','"$cepstrumCount"_"$featID"','$filterCount'); exit;\""
                #matlab -nodesktop -nosplash -r "cd scripts/feature_extraction/ ; lfcc_evalData('../$evalTestWavList','$tempFeatName','"$cepstrumCount"_"$featID"','$filterCount'); exit;"
                echo "LFCC Features are extracted..."
        else
                echo "Feature extraction skipped....! Existing features are used"
        fi
        dirName="$featName"_"$cepstrumCount"_"$featID"
        mkdir $wdir/features/"$featName"_"$cepstrumCount"_"$featID"
        mkdir $wdir/features/"$featName"_"$cepstrumCount"_"$featID"/$attackType
        echo "mv scripts/feature_extraction/LFCC_"$cepstrumCount"_"$featID"/* $wdir/features/"$featName"_"$cepstrumCount"_"$featID"/"$attackType/
        mv scripts/feature_extraction/LFCC_"$cepstrumCount"_"$featID"/* $wdir/features/"$featName"_"$cepstrumCount"_"$featID/"$attackType/

else
        filterCount=40
        featureExtractionScript=$wdir/scripts/feature_extraction/featureExtraction.sh
        configFile=$wdir/conf/fe-ctrl.base
        sed 's!cepstrumCount!'$cepstrumCount'!' $wdir/conf/fe-ctrl.base.template.$featName > temp.confFile
        sed 's!filterCount!'$filterCount'!' temp.confFile > temp1.confFile
        sed 's!wndSize!'$windowSize'!' temp1.confFile > $configFile
        rm temp.confFile temp1.confFile
        ########################## STEP - 1: Feature Extraction #################################################################
        if [ $featExtractFlag == 1 ]; then
        	echo "bash $featureExtractionScript $genuineTrainWavList $featName $deltaFlag $deltaDeltaFlag train genuine $logEnergyFlag $cepstrumCount"
                bash $featureExtractionScript $genuineTrainWavList $featName $deltaFlag $deltaDeltaFlag train genuine $logEnergyFlag $cepstrumCount
                echo "bash $featureExtractionScript $spoofedTrainWavList $featName $deltaFlag $deltaDeltaFlag train spoofed $logEnergyFlag $cepstrumCount"
                bash $featureExtractionScript $spoofedTrainWavList $featName $deltaFlag $deltaDeltaFlag train spoofed $logEnergyFlag $cepstrumCount
                echo "bash $featureExtractionScript $devTestWavList $featName $deltaFlag $deltaDeltaFlag $devTestDataType unknown $logEnergyFlag $cepstrumCount"
                bash $featureExtractionScript $devTestWavList $featName $deltaFlag $deltaDeltaFlag $devTestDataType unknown $logEnergyFlag $cepstrumCount
                echo "bash $featureExtractionScript $evalTestWavList $featName $deltaFlag $deltaDeltaFlag $evalTestDataType unknown $logEnergyFlag $cepstrumCount"
                bash $featureExtractionScript $evalTestWavList $featName $deltaFlag $deltaDeltaFlag $evalTestDataType unknown $logEnergyFlag $cepstrumCount
        else
                echo "Feature extraction skipped....! Existing features are used"
        fi
fi

shopt -u nocasematch

genuineTrainFeatPath=`echo $wdir/features/"$featName"_"$cepstrumCount"_"$featID"/$attackType/train/bonafide` 
spoofedTrainFeatPath=`echo $wdir/features/"$featName"_"$cepstrumCount"_"$featID"/$attackType/train/spoofed` 
devTestFeatPath=`echo $wdir/features/"$featName"_"$cepstrumCount"_"$featID"/$attackType/dev`
evalTestFeatPath=`echo $wdir/features/"$featName"_"$cepstrumCount"_"$featID"/$attackType/eval`
genuineTrainFeatList=lists/asv2019_"$attackType"_genuineTrain_"$featName"_"$cepstrumCount""$featID".lst
spoofedTrainFeatList=lists/asv2019_"$attackType"_spoofedTrain_"$featName"_"$cepstrumCount""$featID".lst
devTestFeatList=lists/asv2019_"$attackType"_devTrials_"$featName"_"$cepstrumCount""$featID".lst
evalTestFeatList=lists/asv2019_"$attackType"_evalTrials_"$featName"_"$cepstrumCount""$featID".lst

ls -v $genuineTrainFeatPath/* > $genuineTrainFeatList
echo find $spoofedTrainFeatPath/ -type f  
find find $spoofedTrainFeatPath/ -type f  > $spoofedTrainFeatList
find $devTestFeatPath/* -type f > $devTestFeatList
find $evalTestFeatPath/* -type f > $evalTestFeatList

echo "GenuineFeatDir: $genuineTrainFeatPath, SpoofedFeatDir: $spoofedTrainFeatPath, and  devFeatDir: $devTestFeatPath, evalFeatDir: $evalTestFeatPath"
echo "GenuineFeatList: $genuineTrainFeatList, SpoofedFeatList: $spoofedTrainFeatList, and  devFeatList: $devTestFeatList, evalFeatList: $evalTestFeatList"
############################# 2. Prepare lists for train, dev and validation ##########################################
########### 20% of the genuineTrain and spoofedTrain are seggregated as validation dataset ############################
########### Development dataset is used as such for fine tuning the algorithm. ########################################
########### Val-data : is prepared randomly by choosing 20% of files ##################################################
featExtractFlag=1
if [ $featExtractFlag == 1 ]; then
	get_seeded_random()
	{
	  seed="$1"
	  openssl enc -aes-256-ctr -pass pass:"$seed" -nosalt \
	    </dev/zero 2>/dev/null
	}

	if [ $attackType == "LA" ]; then 
		genValLmt=`echo 2580 | awk '{print 2580*0.2}'`
		spfValLmt=`echo 22880 | awk '{print 22880*0.2}'`
	else
		genValLmt=`echo 5400 | awk '{print 5400*0.2}'`
		spfValLmt=`echo 48600 | awk '{print 48600*0.2}'`
	fi

	shuf -i1-$genValLmt --random-source=<(get_seeded_random 1) | sort -u > tmp1.$featName.$attackType.gen ### 516 is 20% of 2580 genuine train trials
	shuf -i1-$spfValLmt --random-source=<(get_seeded_random 2) | sort -u > tmp1.$featName.$attackType.spf ### 4560 is 20% of 22880 genuine train trials

	rm trainVal_gen_"$featName"_$attackType.lst trainVal_spf_"$featName"_$attackType.lst

	for i in `seq 1 1 $genValLmt`
	do
		curRandomNum=`less tmp1.$featName.$attackType.gen | head -$i | tail -1`
		less $genuineTrainFeatList | head -$curRandomNum | tail -1 >> trainVal_gen_"$featName"_$attackType.lst
	done
	lines=`less trainVal_gen_"$featName"_$attackType.lst | wc -l`
	echo "trainVal_gen_"$featName"_$attackType.lst generated and has $lines lines"
	
	for i in `seq 1 1 $spfValLmt`
	do
		curRandomNum=`less tmp1.$featName.$attackType.spf | head -$i | tail -1`
		less $spoofedTrainFeatList | head -$curRandomNum | tail -1 >> trainVal_spf_"$featName"_$attackType.lst
	done
	lines=`less trainVal_spf_"$featName"_$attackType.lst | wc -l `
	echo "trainVal_spf_"$featName"_$attackType.lst generated and has $lines lines"
fi

########################################################################################################################
less trainVal_gen_"$featName"_"$attackType".lst | sort -u > tmp.$featName.txt
mv tmp.$featName.txt trainVal_gen_"$featName"_"$attackType".lst

less trainVal_spf_"$featName"_"$attackType".lst | sort -u > tmp.$featName.txt
mv tmp.$featName.txt trainVal_spf_"$featName"_"$attackType".lst

comm -23 $genuineTrainFeatList trainVal_gen_"$featName"_"$attackType".lst > tmp1.$featName.txt
comm -23 $spoofedTrainFeatList trainVal_spf_"$featName"_"$attackType".lst >> tmp1.$featName.txt
mv tmp1.$featName.txt trainAlone.$featName.txt

less trainAlone.$featName.txt | parallel -v "wc -l {1}" | grep -v "wc " | sort -n | cut -d ' ' -f2 > train_"$featName"_header.txt
less trainVal_gen_"$featName"_"$attackType".lst trainVal_spf_"$featName"_"$attackType".lst > trainVal_"$featName"_header.txt

wc -l trainVal_gen_"$featName"_"$attackType".lst trainVal_spf_"$featName"_"$attackType".lst trainAlone.$featName.txt trainVal_"$featName"_header.txt

cp $devTestWavList dev_"$featName"_header.txt
#sed -i 's!data/ASV_spoof_2019/'$attackType'/ASVspoof2019_'$attackType'_dev/wav/!features/imfs_70Filters_S/'$attackType'/dev/'! dev_"$featName"_header.txt
sed -i 's!data/ASV_spoof_2019/'$attackType'/ASVspoof2019_'$attackType'_dev/wav/!features/'$dirName'/'$attackType'/dev/'! dev_"$featName"_header.txt
sed -i 's!\.wav!\.'$featName'!' dev_"$featName"_header.txt
sed -i 's!spoof/!spoofed/!' dev_"$featName"_header.txt
#sed -i 's!spoofed/!/!' dev_"$featName"_header.txt
#sed -i 's!bonafide/!/!' dev_"$featName"_header.txt


echo "ls -v $evalTestFeatPath/* > eval_"$featName"_header.txt"
ls -v $evalTestFeatPath/* > eval_"$featName"_header.txt


export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6
export LD_LIBRARY_PATH=/usr/local/cuda/lib64
#echo "python3 scripts/xvectors_naive_asv2019_LA_devData.py modelDir_"$featName"_"$attackType"_$hLayer1"_"$hLayer2"_"$xvectorDim $testNNFlag 0 resultFile_"$featName"_"$attackType"_$hLayer1"_"$hLayer2"_"$xvectorDim.txt train_"$featName"_header.txt trainVal_"$featName"_header.txt dev_"$featName"_header.txt"
#python3 scripts/xvectors_naive_asv2019_LA_devData.py modelDir_"$featName"_"$attackType"_$hLayer1"_"$hLayer2"_"$xvectorDim $testNNFlag 0 resultFile_"$featName"_"$attackType"_$hLayer1"_"$hLayer2"_"$xvectorDim.txt train_"$featName"_header.txt trainVal_"$featName"_header.txt dev_"$featName"_header.txt
echo "python3 scripts/xvectors_naive_asv2019_LA_devData_equal_batch.py modelDir_"$featName"_"$attackType"_$hLayer1"_"$hLayer2"_"$xvectorDim $testNNFlag 0 resultFile_"$featName"_"$attackType"_$hLayer1"_"$hLayer2"_"$xvectorDim.txt train_"$featName"_header.txt trainVal_"$featName"_header.txt dev_"$featName"_header.txt"
python3 scripts/xvectors_naive_asv2019_LA_devData_equal_batch.py modelDir_"$featName"_"$attackType"_$hLayer1"_"$hLayer2"_"$xvectorDim $testNNFlag 0 resultFile_"$featName"_"$attackType"_$hLayer1"_"$hLayer2"_"$xvectorDim.txt train_"$featName"_header.txt trainVal_"$featName"_header.txt dev_"$featName"_header.txt
export LD_PRELOAD=""
export LD_LIBRARY_PATH=""

################################## STEP - 3: Calculate EER ##################################################

resultFile=resultFile_"$featName"_"$attackType"_$hLayer1"_"$hLayer2"_"$xvectorDim.txt
cmGroundTruth=data/ASV_spoof_2019/"$attackType"/ASVspoof2019_"$attackType"_protocols/ASVspoof2019."$attackType".cm.dev.trl.txt
asvScoreFile=data/ASV_spoof_2019/"$attackType"/ASVspoof2019_"$attackType"_dev_asv_scores_v1.txt

###LA_D_9967770 spoof -0.67486644 LA_0078 LA_D_9967770 - VC_4 spoof
cmScoreFile=scoreFile_"$featName"_"$attackType"_$hLayer1"_"$hLayer2"_"$xvectorDim.txt
paste -d ' ' $resultFile $cmGroundTruth | awk '{if($1==$5) print $1" "$7" "$8" "$3}' > $cmScoreFile

rm output.$featName.txt
echo "matlab -nodesktop -nosplash -r \"cd ASVspoof_2019_baseline_CM_v1/tDCF_v1/ ; evaluate_tDCF_asvspoof19('../../$cmScoreFile','../../$asvScoreFile'); exit;\""
matlab -nodesktop -nosplash -r "cd ASVspoof_2019_baseline_CM_v1/tDCF_v1/ ; evaluate_tDCF_asvspoof19('../../$cmScoreFile','../../$asvScoreFile'); exit;" >> output.$featName.txt
tDCF=`less output.$featName.txt | grep "min-tDCF" | cut -d '=' -f2`
spkrEER=`less output.$featName.txt | grep "EER" | head -1 | cut -d '=' -f2 | cut -d '%' -f1`
spfEER=`less output.$featName.txt | grep "EER" | tail -1 | cut -d '=' -f2 | cut -d '%' -f1`
echo ""

### LA_D_9935163 spoof -0.49706092 LA_0078 LA_D_9935163 - VC_4 spoof
paste -d ' ' $resultFile $cmGroundTruth > tmp1.$featName
#awk '{if($4>=0.0) {print $0" bonafide"} else {print $0" spoof"}}' tmp1 > tmp2
trialCount=`less $cmGroundTruth | wc -l`
acc=`awk -F' ' -v hits=0 -v miss=0 -v trialCount=$trialCount '{if($1==$5 && $2==$8) {hits=hits+1} else {miss=miss+1}} END {print "hits="hits" ; miss="miss" ; acc=" (hits/trialCount)*100}' tmp1.$featName`
echo "HL1:$hLayer1 HL2:$hLayer2 xVecDim:$xvectorDim feat:$featName featID:"$cepstrumCount"$featID ========> spkrEER: $spkrEER ; spfEER: $spfEER ; t-DCF=$tDCF ; Acc: $acc" 
echo "HL1:$hLayer1 HL2:$hLayer2 xVecDim:$xvectorDim feat:$featName featID:"$cepstrumCount"$featID ========> spkrEER: $spkrEER ; spfEER: $spfEER ; t-DCF=$tDCF ; Acc: $acc" >> $featName.resultFile.30Mar19.txt
echo ""
