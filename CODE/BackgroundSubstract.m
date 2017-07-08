function [] = BackgroundSubstract(stbaleVid,binaryVid,ExtractedVid,BGSubParam)

%For standalone operation please uncomment the following
%clc;close all; clear all;
% BGSubParam.grayThresh = 0.15;
% BGSubParam.maxApproxFigureArea = 12000;
% BGSubParam.minApproxFigureArea = 1000;
% BGSubParam.AreYouFeelingLucky = 1;
% BGSubParam.MaxMinAreaDelta = 1500;
% BGSubParam.numOfSmoothItr = 1;
% stbaleVid = 'stabilized.avi';
% binaryVid = 'binary.avi';
% ExtractedVid = 'extracted.avi';

hVideoSrc = VideoReader(sprintf('../Output/%s',stbaleVid));
[RGBframes,~]=LoadVid(hVideoSrc,floor(hVideoSrc.Duration*hVideoSrc.FrameRate)-1);
%% Main Method
% Read Video
[~,c] = size(RGBframes);
%RGB
[frameHight,frameWidth,~] = size(RGBframes{1});
lastFrame = c;
%create Database
rMedian=zeros(frameHight,frameWidth,1,lastFrame);
gMedian=zeros(frameHight,frameWidth,1,lastFrame);
bMedian=zeros(frameHight,frameWidth,1,lastFrame);
%get Frames
for i = 1: lastFrame
    rMedian(:,:,1,i) = RGBframes{i}(:,:,1);
    gMedian(:,:,1,i) = RGBframes{i}(:,:,2);
    bMedian(:,:,1,i) = RGBframes{i}(:,:,3);
end
%performing median
background_rframe = median(rMedian,4);
background_gframe = median(gMedian,4);
background_bframe = median(bMedian,4);
clearvars 'rMedian' 'gMedian' 'bMedian';

%replicating background
background = cell(1,lastFrame);
wbar =  waitbar(0,'Processing Video, Please Wait...');
for i = 1: lastFrame
    waitbar(i/lastFrame, wbar);
    background{i}(:,:,1) = uint8(background_rframe);
    background{i}(:,:,2) = uint8(background_gframe);
    background{i}(:,:,3) = uint8(background_bframe);
end
close(wbar);

wbar =  waitbar(0,'Performing Substraction, Please Wait...');
binMask = cell(1,size(RGBframes,2));
for idx=1:size(RGBframes,2)
    waitbar(idx/lastFrame, wbar);
    RGBframes{idx} = im2double(RGBframes{idx});background{idx} = im2double(background{idx});
    redDelta = abs(RGBframes{idx}(:,:,1) - background{idx}(:,:,1));
    greenDelta = abs(RGBframes{idx}(:,:,2) - background{idx}(:,:,2));
    blueDelta = abs(RGBframes{idx}(:,:,3) - background{idx}(:,:,3));
    maxDelta = max(redDelta, max(greenDelta,blueDelta));
    binMask{idx}= imbinarize(maxDelta,BGSubParam.grayThresh);   
end
close(wbar);
%% Smoothing
maxSize = BGSubParam.maxApproxFigureArea;
minSize = BGSubParam.minApproxFigureArea;
diskEl = strel('Disk',3);
wbar =  waitbar(0,'Smoothing in Process, Please Wait...');
for idx=1:size(binMask,2)
    waitbar(idx/size(binMask,2), wbar);
    binMaskSmooth = binMask{idx};
    for j=1:BGSubParam.numOfSmoothItr
        %Remove small particals
        binMaskSmooth = bwareaopen(binMaskSmooth, 700);
