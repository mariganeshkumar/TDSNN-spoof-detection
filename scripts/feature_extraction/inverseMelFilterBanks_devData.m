function a =inverseMelFilterBanks_devData(genuineTrainWavList,spoofedTrainWavList,testWavList,featName1,featID0,filterCount1)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BTAS 2016 Dataset: % Audio replay detection challenge for automatic speaker verification anti-spoofing
% 
% ====================================================================================
% Matlab implementation of the baseline system for replay detection based
% on constant Q cepstral coefficients (CQCC) features 
% ====================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%clc; clear all; close all;
t = cputime
% add required libraries to the path
addpath(genpath('utility'));
addpath(genpath('bosaris_toolkit'));


% genuineTrainWavList = fullfile('../lists/train_genuine_wav.lst');
% spoofedTrainWavList = fullfile('../lists/train_replay_wav.lst');
% testWavList = fullfile('../lists/devData_all_wav.lst');
% featName1='imfbe'
% featID0='10Filters_S'
windowLength=25;
nFFT=512;

% % set paths to the wave files and protocols
genuineTrainProtocolFile = genuineTrainWavList;
replayTrainProtocolFile =spoofedTrainWavList;
devProtocolFile = testWavList;
featName=featName1;
tempvar=upper(featName1);
cepstrumCount=str2double(featID0(1:2));
parentDir=strcat(tempvar,'_',featID0);
featID1=featID0;
filterCount=str2double(featID1(1:2));
a=strsplit(featID0,'_');
featureType=a(2)

%% read genuine train protocol
fileID = fopen(genuineTrainProtocolFile);
genuineProtocol = textscan(fileID, '%s');
fclose(fileID);

%% get file and label lists
genuineFileList = genuineProtocol{1};

%% Feature extraction for training data

%% Creating Directories
genuineDirectoryNameList='../lists/genuineTrain_directoryNames.lst';
fileID_writeG = fopen(genuineDirectoryNameList);
genuineDirectoryNames = textscan(fileID_writeG, '%s');
fclose(fileID_writeG);
genuineDirCount=length(genuineDirectoryNames{1});
pathToGenuineTrainFeatFiles=fullfile(parentDir);
for j=1:genuineDirCount
    tempDirName=genuineDirectoryNames{1}{j};
    fullName=fullfile(pathToGenuineTrainFeatFiles,tempDirName);
    mkdir(fullName);
end

%% extract features for GENUINE training data and store in cell array
disp('Extracting/writing features for GENUINE training data...');
size(genuineFileList)
genuineFeatureCell = cell(size(genuineFileList));
parfor i=1:length(genuineFileList);
    filePath = fullfile('..',genuineFileList{i});
    filePathSplit = strsplit(filePath,'/');
    wavName = filePathSplit(end);
    fileNameSplit = strsplit(wavName{1},'.');
    fileName = fileNameSplit(1);

    [x,fs] = audioread(filePath);
    [statG,deltaG,double_deltaG]=extract_imfs(x,fs,windowLength,nFFT,filterCount,cepstrumCount) ;

    if ( string(featureType{1}) == 'S' )
        %disp('only S');
        genuineFeatureCell{i} =[statG];
    elseif ( string(featureType{1}) == 'SD' )
        %disp('only SD');
        genuineFeatureCell{i} =[statG deltaG];
    elseif ( string(featureType{1}) == 'SDA' )
        %disp('only SDA');
        genuineFeatureCell{i} =[statG deltaG double_deltaG];
    elseif ( string(featureType{1}) == 'DA' )
        %disp('only DA');
        genuineFeatureCell{i} =[deltaG double_deltaG];        
    elseif ( string(featureType{1}) == 'SA' )
        %disp('only SA');
        genuineFeatureCell{i} =[statG double_deltaG];     
    end
    var=genuineFeatureCell{i};
%	filePath1=fullfile('..','dummy.imfs');
    filePath1 = fullfile(pathToGenuineTrainFeatFiles,'train/bonafide',strcat(fileName{1},'.imfs'));
    dlmwrite(filePath1,var,'delimiter',' ','precision','%.6f');

end
disp('Done!');
clear genuineFeatureCell;

%% read replayed train protocol
fileID = fopen(replayTrainProtocolFile);
replayProtocol = textscan(fileID, '%s');
fclose(fileID);

%% get file and label lists
replayFileList = replayProtocol{1};

