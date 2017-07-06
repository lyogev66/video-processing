function Tracker(mattedfile,outfile,TrackParam)
% Tracking algorithm based on Partical filter

% PARTICLE FILTER TRACKING Based on  HW 3
% using compBatDist, compNormHist, predictParticles,sampleParticles
% and showParticles to track  (other function for video parsing)

% %%manutal operation 
mattedfile = 'matted.avi';
outfile = 'output.avi';
% 
% % SET NUMBER OF PARTICLES
% TrackParam.maxMovment = 30;
% TrackParam.Particals = 100;
% TrackParam.chooseRectFrame = 3;
% initial Position
% position = [106.0000  188.0000   28.0000   75.0000];
% manualSelect=false;
% or
manualSelect=true;

N = TrackParam.Particals;
maxPixelMovment = TrackParam.maxMovment;
chooseRectFrame = TrackParam.chooseRectFrame;

%open video
hVideoSrc = VideoReader(sprintf('../Output/%s',mattedfile));
hVideoOut = VideoWriter(sprintf('../Output/%s',outfile));



%define parameters for the output video
ApproxNumberOfFrames = (hVideoSrc.Duration*hVideoSrc.FrameRate-1);
hVideoOut.Quality = 100;
hVideoOut.FrameRate = hVideoSrc.FrameRate;
open(hVideoOut);

%load the Video and crop it
[dataBase,NumberOfFrames] = LoadDB(hVideoSrc,ApproxNumberOfFrames);

I = dataBase{chooseRectFrame};

% to select the object uncomment below
if manualSelect
    figure; imshow(I);
    title('select rectangle object to track and double click')
    h = imrect;
    position = wait(h);
    close
end
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
DBout = cell(size(dataBase));


% CREATE INITIAL PARTICLE MATRIX 'S' (SIZE 6xN)
S = predictParticles(repmat(s_initial, 1, N),maxPixelMovment,size(I));

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
    S_next = predictParticles(S_next_tag,maxPixelMovment,size(I));
    if find(S_next(3,:)~=half_width)
        S_next(3,S_next(3,:)~=half_width) = half_width;
    end
        
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

end