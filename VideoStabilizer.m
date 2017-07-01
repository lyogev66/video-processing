function [] = VideoStabilizer()
clear;clc;close all
%%defining constants
srcfile = 'input.avi';
outfile = 'my_stable_big.avi';
stablizerParam.MinContrast=0.3;
stablizerParam.MinQuality=0.2;
cropParam.facor = 0.1;
% sizeReduceFactor = 0.1;

%open video
hVideoSrc = VideoReader(srcfile);
hVideoOut = VideoWriter(outfile);

%define parameters
NumberOfFrames = floor(hVideoSrc.Duration*hVideoSrc.FrameRate)-1;
hVideoOut.Quality = 100;
hVideoOut.FrameRate = hVideoSrc.FrameRate;
open(hVideoOut);

%load the Video and crop it
dataBase = LoadDB(hVideoSrc,NumberOfFrames);
% dataBase=LoadAndCrop(hVideoSrc,NumberOfFrames,sizeReduceFactor);
dataBase = CropDB(dataBase,cropParam);
DBout = StableVid(dataBase,NumberOfFrames,stablizerParam);
WriteVideoFromDB(DBout,hVideoOut,NumberOfFrames)
hVideoOut.close()


end

%%
function dataBase=LoadDB(hVideoSrc,NumberOfFrames)

dataBase = cell(3,NumberOfFrames);

%define crop rectangle

%load and crop
wbar = waitbar(0,'Loading DataBase, Please Wait...');
for FrameNumber=1:NumberOfFrames
    waitbar(FrameNumber/NumberOfFrames, wbar);
    frame=readFrame(hVideoSrc);
    dataBase{FrameNumber}=frame;
end
close(wbar);
end

function WriteVideoFromDB(dataBase,hVideoOut,NumberOfFrames)

%define crop rectangle

%load and crop
wbar = waitbar(0,'Writing Video, Please Wait...');
for FrameNumber=1:NumberOfFrames
    waitbar(FrameNumber/NumberOfFrames, wbar);
    writeVideo(hVideoOut,dataBase{FrameNumber});
end
close(wbar);
end


function DBout = CropDB(dataBase,cropParam)
NumberOfFrames = size(dataBase,2);
DBout= cell(3,NumberOfFrames);
[Height, Width, ~] = size(dataBase{1});
Factor = cropParam.facor;
%define crop rectangle
xmin=Width*Factor;ymin=Height*Factor;
cropRect=[xmin ymin Width Height];
wbar = waitbar(0,'Croping Image, Please Wait...');
for FrameNumber=1:NumberOfFrames
    waitbar(FrameNumber/NumberOfFrames, wbar);
    DBout{FrameNumber}=imcrop(dataBase{FrameNumber},cropRect);
end
close(wbar);
end


%%
function DBout=StableVid(dataBase,NumberOfFrames,stablizerParam)

DBout = cell(3,NumberOfFrames);
% for stablizerInd=1:stablizeIter
    %get first frame - assuming first frame the anchor point.
    imgPrev = rgb2gray(dataBase{1});
    imgCurr = imgPrev;
    %write it as is
    DBout{1} = (dataBase{1});
    Hcumulative = eye(3);
    wbar = waitbar(0,sprintf('Stablizing Video,\n Please Wait...'));
%     wbar = waitbar(0,sprintf('Stablizing Video iter %d of %d,\n Please Wait...',stablizerInd,stablizeIter));    
    for FrameCount=2:NumberOfFrames
        waitbar(FrameCount/NumberOfFrames, wbar);
        imgPrev = imgCurr;
        imgCurr = rgb2gray(dataBase{FrameCount}); % Read frame into imgB
        H = myEstimateTransform(imgPrev,imgCurr,stablizerParam); 
        HsRt = TformToSRT(H);
        Hcumulative = HsRt.T * Hcumulative;      
        imgBp = imwarp((dataBase{FrameCount}),affine2d(Hcumulative),'OutputView',imref2d(size(imgCurr))) ;    
        DBout{FrameCount} = imgBp;  
    end
    close(wbar);
%     dataBase=DBout;
% end
end


%%



function h =  myEstimateTransform(imgA,imgB,stablizerParam)
    ptConstThresh = stablizerParam.MinContrast;
    ptQualThresh = stablizerParam.MinQuality;
    %detectFastFeatures instead of vision.CornerDetector
    pointsA = detectMinEigenFeatures(imgA);
    pointsB = detectMinEigenFeatures(imgB);    
%     pointsA = detectFASTFeatures(imgA, 'MinContrast', ptConstThresh,'MinQuality',ptQualThresh);
%     pointsB = detectFASTFeatures(imgB, 'MinContrast', ptConstThresh,'MinQuality',ptQualThresh);

    %estimateGeometricTransform instead of vision.GeometricTransformEstimator
    % Extract FREAK descriptors for the corners
    [featuresA, pointsA] = extractFeatures(imgA, pointsA,'BlockSize', 11);
    [featuresB, pointsB] = extractFeatures(imgB, pointsB,'BlockSize', 11);
    indexPairs = matchFeatures(featuresA, featuresB);
    pointsA = pointsA(indexPairs(:, 1), :);
    pointsB = pointsB(indexPairs(:, 2), :);
    [tform, pointsBm, pointsAm] = estimateGeometricTransform(...
    pointsB, pointsA, 'affine','MaxNumTrials',2000,'MaxDistance',1);
%     [tform, pointsBm, pointsAm] = estimateGeometricTransform(...
%     pointsB, pointsA, 'similarity');
    h = tform.T;
end

function tformsRT=TformToSRT(H)
    R = H(1:2,1:2);
    % Compute theta from mean of two possible arctangents
    theta = mean([atan2(R(2),R(1)) atan2(-R(3),R(4))]);
    % Compute scale from mean of two stable mean calculations
    scale = mean(R([1 4])/cos(theta));
    % Translation remains the same:
    translation = H(3, 1:2);
    % Reconstitute new s-R-t transform:
    HsRt = [[scale*[cos(theta) -sin(theta); sin(theta) cos(theta)]; ...
      translation], [0 0 1]'];
    tformsRT = affine2d(HsRt);
end

%%