disp('Creating directories for replay trials');
replayDirectoryNameList='../lists/genuineTrain_directoryNames.lst';
fileID_writeR = fopen(replayDirectoryNameList);
replayDirectoryNames = textscan(fileID_writeR, '%s');
fclose(fileID_writeR);
replayDirCount=length(replayDirectoryNames{1});
pathToReplayTrainFeatFiles=fullfile(parentDir);
for j=1:replayDirCount
    tempDirName=replayDirectoryNames{1}{j};
    fullName=fullfile(pathToReplayTrainFeatFiles,tempDirName);
    mkdir(fullName);
end

% extract features for SPOOF training data and store in cell array
disp('Extracting features for SPOOF training data...');
spoofFeatureCell = cell(size(replayFileList));
parfor i=1:length(replayFileList)
    filePath = fullfile('..',replayFileList{i});
    filePathSplit = strsplit(filePath,'/');
    wavName = filePathSplit(end);
    fileNameSplit = strsplit(wavName{1},'.');
    fileName = fileNameSplit(1);

    [x,fs] = audioread(filePath);
    [statR,deltaR,double_deltaR]=extract_imfs(x,fs,windowLength,nFFT,filterCount,cepstrumCount) ;
    if ( string(featureType{1})  == 'S' )
        %disp('only S');
        spoofFeatureCell{i} =[statR];
    elseif ( string(featureType{1})  == 'SD' )
        %disp('only SD');
        spoofFeatureCell{i} =[statR deltaR];
    elseif ( string(featureType{1})  == 'SDA' )
        %disp('only SDA');
        spoofFeatureCell{i} =[statR deltaR double_deltaR];
    elseif ( string(featureType{1})  == 'DA' )
        %disp('only DA');
        spoofFeatureCell{i} =[deltaR double_deltaR];
    elseif ( string(featureType{1})  == 'SA' )
        %disp('only SA');
        spoofFeatureCell{i} =[statR double_deltaR];
    end

    var=spoofFeatureCell{i};
    filePath1 = fullfile(pathToReplayTrainFeatFiles,'train/spoofed',strcat(fileName{1},'.imfs'));
    dlmwrite(filePath1,var,'delimiter',' ','precision','%.6f');
end
disp('Done!');
clear spoofFeatureCell;

%% Feature extraction and scoring of development data
fileID = fopen(devProtocolFile);
devProtocol = textscan(fileID, '%s');
fclose(fileID);

devFileList = devProtocol{1};

devDirectoryNameList='../lists/devData_directoryNames.lst';
fileID_writeD = fopen(devDirectoryNameList);
devDirectoryNames = textscan(fileID_writeD, '%s');
fclose(fileID_writeD);
devDirCount=length(devDirectoryNames{1});
pathToDevFeatures=fullfile(parentDir,'dev');
for j=1:devDirCount
    tempDirName=devDirectoryNames{1}{j};
    fullName=fullfile(pathToDevFeatures,'..',tempDirName);
    mkdir(fullName)
end

scores = zeros(size(devFileList));
disp('Extracting/writing features for  development trials...');
devFeatureCell = cell(size(devFileList));
parfor i=1:length(devFileList)
    filePath = fullfile('..',devFileList{i});
    filePathSplit = strsplit(filePath,'/');
    wavName = filePathSplit(end);
    fileNameSplit = strsplit(wavName{1},'.');
    fileName = fileNameSplit(1);
    spfFlag=isempty(strfind(filePath, '/spoofed/')) %% Will return 0 if match is found
    [x,fs] = audioread(filePath);
    [statD,deltaD,double_deltaD]=extract_imfs(x,fs,windowLength,nFFT,filterCount,cepstrumCount);
    if ( string(featureType{1})  == 'S' )
        %disp('only S');
        devFeatureCell{i} =[statD];
    elseif ( string(featureType{1})  == 'SD' )
        %disp('only SD');
        devFeatureCell{i} =[statD deltaD];
    elseif ( string(featureType{1})  == 'SDA' )
        %disp('only SDA');
        devFeatureCell{i} =[statD deltaD double_deltaD];
    elseif ( string(featureType{1})  == 'DA' )
        %disp('only DA');
        devFeatureCell{i} =[deltaD double_deltaD];
    elseif ( string(featureType{1})  == 'SA' )
        %disp('only SA');
        devFeatureCell{i} =[statD double_deltaD];
    end
	var=devFeatureCell{i};
        if (spfFlag==0)
                filePath1 = fullfile(pathToDevFeatures,'spoofed',strcat(fileName{1},'.imfs'))
        else
                filePath1 = fullfile(pathToDevFeatures,'bonafide',strcat(fileName{1},'.imfs'))
        end
	dlmwrite(filePath1,var,'delimiter',' ','precision','%.6f');
end
disp('Done!');
clear devFeatureCell;
end
