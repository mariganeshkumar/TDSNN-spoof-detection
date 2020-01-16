#!/bin/bash

if [ $# != 12 ]; then
	echo "Arg1: FeatureName (lfcc/lfbe)"
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
    echo "Arg12: Log file to log the results"
	exit
fi

wdir=.
databasePath=data/
featName=$1
cepstrumCount=$2
deltaFlag=$3
deltaDeltaFlag=$4
logEnergyFlag=$5
featExtractFlag=$6
hLayer1=$7
hLayer2=$8
xvectorDim=${9}
testNNFlag=${10}
attackType=${11}
logFile=${12}



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
genuineTrainWavList=$wdir/lists/asv2019_"$attackType"_genuine_train_wav.lst
spoofedTrainWavList=$wdir/lists/asv2019_"$attackType"_spoof_train_wav.lst
devTestDataType=dev
evalTestDataType=eval
devCMGroundTruth=data/"$attackType"/ASVspoof2019_"$attackType"_cm_protocols/ASVspoof2019."$attackType".cm.dev.trl.txt
devASVScoreFile=data/"$attackType"/ASVspoof2019_"$attackType"_asv_scores/ASVspoof2019."$attackType".asv.dev.gi.trl.scores.txt
evalCMGroundTruth=data/"$attackType"/ASVspoof2019_"$attackType"_cm_protocols/ASVspoof2019."$attackType".cm.eval.trl.txt
evalASVScoreFile=data/"$attackType"/ASVspoof2019_"$attackType"_asv_scores/ASVspoof2019."$attackType".asv.eval.gi.trl.scores.txt


featureExtractionScript=$wdir/scripts/feature_extraction/featureExtraction.sh
windowSize=400



featDir=$wdir/features/"$featName"_"$cepstrumCount"_"$featID/"$attackType/
exp_name="$featName"_"$attackType"_"$hLayer1"_"$hLayer2"_"$xvectorDim"
echo $exp_name

if [ $featName == "lfbe" ]; then
        echo "featName: $featName ; featID: $featID"
        filterCount=60
        cepstrumCount="$filterCount"Filters
        featName1="lfbe_"$filterCount"Filters_"$featID
        tempFeatName=lfbe
        if [ $featExtractFlag == 1 ]; then
                echo "matlab -nodesktop -nosplash -r \"cd scripts/feature_extraction/ ; lfbe_devData('../../$genuineTrainWavList','../../$spoofedTrainWavList','../../$devTestWavList','$tempFeatName','"$cepstrumCount"_"$featID"','$filterCount'); exit;\""
                #matlab -nodesktop -nosplash -r "cd scripts/feature_extraction/ ; lfbe_devData('../../$genuineTrainWavList','../../$spoofedTrainWavList','../../$devTestWavList','$tempFeatName','"$cepstrumCount"_"$featID"','$filterCount'); exit;"
                #echo "matlab -nodesktop -nosplash -r \"cd scripts/feature_extraction/ ; lfbe_evalData('../../$evalTestWavList','$tempFeatName','"$cepstrumCount"_"$featID"','$filterCount'); exit;\""
                #matlab -nodesktop -nosplash -r "cd scripts/feature_extraction/ ; lfbe_evalData('../../$evalTestWavList','$tempFeatName','"$cepstrumCount"_"$featID"','$filterCount'); exit;"
                echo "LFBE Features are extracted..."
        else
                echo "Feature extraction skipped....! Existing features are used"
        fi
        dirName="$featName"_"$cepstrumCount"_"$featID"
        mkdir -p $wdir/features/"$featName"_"$cepstrumCount"_"$featID"
        mkdir -p $wdir/features/"$featName"_"$cepstrumCount"_"$featID"/$attackType
        echo "mv scripts/feature_extraction/LFBE_"$cepstrumCount"_"$featID"/* $wdir/features/"$featName"_"$cepstrumCount"_"$featID"/"$attackType/
        mv scripts/feature_extraction/LFBE_"$cepstrumCount"_"$featID"/* $featDir

elif [ $featName == "lfcc" ]; then
        echo "featName: $featName ; featID: $featID"
        filterCount=40
        featName1="lfcc_"$cepstrumCount"_"$featID
        tempFeatName=lfcc
        if [ $featExtractFlag == 1 ]; then
                echo "matlab -nodesktop -nosplash -r \"cd scripts/feature_extraction/ ; extract_lfcc_bulk('../../$genuineTrainWavList','/train/bonafide/','$tempFeatName','"$cepstrumCount"_"$featID"','$filterCount'); exit;\""
                matlab -nodesktop -nosplash -r "cd scripts/feature_extraction/ ; extract_lfcc_bulk('../../$genuineTrainWavList','/train/bonafide/','$tempFeatName','"$cepstrumCount"_"$featID"','$filterCount'); exit;"
                echo "matlab -nodesktop -nosplash -r \"cd scripts/feature_extraction/ ; extract_lfcc_bulk('../../$spoofedTrainWavList','/train/spoofed/','$tempFeatName','"$cepstrumCount"_"$featID"','$filterCount'); exit;\""
                matlab -nodesktop -nosplash -r "cd scripts/feature_extraction/ ; extract_lfcc_bulk('../../$spoofedTrainWavList','/train/spoofed/','$tempFeatName','"$cepstrumCount"_"$featID"','$filterCount'); exit;"
                echo "matlab -nodesktop -nosplash -r \"cd scripts/feature_extraction/ ; extract_lfcc_bulk('../../$devTestWavList','/dev/','$tempFeatName','"$cepstrumCount"_"$featID"','$filterCount'); exit;\""
                matlab -nodesktop -nosplash -r "cd scripts/feature_extraction/ ; extract_lfcc_bulk('../../$devTestWavList','/dev/','$tempFeatName','"$cepstrumCount"_"$featID"','$filterCount'); exit;"
                echo "matlab -nodesktop -nosplash -r \"cd scripts/feature_extraction/ ; extract_lfcc_bulk('../../$evalTestWavList','/eval/','$tempFeatName','"$cepstrumCount"_"$featID"','$filterCount'); exit;\""
                matlab -nodesktop -nosplash -r "cd scripts/feature_extraction/ ; extract_lfcc_bulk('../../$evalTestWavList','/eval/','$tempFeatName','"$cepstrumCount"_"$featID"','$filterCount'); exit;"

                echo "LFCC Features are extracted..."
        else
                echo "Feature extraction skipped....! Existing features are used"
        fi
        dirName="$featName"_"$cepstrumCount"_"$featID"
        mkdir -p $wdir/features/"$featName"_"$cepstrumCount"_"$featID"
        mkdir -p $wdir/features/"$featName"_"$cepstrumCount"_"$featID"/$attackType
        echo "mv scripts/feature_extraction/LFCC_"$cepstrumCount"_"$featID"/* $wdir/features/"$featName"_"$cepstrumCount"_"$featID"/"$attackType/
        mv scripts/feature_extraction/LFCC_"$cepstrumCount"_"$featID"/* $featDir

else
        echo "Check  your feature options"
        exit 1
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

find $genuineTrainFeatPath/ -name "*$featName" -maxdepth 1 | sort -u > $genuineTrainFeatPath
find $spoofedTrainFeatPath/ -name "*$featName" -maxdepth 1 | sort -u > $spoofedTrainFeatList
#
#echo find $spoofedTrainFeatPath/ -type f  
#find find $spoofedTrainFeatPath/ -type f  > $spoofedTrainFeatList
find $devTestFeatPath/* -type f > $devTestFeatList
find $evalTestFeatPath/ -type f > $evalTestFeatList

echo "GenuineFeatDir: $genuineTrainFeatPath, SpoofedFeatDir: $spoofedTrainFeatPath, and  devFeatDir: $devTestFeatPath, evalFeatDir: $evalTestFeatPath"
echo "GenuineFeatList: $genuineTrainFeatList, SpoofedFeatList: $spoofedTrainFeatList, and  devFeatList: $devTestFeatList, evalFeatList: $evalTestFeatList"
############################# 2. Prepare lists for train, dev and validation ##########################################
########### 20% of the genuineTrain and spoofedTrain are seggregated as validation dataset ############################
########### Development dataset is used as such for fine tuning the algorithm. ########################################
########### Val-data : is prepared randomly by choosing 20% of files ##################################################

get_seeded_random()
{
  seed="$1"
  openssl enc -aes-256-ctr -pass pass:"$seed" -nosalt \
    </dev/zero 2>/dev/null
}


devWavFilePath=$databasePath$attackType/ASVspoof2019_"$attackType"_dev/wav
echo $databasePath/$attackType/ASVspoof2019_"$attackType"_dev/wav
cp $devTestWavList dev_"$featName"_"$exp_name"_header.txt
#sed -i 's!data/ASV_spoof_2019/'$attackType'/ASVspoof2019_'$attackType'_dev/wav/!features/imfs_70Filters_S/'$attackType'/dev/'! dev_"$featName"_"$exp_name"_header.txt
#sed -i 's!data/ASV_spoof_2019/'$attackType'/ASVspoof2019_'$attackType'_dev/wav/!features/'$dirName'/'$attackType'/dev/'! dev_"$featName"_"$exp_name"_header.txt
sed -i 's!\.wav!\.'$featName'!' dev_"$featName"_"$exp_name"_header.txt
sed -i 's!'$devWavFilePath'!'$featDir'/dev/!' dev_"$featName"_"$exp_name"_header.txt
echo sed -i 's!'$devWavFilePath'!'$featDir'/dev/!' dev_"$featName"_"$exp_name"_header.txt

cp dev_"$featName"_"$exp_name"_header.txt $devTestFeatList
 
devFileCount=`cat "$devTestFeatList" | wc -l`
valLmt=`echo $devFileCount | awk '{print $1*0.5}'`


shuf -i1-$devFileCount --random-source=<(get_seeded_random 1) | sort -u > tmp1."$exp_name".$featName.$attackType.rand ### 516 is 20% of 2580 genuine train trials

#rm trainVal_gen_"$featName"_$attackType.lst trainVal_spf_"$featName"_$attackType.lst
rm trainVal_"$featName"_"$exp_name"_header.txt
for i in `seq 1 1 $valLmt`
do
    ( curRandomNum=`less tmp1."$exp_name".$featName.$attackType.rand | head -$i | tail -1` 
	filePath=`less $devTestFeatList | head -$curRandomNum | tail -1`  
    fileLable=`less $devCMGroundTruth | head -$curRandomNum | tail -1 | cut -d' ' -f5` 
    echo $filePath $fileLable >> trainVal_"$featName"_"$exp_name"_header.txt ) &
done
wait
#lines=`less trainVal_gen_"$featName"_$attackType.lst | wc -l`
#echo "trainVal_gen_"$featName"_$attackType.lst generated and has $lines lines"

#lines=`less trainVal_spf_"$featName"_$attackType.lst | wc -l `
#echo "trainVal_spf_"$featName"_$attackType.lst generated and has $lines lines"



########################################################################################################################
#less trainVal_gen_"$featName"_"$attackType".lst | sort -u > tmp."$exp_name".$featName.txt
#mv tmp."$exp_name".$featName.txt trainVal_gen_"$featName"_"$attackType".lst

#less trainVal_spf_"$featName"_"$attackType".lst | sort -u > tmp."$exp_name".$featName.txt
#mv tmp."$exp_name".$featName.txt trainVal_spf_"$featName"_"$attackType".lst

cat $genuineTrainFeatList  > tmp1."$exp_name".$featName.txt
cat $spoofedTrainFeatList  >> tmp1."$exp_name".$featName.txt
mv tmp1."$exp_name".$featName.txt trainAlone.$featName.txt

less trainAlone.$featName.txt | parallel -v "wc -l {1}" | grep -v "wc " | sort -n | cut -d ' ' -f2 > train_"$featName"_"$exp_name"_header.txt
#less trainVal_gen_"$featName"_"$attackType".lst trainVal_spf_"$featName"_"$attackType".lst > trainVal_"$featName"_"$exp_name"_header.txt

#wc -l trainVal_gen_"$featName"_"$attackType".lst trainVal_spf_"$featName"_"$attackType".lst trainAlone.$featName.txt trainVal_"$featName"_"$exp_name"_header.txt



#sed -i 's!spoofed/!/!' dev_"$featName"_"$exp_name"_header.txt
#sed -i 's!bonafide/!/!' dev_"$featName"_"$exp_name"_header.txt

evalWavFilePath=$databasePath$attackType/ASVspoof2019_"$attackType"_eval/wav
cp $evalTestWavList eval_"$featName"_"$exp_name"_header.txt
sed -i 's!\.wav!\.'$featName'!' eval_"$featName"_"$exp_name"_header.txt
sed -i 's!'$evalWavFilePath'!'$featDir'/eval/!' eval_"$featName"_"$exp_name"_header.txt

export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6
export LD_LIBRARY_PATH=/usr/local/cuda/lib64
export CUDA_VISIBLE_DEVICES="0"
echo "python3 scripts/xvectors_naive_asv2019_LA_devData_equal_batch.py modelDir/"$exp_name" $testNNFlag  0 resultFile_"$exp_name".txt train_"$featName"_"$exp_name"_header.txt trainVal_"$featName"_"$exp_name"_header.txt dev_"$featName"_"$exp_name"_header.txt" eval_"$featName"_"$exp_name"_header.txt
python3 scripts/xvectors_naive_asv2019_LA_devData_equal_batch.py modelDir/"$exp_name" $testNNFlag  0 resultFile_"$exp_name".txt train_"$featName"_"$exp_name"_header.txt trainVal_"$featName"_"$exp_name"_header.txt dev_"$featName"_"$exp_name"_header.txt eval_"$featName"_"$exp_name"_header.txt
export LD_PRELOAD=""
export LD_LIBRARY_PATH=""

################################## STEP - 3: Calculate Dev EER ##################################################

resultFile=dev_resultFile_"$exp_name".txt

###LA_D_9967770 spoof -0.67486644 LA_0078 LA_D_9967770 - VC_4 spoof
cmScoreFile=dev_scoreFile_"$exp_name".txt
echo paste -d ' ' $resultFile $devCMGroundTruth | awk '{if($1==$5) print $1" "$7" "$8" "$3}' > $cmScoreFile

paste -d ' ' $resultFile $devCMGroundTruth | awk '{if($1==$5) print $1" "$7" "$8" "$3}' > $cmScoreFile

rm output.$featName.txt
echo "matlab -nodesktop -nosplash -r \"cd library/evaluvation/tDCF_v1/ ; evaluate_tDCF_asvspoof19('../../../$cmScoreFile','../../../$devASVScoreFile'); exit;\""
matlab -nodesktop -nosplash -r "cd library/evaluvation/tDCF_v1/ ; evaluate_tDCF_asvspoof19('../../../$cmScoreFile','../../../$devASVScoreFile'); exit;" >> output.$featName.txt
tDCF=`less output.$featName.txt | grep "min-tDCF" | cut -d '=' -f2`
spkrEER=`less output.$featName.txt | grep "EER" | head -1 | cut -d '=' -f2 | cut -d '%' -f1`
spfEER=`less output.$featName.txt | grep "EER" | tail -1 | cut -d '=' -f2 | cut -d '%' -f1`
echo ""

### LA_D_9935163 spoof -0.49706092 LA_0078 LA_D_9935163 - VC_4 spoof
paste -d ' ' $resultFile $devCMGroundTruth > tmp1."$exp_name".$featName
#awk '{if($4>=0.0) {print $0" bonafide"} else {print $0" spoof"}}' tmp1 > tmp2
trialCount=`less $devCMGroundTruth | wc -l`
acc=`awk -F' ' -v hits=0 -v miss=0 -v trialCount=$trialCount '{if($1==$5 && $2==$8) {hits=hits+1} else {miss=miss+1}} END {print "hits="hits" ; miss="miss" ; acc=" (hits/trialCount)*100}' tmp1."$exp_name".$featName`
echo "HL1:$hLayer1 HL2:$hLayer2 xVecDim:$xvectorDim  feat:$featName featID:"$cepstrumCount"$featID ========> spkrEER: $spkrEER ; spfEER: $spfEER ; t-DCF=$tDCF ; Acc: $acc" 
echo "HL1:$hLayer1 HL2:$hLayer2 xVecDim:$xvectorDim  feat:$featName featID:"$cepstrumCount"$featID ========> spkrEER: $spkrEER ; spfEER: $spfEER ; t-DCF=$tDCF ; Acc: $acc" >> dev_$logFile
echo ""

mkdir dev_score_files
mv dev_scoreFile_"$exp_name".txt dev_score_files/dev_scoreFile_"$exp_name".txt

mkdir dev_result_files
mv dev_resultFile_"$exp_name".txt dev_result_files/dev_resultFile_"$exp_name".txt


################################## STEP - 3: Calculate Eval EER ##################################################

resultFile=eval_resultFile_"$exp_name".txt

###LA_D_9967770 spoof -0.67486644 LA_0078 LA_D_9967770 - VC_4 spoof
cmScoreFile=eval_scoreFile_"$exp_name".txt
echo paste -d ' ' $resultFile $evalCMGroundTruth | awk '{if($1==$5) print $1" "$7" "$8" "$3}' > $cmScoreFile

paste -d ' ' $resultFile $evalCMGroundTruth | awk '{if($1==$5) print $1" "$7" "$8" "$3}' > $cmScoreFile

rm output.$featName.txt
echo "matlab -nodesktop -nosplash -r \"cd library/evaluvation/tDCF_v1/ ; evaluate_tDCF_asvspoof19('../../../$cmScoreFile','../../../$evalASVScoreFile'); exit;\""
matlab -nodesktop -nosplash -r "cd library/evaluvation/tDCF_v1/ ; evaluate_tDCF_asvspoof19('../../../$cmScoreFile','../../../$evalASVScoreFile'); exit;" >> output.$featName.txt
tDCF=`less output.$featName.txt | grep "min-tDCF" | cut -d '=' -f2`
spkrEER=`less output.$featName.txt | grep "EER" | head -1 | cut -d '=' -f2 | cut -d '%' -f1`
spfEER=`less output.$featName.txt | grep "EER" | tail -1 | cut -d '=' -f2 | cut -d '%' -f1`
echo ""

### LA_D_9935163 spoof -0.49706092 LA_0078 LA_D_9935163 - VC_4 spoof
paste -d ' ' $resultFile $evalCMGroundTruth > tmp1."$exp_name".$featName
#awk '{if($4>=0.0) {print $0" bonafide"} else {print $0" spoof"}}' tmp1 > tmp2
trialCount=`less $evalCMGroundTruth | wc -l`
acc=`awk -F' ' -v hits=0 -v miss=0 -v trialCount=$trialCount '{if($1==$5 && $2==$8) {hits=hits+1} else {miss=miss+1}} END {print "hits="hits" ; miss="miss" ; acc=" (hits/trialCount)*100}' tmp1."$exp_name".$featName`
echo "HL1:$hLayer1 HL2:$hLayer2 xVecDim:$xvectorDim  feat:$featName featID:"$cepstrumCount"$featID ========> spkrEER: $spkrEER ; spfEER: $spfEER ; t-DCF=$tDCF ; Acc: $acc" 
echo "HL1:$hLayer1 HL2:$hLayer2 xVecDim:$xvectorDim  feat:$featName featID:"$cepstrumCount"$featID ========> spkrEER: $spkrEER ; spfEER: $spfEER ; t-DCF=$tDCF ; Acc: $acc" >> eval_$logFile
echo ""

mkdir eval_score_files
mv eval_scoreFile_"$exp_name".txt eval_score_files/eval_scoreFile_"$exp_name".txt

mkdir eval_result_files
mv eval_resultFile_"$exp_name".txt eval_result_files/dev_resultFile_"$exp_name".txt





################################## STEP - 3: Delete unwanted files ##################################################
rm -rf tmp."$exp_name".*
rm -rf tmp1."$exp_name".*
rm -f *.lst
rm -rf trainVal_"$featName"_"$exp_name"_header.txt train_"$featName"_"$exp_name"_header.txt dev_"$featName"_"$exp_name"_header.txt eval_"$featName"_"$exp_name"_header.txt