%         %Filter noise and smooth edges
%         binMaskSmooth = medfilt2(binMaskSmooth,[5 5]);
% %         %Open and close again to gather even more small blobs
%         binMaskSmooth = imclose(binMaskSmooth,diskEl); 
% %         binMaskSmooth = imopen(binMaskSmooth,diskEl);
        binMaskSmooth = imopen(binMaskSmooth,strel('Disk',1));
        binMaskSmooth = medfilt2(binMaskSmooth,[5 5]);
        binMaskSmooth = imerode(binMaskSmooth,strel('Disk',1));
        binMaskSmooth = medfilt2(binMaskSmooth,[5 5]);
        binMaskSmooth = imdilate(binMaskSmooth,strel('Disk',3));
        %Remove remining blobs which are smaller then figure
        binMaskSmooth = bwareaopen(binMaskSmooth, BGSubParam.minApproxFigureArea);
        %Connected componenets
        BWLabel = bwlabel(binMaskSmooth,8);
        %Finding the largest CC in the binary image:
        MaxLabelIndex = max(max(BWLabel));
        MaxCCSize = 0;
        MaxCCIndex = 1;
        for k=1:1:(MaxLabelIndex-1)    
            [MaxCCSize1, ~] = size(find(BWLabel==k));
            [MaxCCSize2, ~] = size(find(BWLabel==(k+1)));
            MaxCCtmp = max(MaxCCSize1,MaxCCSize2);
            MinCCtmp = min(MaxCCSize1,MaxCCSize2);
            %Remove blobs that are bigger then figure
            if (MaxCCtmp < maxSize && MaxCCtmp > minSize)
                MaxCCSize = max(MaxCCSize,MaxCCtmp);
            else
                %Find the maximum blob in range
                if (MinCCtmp < maxSize && MinCCtmp > minSize)
                    MaxCCSize = max(MaxCCSize,MinCCtmp);
                end
                
            end
            if (MaxCCtmp == MaxCCSize)
                if (MaxCCSize1 > MaxCCSize2)
                    MaxCCIndex = k;
                else
                    MaxCCIndex = k+1;
                end
            else
                %if no maximum blob in range, find the minimum one (that
                % mean we missed while chacking for maximum since it was
                % between 2 big blobs)
                if (MinCCtmp == MaxCCSize)
                    if (MaxCCSize1 < MaxCCSize2)
                        MaxCCIndex = k;
                    else
                        MaxCCIndex = k+1;
                    end
                end
            end              
        end
        binMaskSmooth = binMaskSmooth & (BWLabel == MaxCCIndex);
        if (BGSubParam.AreYouFeelingLucky == 1)
            %change the scale based on the blob found as figure for fine tuning the algorithm 
            maxSize = size(find(BWLabel==MaxCCIndex),1) + BGSubParam.MaxMinAreaDelta;
            minSize = maxSize - 2*BGSubParam.MaxMinAreaDelta;
        end
    end
    binMaskSmooth = medfilt2(binMaskSmooth);
    binMask{idx} = binMaskSmooth;
end
close(wbar);

wbar =  waitbar(0,'Appling Binary Mask, Please Wait...');
binaryDataBase = cell(size(binMask));extractedDataBase = cell(size(binMask));
for ch=1:3
    for idx=1: size(binMask,2)
        if (ch == 1)
            binaryDataBase{idx} = double(binMask{idx});
        end
        waitbar(ch/3, wbar);
        extractedDataBase{idx}(:,:,ch) = RGBframes{idx}(:,:,ch) .* binMask{idx};
    end
end
close(wbar)
CreateVid(sprintf('../Output/%s',binaryVid),binaryDataBase,hVideoSrc.FrameRate);
CreateVid(sprintf('../Output/%s',ExtractedVid),extractedDataBase,hVideoSrc.FrameRate);
end


function [dataBase,NumberOfFrames]=LoadVid(hVideoSrc,ApproxNumberOfFrames)
 
dataBase = cell(1,ApproxNumberOfFrames);

%define crop rectangle

%load and crop
wbar = waitbar(0,'Loading DataBase, Please Wait...');
FrameCount=1;
while hasFrame(hVideoSrc)
    waitbar(FrameCount/ApproxNumberOfFrames, wbar);
    frame = readFrame(hVideoSrc);
    dataBase{FrameCount} = frame;
    FrameCount = FrameCount+1;
end
NumberOfFrames = min(FrameCount-1,ApproxNumberOfFrames);
close(wbar);
end

function [  ] = CreateVid( Name_Str,Frames, FPS)
    wbar = waitbar(0,'Writing Video, Please Wait...');
    Vid = VideoWriter(Name_Str);
    Vid.FrameRate = FPS;
    open(Vid);
    numOfFrames =  size(Frames,2);   
    for k=1:numOfFrames
        waitbar(k/numOfFrames, wbar);
        currframe = Frames{k};
        writeVideo(Vid,currframe);
    end
    close(Vid);
    close(wbar);
end
