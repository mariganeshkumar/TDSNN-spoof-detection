##	Control file, input file and output file arguments are mandatory
##	extractlfs [options]
##	v: vadtype 0 = none, 1 = threshold, 2 = tgmm, 3 = transcript
##	t: threshold scale
##	b: transcript name
##	g: trigaussian file
##	d: compute delta
##	a: compute acceleration
##	c: control file
##	i: input wave file
##	o: output wavefile
##	r: use this to set channel
## 	s: save output in binary format

#variable_declaration

if [ $# != 3 ]; then
	echo "Arg1: featureDirName"
	echo "Arg2: feature ID (S/SD/SDA)"
	echo "Arg3: attackType"
	exit
fi

wdir=.
executable=$wdir/bin/extractmfs
configFile=$wdir/conf/fe-ctrl.base.lfs
feature=lfs
featDir=$wdir/features/
featDir1=$featDir/$1
featID=$2
attackType=$3

echo "---------- Experiment : MFS Extraction ---------"
echo "result_folder: $result_folder"
echo "executable_file : $executable"
echo "config_file : $config_file"
echo "input_file : $input_file"

#FEATURE EXTRACTION
# -----------------------
# COMMAND FORMAT:
#	
# less $InputFileList | parallel -v -j20 $Executable -v vadType -t thresholdValue -d delta -i inputFile -o outputFile -r channel -c ConfigFile
if [ ! -d "$featDir1" ]; then
    mkdir $featDir1
    mkdir $featDir1/$attackType
fi

if [ ! -d "$featDir1/$attackType" ]; then
    mkdir $featDir1/$attackType

fi

featDir2=$featDir1/$attackType
mkdir $featDir2/dev
mkdir $featDir2/dev/bonafide
mkdir $featDir2/dev/spoofed
mkdir $featDir2/train
mkdir $featDir2/train/bonafide
mkdir $featDir2/train/spoofed
mkdir $featDir2/eval

genuineTrainWavList=lists/asv2019_"$attackType"_genuineTrain_wav.lst
spoofedTrainWavList=lists/asv2019_"$attackType"_spoofedTrain_wav.lst
devTestWavList=lists/asv2019_"$attackType"_dev_wav.lst
evalTestWavList=lists/asv2019_"$attackType"_eval_wav.lst

if [ $featID == "S" ]; then 
	echo "less $genuineTrainWavList | parallel -v -j20 --dryrun $executable  -v 1 -t 0.06 -i {1} -o $featDir2/train/bonafide/{1/.}.lfs -r A -c $configFile | head -2"
	less $genuineTrainWavList | parallel -v -j20 $executable  -v 1 -t 0.06 -i {1} -o $featDir2/train/bonafide/{1/.}.lfs -r A -c $configFile
	echo "less $spoofedTrainWavList | parallel -v -j20 --dryrun $executable  -v 1 -t 0.06 -i {1} -o $featDir2/train/spoofed/{1/.}.lfs -r A -c $configFile | head -2"
	less $spoofedTrainWavList | parallel -v -j20 $executable  -v 1 -t 0.06 -i {1} -o $featDir2/train/spoofed/{1/.}.lfs -r A -c $configFile
	echo "less $devTestWavList | grep "bonafide" | parallel -v -j20 --dryrun $executable  -v 1 -t 0.06 -i {1} -o $featDir2/dev/bonafide/{1/.}.lfs -r A -c $configFile | head -2"
	less $devTestWavList | grep "bonafide" | parallel -v -j20 $executable  -v 1 -t 0.06 -i {1} -o $featDir2/dev/bonafide/{1/.}.lfs -r A -c $configFile
	echo "less $devTestWavList | grep "spoofed" | parallel -v -j20 --dryrun $executable  -v 1 -t 0.06 -i {1} -o $featDir2/dev/spoofed/{1/.}.lfs -r A -c $configFile | head -2"
	less $devTestWavList | grep "spoofed" | parallel -v -j20 $executable  -v 1 -t 0.06 -i {1} -o $featDir2/dev/spoofed/{1/.}.lfs -r A -c $configFile
#	echo "less $wdir/lists/evalData_wav.lst | parallel -v -j20 --dryrun $executable  -v 1 -t 0.06 -i {1} -o $featDir2/eval/{1/.}.lfs -r A -c $configFile | head -2"
#	less $wdir/lists/evalData_wav.lst | parallel -v -j20 $executable -v 1 -t 0.06 -i {1} -o $featDir2/eval/{1/.}.lfs -r A -c $configFile

elif [ $featID == "SD" ]; then
	echo "less $genuineTrainWavList | parallel -v -j20 --dryrun $executable  -v 1 -d -t 0.06 -i {1} -o $featDir2/train/bonafide/{1/.}.lfs -r A -c $configFile | head -2"
	less $genuineTrainWavList | parallel -v -j20 $executable  -v 1 -d -t 0.06 -i {1} -o $featDir2/train/bonafide/{1/.}.lfs -r A -c $configFile
	echo "less $spoofedTrainWavList | parallel -v -j20 --dryrun $executable  -v 1 -d -t 0.06 -i {1} -o $featDir2/train/spoofed/{1/.}.lfs -r A -c $configFile | head -2"
	less $spoofedTrainWavList | parallel -v -j20 $executable  -v 1 -d -t 0.06 -i {1} -o $featDir2/train/spoofed/{1/.}.lfs -r A -c $configFile
	echo "less $devTestWavList | grep "bonafide" | parallel -v -j20 --dryrun $executable  -v 1 -d -t 0.06 -i {1} -o $featDir2/dev/bonafide/{1/.}.lfs -r A -c $configFile | head -2"
	less $devTestWavList | grep "bonafide" | parallel -v -j20 $executable  -v 1 -d -t 0.06 -i {1} -o $featDir2/dev/bonafide/{1/.}.lfs -r A -c $configFile
	echo "less $devTestWavList | grep "spoofed" | parallel -v -j20 --dryrun $executable  -v 1 -d -t 0.06 -i {1} -o $featDir2/dev/spoofed/{1/.}.lfs -r A -c $configFile | head -2"
	less $devTestWavList | grep "spoofed" | parallel -v -j20 $executable  -v 1 -d -t 0.06 -i {1} -o $featDir2/dev/spoofed/{1/.}.lfs -r A -c $configFile
#	echo "less $wdir/lists/evalData_wav.lst | parallel -v -j20 --dryrun $executable  -v 1 -d -t 0.06 -i {1} -o $featDir2/eval/{1/.}.lfs -r A -c $configFile | head -2"
#	less $wdir/lists/evalData_wav.lst | parallel -v -j20 $executable -v 1 -d -t 0.06 -i {1} -o $featDir2/eval/{1/.}.lfs -r A -c $configFile

elif [ $featID == "SDA" ]; then
        echo "less $genuineTrainWavList | parallel -v -j20 --dryrun $executable  -v 1 -d -a -t 0.06 -i {1} -o $featDir2/train/bonafide/{1/.}.lfs -r A -c $configFile | head -2"
        less $genuineTrainWavList | parallel -v -j20 $executable  -v 1 -d -a -t 0.06 -i {1} -o $featDir2/train/bonafide/{1/.}.lfs -r A -c $configFile
        echo "less $spoofedTrainWavList | parallel -v -j20 --dryrun $executable  -v 1 -d -a -t 0.06 -i {1} -o $featDir2/train/spoofed/{1/.}.lfs -r A -c $configFile | head -2"
        less $spoofedTrainWavList | parallel -v -j20 $executable  -v 1 -d -a -t 0.06 -i {1} -o $featDir2/train/spoofed/{1/.}.lfs -r A -c $configFile
	echo "less $devTestWavList | grep "bonafide" | parallel -v -j20 --dryrun $executable  -v 1 -d -a -t 0.06 -i {1} -o $featDir2/dev/bonafide/{1/.}.lfs -r A -c $configFile | head -2"
	less $devTestWavList | grep "bonafide" | parallel -v -j20 $executable  -v 1 -d -a -t 0.06 -i {1} -o $featDir2/dev/bonafide/{1/.}.lfs -r A -c $configFile
	echo "less $devTestWavList | grep "spoofed" | parallel -v -j20 --dryrun $executable  -v 1 -d -a -t 0.06 -i {1} -o $featDir2/dev/spoofed/{1/.}.lfs -r A -c $configFile | head -2"
	less $devTestWavList | grep "spoofed" | parallel -v -j20 $executable  -v 1 -d -a -t 0.06 -i {1} -o $featDir2/dev/spoofed/{1/.}.lfs -r A -c $configFile
#        echo "less $wdir/lists/evalData_wav.lst | parallel -v -j20 --dryrun $executable  -v 1 -d -a -t 0.06 -i {1} -o $featDir2/eval/{1/.}.lfs -r A -c $configFile | head -2"
#        less $wdir/lists/evalData_wav.lst | parallel -v -j20 $executable -v 1 -d -a -t 0.06 -i {1} -o $featDir2/eval/{1/.}.lfs -r A -c $configFile

else
	echo "Check the featID $featID"
	exit -1
fi

