function EER=getEER(scoreFile)    


%% add required libraries to the path
addpath(genpath('../baseline_CM/utility'));
addpath(genpath('../baseline_CM/bosaris_toolkit'));   

%% Variable initialization
scoreFileName=scoreFile;
%scoreFileName = fullfile('../resultFile_cqcc_13ZSDA');
fileID1 = fopen(scoreFileName);
scoreFile = textscan(fileID1,'%s%s');

%Read scores1 as array from the cell
scores1=zeros(size(scoreFile));
scores1=dlmread(scoreFileName, ' ', 0, 1);

%% read development protocol
devProtocolFile = fullfile('../data/ASV_spoof_2019/LA/ASVspoof2019_LA_protocols/ASVspoof2019.LA.cm.dev.trl.txt');
fileID = fopen(devProtocolFile);
protocol = textscan(fileID, '%s%s%s%s%s');
fclose(fileID);

%% get file and label lists
filelist = protocol{2};
labels = protocol{5};

%% get indices of bonafide and spoof files
bonafideIdx = find(strcmp(labels,'bonafide'));
spoofIdx = find(strcmp(labels,'spoof'));

%% Read each development trial's feature and do scoring

[Pmiss,Pfa] = rocch(scores1(strcmp(labels,'bonafide')),scores1(strcmp(labels,'spoof')));
EER = rocch2eer(Pmiss,Pfa) * 100; 
fprintf('EER is %.2f\n', EER);

save('Pmiss_cqcc.txt','Pmiss','-ascii');
save('Pfa_cqcc.txt','Pfa','-ascii');

[maxVal,maxIndex]=max(scores1);
[minVal,minIndex]=min(scores1);

end
