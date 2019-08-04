function a =inverseMelFilterBanks_evalData(testWavList,featName1,featID0,filterCount1)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BTAS 2016 Dataset: % Audio replay detection challenge for automatic speaker verification anti-spoofing
% 
% ====================================================================================
% Matlab implementation of the baseline system for replay detection based
% on constant Q cepstral coefficients (CQCC) features 
% ====================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%clc; clear all; close all;
t = cputime;
% add required libraries to the path
addpath(genpath('utility'));
addpath(genpath('bosaris_toolkit'));


% genuineTrainWavList = fullfile('../lists/train_genuine_wav.lst');
% spoofedTrainWavList = fullfile('../lists/train_replay_wav.lst');
% testWavList = fullfile('../lists/evalData_all_wav.lst');
% featName1='imfbe'
% featID0='10Filters_S'
windowLength=25;
nFFT=512;

% % set paths to the wave files and protocols
evalProtocolFile = testWavList;
featName=featName1;
tempvar=upper(featName1);
cepstrumCount=str2double(featID0(1:2));
parentDir=strcat(tempvar,'_',featID0);
featID1=featID0;
filterCount=str2double(featID1(1:2));
a=strsplit(featID0,'_');
featureType=a(2);

%% Feature extraction and scoring of evaluation data
fileID = fopen(evalProtocolFile);
evalProtocol = textscan(fileID, '%s');
fclose(fileID);

evalFileList = evalProtocol{1};

evalDirectoryNameList='../lists/evalData_directoryNames.lst';
fileID_writeD = fopen(evalDirectoryNameList);
evalDirectoryNames = textscan(fileID_writeD, '%s');
fclose(fileID_writeD);
evalDirCount=length(evalDirectoryNames{1});
pathToEvalFeatures=fullfile(parentDir,'eval');
for j=1:evalDirCount
    tempDirName=evalDirectoryNames{1}{j};
    fullName=fullfile(pathToEvalFeatures,'..',tempDirName);
    mkdir(fullName)
end

scores = zeros(size(evalFileList));
disp('Extracting/writing features for  evaluation trials...');
evalFeatureCell = cell(size(evalFileList));
parfor i=1:length(evalFileList)
    filePath = fullfile(evalFileList{i});
    filePathSplit = strsplit(filePath,'/');
    wavName = filePathSplit(end);
    fileNameSplit = strsplit(wavName{1},'.');
    fileName = fileNameSplit(1);

    [x,fs] = audioread(filePath);
    [statD,deltaD,double_deltaD]=extract_imfs(x,fs,windowLength,nFFT,filterCount,cepstrumCount);
    if ( string(featureType{1})  == 'S' )
        %disp('only S');
        evalFeatureCell{i} =[statD];
    elseif ( string(featureType{1})  == 'SD' )
        %disp('only SD');
        evalFeatureCell{i} =[statD deltaD];
    elseif ( string(featureType{1})  == 'SDA' )
        %disp('only SDA');
        evalFeatureCell{i} =[statD deltaD double_deltaD];
    elseif ( string(featureType{1})  == 'DA' )
        %disp('only DA');
        evalFeatureCell{i} =[deltaD double_deltaD];
    elseif ( string(featureType{1})  == 'SA' )
        %disp('only SA');
        evalFeatureCell{i} =[statD double_deltaD];
    end
	var=evalFeatureCell{i};
	filePath1 = fullfile(pathToEvalFeatures,strcat(fileName{1},'.imfs'));
	dlmwrite(filePath1,var,'delimiter',' ','precision','%.6f');
end
clear evalFeatureCell;

end

