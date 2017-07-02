%% MAIN FUNCTION HW 3, COURSE 0512-4263, TAU 2017
%
%
% PARTICLE FILTER TRACKING
%
% THE PURPOSE OF THIS ASSIGNMENT IS TO IMPLEMENT A PARTICLE FILTER TRACKER
% IN ORDER TO TRACK A RUNNING PERSON IN A SERIES OF IMAGES.
%
% IN ORDER TO DO THIS YOU WILL WRITE THE FOLLOWING FUNCTIONS:
%
% compNormHist.m
% INPUT  = I (image) AND s (1x6 STATE VECTOR, CAN ALSO BE ONE COLUMN FROM S)
% OUTPUT = normHist (NORMALIZED HISTOGRAM 16x16x16 SPREAD OUT AS A 4096x1
%                    VECTOR. NORMALIZED = SUM OF TOTAL ELEMENTS IN THE HISTOGRAM = 1)
%
%
% predictParticles.m
% INPUT  = S_next_tag (previously sampled particles)
% OUTPUT = S_next (predicted particles. weights and CDF not updated yet)
%
%
% compBatDist.m
% INPUT  = p , q (2 NORMALIZED HISTOGRAM VECTORS SIZED 4096x1)
% OUTPUT = THE BHATTACHARYYA DISTANCE BETWEEN p AND q (1x1)
%
% IMPORTANT - YOU WILL USE THIS FUNCTION TO UPDATE THE INDIVIDUAL WEIGHTS
% OF EACH PARTICLE. AFTER YOU'RE DONE WITH THIS YOU WILL NEED TO COMPUTE
% THE 100 NORMALIZED WEIGHTS WHICH WILL RESIDE IN VECTOR W (1x100)
% AND THE CDF (CUMULATIVE DISTRIBUTION FUNCTION, C. SIZED 1x100)
% NORMALIZING 100 WEIGHTS MEANS THAT THE SUM OF 100 WEIGHTS = 1
%
%
% sampleParticles.m
% INPUT  = S_prev (PREVIOUS STATE VECTOR MATRIX), C (CDF)
% OUTPUT = S_next_tag (NEW X STATE VECTOR MATRIX)
%
%
% showParticles.m
% INPUT = I (current frame), S (current state vector)
%         W (current weight vector), i (number of current frame)
%         ID (GROUP_XX_YY as set in line #48)
%
% CHANGE THE CODE IN LINES 48, THE SPACE SHOWN IN LINES 73-74 AND 91-92
%
%
%%
close all; clc; clearvars;




%%defining constants
srcfile = 'input.avi';
outfile = 'tracked.avi';



% SET NUMBER OF PARTICLES
N = 100;

% Initial Settings



%open video
hVideoSrc = VideoReader(srcfile);
hVideoOut = VideoWriter(outfile);

%define parameters
NumberOfFrames = floor((hVideoSrc.Duration*hVideoSrc.FrameRate-1)/3);
hVideoOut.Quality = 100;
hVideoOut.FrameRate = hVideoSrc.FrameRate;
open(hVideoOut);

%load the Video and crop it
dataBase = LoadDB(hVideoSrc,NumberOfFrames);

I = dataBase{1};


position = [100.0000  156.0000   29.0000   93.0000];

%add later 
% figure; imshow(I);
% h = imrect;
% position = wait(h);
close

%%%images
half_width = round(position(3)/2);
half_height = round(position(4)/2);
x_center = position(1) + half_width;
y_center = position(2) + half_height;

s_initial = [ x_center  % x center
    y_center    % y center
    half_width     % half width
    half_height     % half height
    0      % velocity x
    0   ]; % velocity y
DBout=cell(size(dataBase));


% CREATE INITIAL PARTICLE MATRIX 'S' (SIZE 6xN)
S = predictParticles(repmat(s_initial, 1, N));

% COMPUTE NORMALIZED HISTOGRAM
q = compNormHist(I,s_initial);

% COMPUTE NORMALIZED WEIGHTS (W) AND PREDICTOR CDFS (C)
p=zeros(size(q,1),1);
W=zeros(N,1);
for partical=1:N
    p = compNormHist(I,S(:,partical));
    W(partical)=compBatDist(p,q);
end
W=W./sum(W);
C=zeros(N,1);
for partical=1:N
     C(partical) = sum(W(1:partical));
end
%create Matrix A that can add the speed value
A=eye(6);A(1:2,5:6)=eye(2);

%going over all images

%% MAIN TRACKING LOOP
wbar = waitbar(0,'Tracking Target, Please Wait...');
for FrameNumber=2:NumberOfFrames
    waitbar(FrameNumber/NumberOfFrames, wbar);
    S_prev = S;
    % LOAD NEW IMAGE FRAME
    I = dataBase{FrameNumber};
    
    % SAMPLE THE CURRENT PARTICLE FILTERS
    S_next_tag = sampleParticles(S_prev,C);
    
    % PREDICT THE NEXT PARTICLE FILTERS (YOU MAY ADD NOISE
    S_next = predictParticles(S_next_tag);
    
    % COMPUTE NORMALIZED WEIGHTS (W) AND PREDICTOR CDFS (C)
    W=zeros(N,1);
    for partical=1:N

        p = compNormHist(I,S_next(:,partical));
        W(partical)=compBatDist(p,q);
    end
    W=W./sum(W);
    C=zeros(N,1);
    for partical=1:N
     C(partical) = sum(W(1:partical));
    end
    
    % SAMPLE NEW PARTICLES FROM THE NEW CDF'S
    S = sampleParticles(S_next,C);
    
    % export to video
    DBout{FrameNumber-1} = showParticles(I,S,W);

end
close(wbar);
WriteVideoFromDB(DBout,hVideoOut,NumberOfFrames);
close(hVideoOut)



