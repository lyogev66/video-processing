function [] = Stabilize(InputFile,StableVid,stablizerParam,cropParam)

% remove comment for manual operation
%clear;close all
clc
InputFile = 'INPUT.avi';
StableVid = 'stabilized.avi';
stablizerParam.MaxDistance = 1;
stablizerParam.type = 'similarity'; % 'affine' for less shaky 'similarity' for shaky video
stablizerParam.MinQuality = 0.3;  % use arround 0.2
stablizerParam.MinContrast = 0.1;  % use below 0.1 value to get more points
% precentage from video borders to crop [0-1]-> 10% -100%
cropParam.facor = 0.1;

%open video
hVideoSrc = VideoReader(sprintf('../Input/%s',InputFile));
hVideoOut = VideoWriter(sprintf('../Output/%s',StableVid));

%define parameters
% NumberOfFrames = hVideoSrc.NumberOfFrames;
ApproxNumberOfFrames = floor(hVideoSrc.Duration*hVideoSrc.FrameRate)-1;
hVideoOut.Quality = 100;
hVideoOut.FrameRate = hVideoSrc.FrameRate;
open(hVideoOut);

%load the Video
[dataBase,NumberOfFrames] = LoadDB(hVideoSrc,ApproxNumberOfFrames);
DBout = Stablizing(dataBase,NumberOfFrames,stablizerParam);
DBout = CropDB(DBout,cropParam);

WriteVideoFromDB(DBout,hVideoOut,NumberOfFrames)
hVideoOut.close()
disp('Finished stabilization.');

end

%%
function [dataBase,NumberOfFrames]=LoadDB(hVideoSrc,ApproxNumberOfFrames)

dataBase = cell(3,ApproxNumberOfFrames);

%define crop rectangle

%load and crop
wbar = waitbar(0,'Loading DataBase, Please Wait...');
FrameCount=1;
while hasFrame(hVideoSrc)
% for FrameCount=1:NumberOfFrames
    waitbar(FrameCount/ApproxNumberOfFrames, wbar);
    frame = readFrame(hVideoSrc);
    dataBase{FrameCount} = frame;
    FrameCount = FrameCount+1;
end
NumberOfFrames = min(FrameCount-1,ApproxNumberOfFrames);
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
for FrameCount=1:NumberOfFrames
    waitbar(FrameCount/NumberOfFrames, wbar);
    DBout{FrameCount}=imcrop(dataBase{FrameCount},cropRect);
end
close(wbar);
end


%%
function DBout=Stablizing(dataBase,NumberOfFrames,stablizerParam)

DBout = cell(3,NumberOfFrames);

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
        HSRT = TformToSRT(H);
        Hcumulative = HSRT.T * Hcumulative;      
        imgBp = imwarp((dataBase{FrameCount}),affine2d(Hcumulative),'OutputView',imref2d(size(imgCurr))) ;    
        DBout{FrameCount} = imgBp;  
%         imshow(imgBp)
    end
    close(wbar);
%     dataBase=DBout;
% end
end

%%
function h =  myEstimateTransform(imgPrev,imgCurr,stablizerParam)

    %using detectMinEigenFeatures to detect features
%     pointsA = detectMinEigenFeatures(imgA,'MinQuality',ptQualThresh);
%     pointsB = detectMinEigenFeatures(imgB,'MinQuality',ptQualThresh); 
    optimizeIter = 3;
    MinQuality = stablizerParam.MinQuality;
    MinContrast= stablizerParam.MinContrast;
    MaxDistance = stablizerParam.MaxDistance; 
    TransformType = stablizerParam.type;
%     bestssd = inf;
    bestDist = inf;
    %using detectFASTFeatures to detect features
    for optimize=1:optimizeIter

        pointsA = detectFASTFeatures(imgPrev, 'MinQuality' ,MinQuality, 'MinContrast',MinContrast);
        pointsB = detectFASTFeatures(imgCurr, 'MinQuality' ,MinQuality, 'MinContrast',MinContrast);

        % Extract FREAK descriptors for the corners
        [featuresA, pointsA] = extractFeatures(imgPrev, pointsA);
        [featuresB, pointsB] = extractFeatures(imgCurr, pointsB);

        indexPairs = matchFeatures(featuresA, featuresB);
        pointsA = pointsA(indexPairs(:, 1), :);
        pointsB = pointsB(indexPairs(:, 2), :);
        %finding features point with smallest distance after match
        dist = pointsA.Location-pointsB.Location;
        totalDist = sum(sqrt(dist(:,1).^2+dist(:,2).^2));
        if totalDist<bestDist
            bestDist = totalDist;
            bestPointsA = pointsA;
            bestPointsB = pointsB;
        end
%         distance = sqrt((x2-x1)^2 + (y2-y1)^2);
        %     imshow((imgCurr));hold on;pointsA.plot
        %figure;showMatchedFeatures(imgPrev, imgCurr, pointsA, pointsB);legend('A', 'B');
    
        [tform, ~, ~] = estimateGeometricTransform(...
        bestPointsB, bestPointsA, TransformType,'MaxNumTrials',3000,'MaxDistance',MaxDistance);
    %     [tform, pointsBm, pointsAm] = estimateGeometricTransform(...
    %     pointsB, pointsA, 'affine');
%          imgCurrWarped = imwarp(imgCurr, tform, 'OutputView', imref2d(size(imgCurr)));
%          X = imgCurrWarped - imgPrev;
%          ssd = sum(X(:).^2);
%          if bestssd > ssd
%              bestTform = tform;
%          end
         % changing parameter for attempt of better results
         MinQuality = MinQuality-0.05;
    end
%     pointsBmp = transformPointsForward(tform, pointsBm.Location);
%     showMatchedFeatures(imgA, imgBp, pointsAm, pointsBmp);
    h = tform.T;
end
%%
function tformSRT=TformToSRT(H)
    R = H(1:2,1:2);
    % Compute theta from mean of two possible arctangents
    ang = mean([atan2(R(2),R(1)) atan2(-R(3),R(4))]);
    % Compute scale from mean of two stable mean calculations
    scale = mean(R([1 4])/cos(ang));
    % Translation remains the same:
    translation = H(3, 1:2);
    % Reconstitute new s-R-t transform:
    hSRT = [[scale*[cos(ang) -sin(ang); sin(ang) cos(ang)]; ...
      translation], [0 0 1]'];
    tformSRT = affine2d(hSRT);
end

%[ tempmean, tempmedian ]
% %%% ENHANCE STABILIZED VIDEO
% function videoenhance( stable )
% N = length( stable );
% [ydim,xdim,~] = size( stable{1} );
% %%% BUILD A 3-D IMAGE STACK FROM THE INPUT SEQUENCE
% stack = zeros( ydim, xdim, N );
% for k = 1 : N
% stack(:,:,k) = rgb2gray(stable{k});
% end
% %%% FILTER
% tempmean = mean( stack, 3 );
% tempmedian = median( stack, 3 );
% tempmean = tempmean/max(max(tempmean));
% tempmedian = tempmean/max(max(tempmedian));
% imshowpair(tempmedian,tempmean,'montage')
% end