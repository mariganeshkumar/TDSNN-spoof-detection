function EER=getEER(scoreFile)    


%% add required libraries to the path
addpath(genpath('utility'));
addpath(genpath('bosaris_toolkit'));   

%% Variable initialization
scoreFileName=scoreFile;
%scoreFileName = fullfile('../resultFile_cqcc_13ZSDA');
fileID1 = fopen(scoreFileName);
scoreFile = textscan(fileID1,'%s%s');

%Read scores1 as array from the cell
scores1=zeros(size(scoreFile));
scores1=dlmread(scoreFileName, ' ', 0, 1);

%% read development protocol
devProtocolFile = fullfile('../data/protocol_V2/ASVspoof2017_V2_eval.trl.txt');
fileID = fopen(devProtocolFile);
protocol = textscan(fileID, '%s%s%s%s%s%s%s');
fclose(fileID);

%% get file and label lists
filelist = protocol{1};
labels = protocol{2};

%% get indices of genuine and spoof files
genuineIdx = find(strcmp(labels,'genuine'));
spoofIdx = find(strcmp(labels,'spoof'));

%% Read each development trial's feature and do scoring

addpath(genpath('bosaris_toolkit'));
[Pmiss,Pfa] = rocch(scores1(strcmp(labels,'genuine')),scores1(strcmp(labels,'spoof')));
EER = rocch2eer(Pmiss,Pfa) * 100; 
fprintf('EER is %.2f\n', EER);

save('Pmiss_cqcc.txt','Pmiss','-ascii')
save('Pfa_cqcc.txt','Pfa','-ascii')

end
