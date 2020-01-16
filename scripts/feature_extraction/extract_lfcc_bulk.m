function a =extract_lfcc_bulk(WavList,dirName,featName1,featID0,filterCount1)
%
% Modified by Mari on 6-Aug-2019
%
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
addpath(genpath('../../library/ASVspoof_2019_baseline_CM_v1'));
addpath(genpath('utility'));
addpath(genpath('bosaris_toolkit'));


windowLength=20;
nFFT=512;

% % set paths to the wave files and protocols
featName=featName1;
tempvar=upper(featName1);
cepstrumCount=str2double(featID0(1:2));
parentDir=strcat(tempvar,'_',featID0);
featID1=featID0;
filterCount=str2double(filterCount1);
a=strsplit(featID0,'_');
featureType=a(2)

%% read genuine train protocol
disp(WavList)
fileID = fopen(WavList);
fileList = textscan(fileID, '%s');
fclose(fileID);

%% get file and label lists
fileList = fileList{1};

%% Feature extraction 

%% Creating Directories
pathToFeatFiles=fullfile(parentDir);
fullName=fullfile(pathToFeatFiles,dirName);
mkdir(fullName);


%% extract features for GENUINE training data and store in cell array
disp('Extracting/writing features for GENUINE training data...');
size(fileList)
featureCell = cell(size(fileList));
parfor i=1:length(fileList);
    filePath = fullfile('../../',fileList{i});
    filePathSplit = strsplit(filePath,'/');
    wavName = filePathSplit(end);
    fileNameSplit = strsplit(wavName{1},'.');
    fileName = fileNameSplit(1);
    [x,fs] = audioread(filePath);
    [statG,deltaG,double_deltaG]=extract_lfcc(x,fs,windowLength,nFFT,filterCount,cepstrumCount);

    if ( string(featureType{1}) == 'S' )
        %disp('only S');
        featureCell{i} =[statG];
    elseif ( string(featureType{1}) == 'SD' )
        %disp('only SD');
        featureCell{i} =[statG deltaG];
    elseif ( string(featureType{1}) == 'SDA' )
        %disp('only SDA');
        featureCell{i} =[statG deltaG double_deltaG];
    elseif ( string(featureType{1}) == 'DA' )
        %disp('only DA');
        featureCell{i} =[deltaG double_deltaG];        
    elseif ( string(featureType{1}) == 'SA' )
        %disp('only SA');
        featureCell{i} =[statG double_deltaG];     
    end
    var=featureCell{i};
    header=size(var');
%    filePath1 = fullfile('..','dummy.lfcc');
    filePath1 = fullfile(pathToFeatFiles,dirName,strcat(fileName{1},'.lfcc'));
    dlmwrite(filePath1,header,'delimiter',' ','precision','%d');
    dlmwrite(filePath1,var,'-append','newline','unix','delimiter',' ','precision','%.6f');

end
disp('Done!');
clear featureCell;

end
