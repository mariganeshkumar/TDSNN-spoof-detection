function [stat,delta,double_delta]=extract_imfcc_bharathi(x,fs,Window_Length,NFFT,No_Filter,coefficients) 
% Function for computing IMFCC features 
% Usage: [stat,delta,double_delta]=extract_imfcc(file_path,Fs,Window_Length,No_Filter) 
%
% Input: x=contents of an audio file rad by audioRead
%       fs=Sampling frequency in Hz
%        Window_Length=Window length in ms
%        NFFT=No of FFT bins
%        No_Filter=No of filter
%        Coefficients =  no. of coefficients to be retained
%
%Output: stat=Static IMFCC (Size: NxNo_Filter where N is the number of frames)
%        delta=Delta IMFCC (Size: NxNo_Filter where N is the number of frames)
%        double_delta=Double Delta IMFCC (Size: NxNo_Filter where N is the number of frames)

speech=x;
Fs=fs;
%rng('default');
%speech=speech+randn(size(speech))*eps;                           %dithering
%-------------------------- PRE-EMPHASIS ----------------------------------
speech = filter( [1 -0.97], 1, speech);
%---------------------------FRAMING & WINDOWING----------------------------
frame_length_inSample=(Fs/1000)*Window_Length;
half=frame_length_inSample/2;
%if (length(speech) < half)
%    diff=half-length(speech);
%    dummy=zeros(diff,1);
%    temp=[speech;dummy];
%    speech=temp;
%end
framedspeech=buffer(speech,frame_length_inSample,frame_length_inSample/4,'nodelay')';
w=hamming(frame_length_inSample);
y_framed=framedspeech.*repmat(w',size(framedspeech,1),1);
%--------------------------------------------------------------------------
f=(Fs/2)*linspace(0,1,NFFT/2+1);
fmel=2595*log10(1+f./700); % CONVERTING TO MEL SCALE
fmelmax=max(fmel);
fmelmin=min(fmel);
filbandwidthsmel=linspace(fmelmin,fmelmax,No_Filter+2);
filbandwidthsf=700*(10.^(filbandwidthsmel/2595)-1);
fr_all=(abs(fft(y_framed',NFFT))).^2;
fa_all=fr_all(1:(NFFT/2)+1,:)';
fa_all=fliplr(fa_all); %Modification for IMFCC
filterbank=zeros((NFFT/2)+1,No_Filter);
for i=1:No_Filter
    filterbank(:,i)=trimf(f,[filbandwidthsf(i),filbandwidthsf(i+1),...
        filbandwidthsf(i+2)]);
end
filbanksum=fa_all*filterbank(1:end,:);
%-------------------------Calculate Static Cepstral------------------------
t=dct(log10(filbanksum'+eps));
t=(t(1:coefficients,:));
stat=t';
delta=deltas(stat',3)';
double_delta=deltas(delta',3)';
%--------------------------------------------------------------------------
