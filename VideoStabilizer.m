function [] = VideoStabilizer()
clear;clc;close all
%%defining constants
filename = 'input.avi';
outfile='my_stable_big.avi';

hVideoSrc = VideoReader(filename);
% vision.VideoFileReader(filename, 'ImageColorSpace', 'Intensity');
hVideoOut = VideoWriter(outfile);
% NumberOfFrames=hVideoSrc.NumberOfFrames;

NumberOfFrames=floor(hVideoSrc.Duration*hVideoSrc.FrameRate)-1;
hVideoOut.Quality = 100;
hVideoOut.FrameRate = hVideoSrc.FrameRate;
open(hVideoOut);

%load the Video and crop it
dataBase=LoadAndCrop(hVideoSrc,NumberOfFrames);

StableVid(dataBase,hVideoOut,NumberOfFrames)
hVideoOut.close()


end

%%

function fullVideo=LoadAndCrop(hVideoSrc,NumberOfFrames)
fullVideo=cell(3,NumberOfFrames);
factor=0.1;

xmin=hVideoSrc.Width*factor;ymin=hVideoSrc.Height*factor;width=hVideoSrc.Width;height=hVideoSrc.Width;
cropRect=[xmin ymin width height];
wbar = waitbar(0,'Loading DataBase, Please Wait...');
for FrameNumber=1:NumberOfFrames
    waitbar(FrameNumber/NumberOfFrames, wbar);
    frame=readFrame(hVideoSrc);
    frame=imcrop(frame,cropRect);
%     frame=rot90(frame,2);   %fixme removeme later
    fullVideo{FrameNumber}=frame;
end
close(wbar);
end


%%
function StableVid(dataBase,hVideoOut,NumberOfFrames)

imgA=rgb2gray(dataBase{1});
imgB=imgA;
imgBp=imgA;
writeVideo(hVideoOut,(dataBase{1}));
Hcumulative = eye(3);
wbar = waitbar(0,'Stablizing Video, Please Wait...');
for FrameCount=2:NumberOfFrames
    waitbar(FrameCount/NumberOfFrames, wbar);
    imgA = imgB;
    imgAp = imgBp; 
    imgB = rgb2gray(dataBase{FrameCount}); % Read frame into imgB
    H = myEstimateTransform(imgA,imgB); %% what else
    HsRt = TformToSRT(H);
    Hcumulative = HsRt.T * Hcumulative;
%     imgBp = imwarp(imgB, tform, 'OutputView', imref2d(size(imgB)));
%         
    imgBp = imwarp((dataBase{FrameCount}),affine2d(Hcumulative),'OutputView',imref2d(size(imgB))) ;
%     pointsBmp = transformPointsForward(tform, pointsBm.Location);
    writeVideo(hVideoOut,imgBp);  
end
close(wbar);
end


%%



function h =  myEstimateTransform(imgA,imgB)
    ptThresh = 0.1;
    %detectFastFeatures instead of vision.CornerDetector
    pointsA = detectFASTFeatures(imgA, 'MinContrast', ptThresh);
    pointsB = detectFASTFeatures(imgB, 'MinContrast', ptThresh);

    %estimateGeometricTransform instead of vision.GeometricTransformEstimator
    % Extract FREAK descriptors for the corners
    [featuresA, pointsA] = extractFeatures(imgA, pointsA);
    [featuresB, pointsB] = extractFeatures(imgB, pointsB);
    indexPairs = matchFeatures(featuresA, featuresB);
    pointsA = pointsA(indexPairs(:, 1), :);
    pointsB = pointsB(indexPairs(:, 2), :);
    [tform, pointsBm, pointsAm] = estimateGeometricTransform(...
    pointsB, pointsA, 'affine');
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