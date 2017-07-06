function [ postMedFrames ] = FastTimeMedian( RGBframes, windowSize )
%FASTTIMEMEDIAN Summary of this function goes here
%   Detailed explanation goes here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                             Main Method                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


grayThresh = 0.15;
%
%windowSize =ceil(size(RGBframes,2)/4)-1);  

%checking the window size is odd
if (mod(windowSize,2)== 0)
    windowSize=windowSize+1;
end

% Read Video
[~,c] = size(RGBframes);
%HSV
% HSVframes =cell(1,c);
% Hframes = cell(1,c);
% for i=1:c
%     HSVframes{i}=uint8(round(rgb2hsv(RGBframes{i}).*256));
%     Hframes{i} = uint8(HSVframes{i}(:,:,1));
% end
%% Variables
%result= median(Hframes(:,:,:,:),4);
% [frameHight,frameWidth] = size(Hframes{1});
% lastFrame = c;
% %%
% Median=zeros(frameHight,frameWidth,1,lastFrame);
% for i = 1: lastFrame
%     Median(:,:,1,i) = Hframes{i};
% end
% background_frame = median(Median,4);
% background = cell(1,size(Median,4));
% for i = 1: lastFrame
%     background{i} = uint8(background_frame);
% end


%RGB
[frameHight,frameWidth,~] = size(RGBframes{1});
lastFrame = c;

rMedian=zeros(frameHight,frameWidth,1,lastFrame);
gMedian=zeros(frameHight,frameWidth,1,lastFrame);
bMedian=zeros(frameHight,frameWidth,1,lastFrame);

for i = 1: lastFrame
    rMedian(:,:,1,i) = RGBframes{i}(:,:,1);
    gMedian(:,:,1,i) = RGBframes{i}(:,:,2);
    bMedian(:,:,1,i) = RGBframes{i}(:,:,3);
end

background_rframe = median(rMedian,4);
background_gframe = median(gMedian,4);
background_bframe = median(bMedian,4);

background = cell(1,size(rMedian,4));
wbar =  waitbar(0,'Extracting Image, Please Wait...');
for i = 1: lastFrame
    waitbar(i/lastFrame, wbar);
    background{i}(:,:,1) = uint8(background_rframe);
    background{i}(:,:,2) = uint8(background_gframe);
    background{i}(:,:,3) = uint8(background_bframe);
end
close(wbar);
%%
% background = cell(size(Hframes));
% windowFrame = zeros(1,windowSize);
% pixelsInFrame = frameHight*frameWidth;
% histMat = zeros(1,256);
% minCount = floor(windowSize-1)/2;
% postMedFrames = cell(1,lastFrame);
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %                             Main Method                           %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% wbar =  waitbar(0,'Fast Median is in Process, Please Wait...');
% for currPixel = 1: pixelsInFrame
%     waitbar(currPixel/pixelsInFrame, wbar);
%     fprintf('Processing %d out of %d\n',currPixel,pixelsInFrame);
%     count = 0;
%     firstRound = 1;
%     lastRound = 0;
%     histMat = zeros(1,256);
%     
%     for currFrame = 1:lastFrame
%         row = floor((currPixel-1)/frameWidth)+1;
%         col = currPixel-(row-1)*frameWidth;
%         
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
% % corener cases
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
%         %current frame count is lower than widnow size
%         if ((currFrame <= windowSize) || (lastFrame-currFrame <= windowSize))
%             if (firstRound || lastRound)
%                 %Get pixal from frames
%                 for idx=1:windowSize
%                     windowFrame(idx)=Hframes{idx}(row,col);
%                     if (firstRound)
%                         histMat(windowFrame(idx)+1)= histMat(windowFrame(idx)+1)+1;
%                     end
%                 end
%                 firstRound=0;lastRound=0;
%             end
%             %get threshold
%             currThreshold = median(windowFrame);
%             %set result
%             background{currFrame}(row,col) = uint8(currThreshold);
%             %get the currnt count of elements which are lower then threshold
%             count = size(find(windowFrame < currThreshold),2);
%             if (currFrame == windowSize )
%                 lastRound = 1;
%             end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%           
% % Normal case
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
%         else
%             %update count
%             if (windowFrame(1)< currThreshold)
%                 count = count - 1;
%             end 
%             %remove the first element
%             windowFrame=circshift(windowFrame,[0,-1]);%circ not working
%             histMat(windowFrame(windowSize)+1)= histMat(windowFrame(windowSize)+1) - 1;
%             windowFrame(windowSize)=Hframes{currFrame}(row,col);
%             histMat(windowFrame(windowSize)+1)= histMat(windowFrame(windowSize)+1) + 1;
%             %update count
%             if (windowFrame(windowSize)< currThreshold)
%                 count = count + 1;
%             end 
%             %Update threshold and count 
%             idx = currThreshold + 1;
%             if (count > minCount && count < windowSize+1)              
%                 while (count > minCount && idx > 0 )
%                     count = count - histMat(idx);
%                     idx = idx - 1;
%                 end
%                 currThreshold = idx ; %0 since of the last idx -1 and currThreshold + 1
%             else
%                if (count < minCount && count > -1)
%                    while (count < minCount && idx < 256 )
%                     count = count + histMat(idx);
%                     idx = idx + 1;
%                    end
%                     currThreshold = idx - 2; %2 since of the last idx +1 and currThreshold + 1
%                else
% 
% 
%                    currThreshold = idx - 1;
%                end
%             end
%             background{currFrame}(row,col) = uint8(currThreshold);  
%             %for debug only
% %             if (median(windowFrame)~= currThreshold)
% %                 error('');
% %             end
%         end
%     end
% end
% close(wbar)
%save('final.mat', 'background' , 'Hframes','RGBframes');
%% Background Subtraction
% clc; clear all;
% load('final.mat');

%binMask = cell(size(Hframes));

%masking

% for idx=1:size(binMask,2)
%     Hframes{idx} = im2double(Hframes{idx});background{idx} = im2double(background{idx});
%     binMask{idx} = abs(Hframes{idx} - background{idx});
%     binMask{idx}= imbinarize(binMask{idx},grayThresh);   
% end
binMask = cell(1,size(RGBframes,2));
for idx=1:size(RGBframes,2)
    RGBframes{idx} = im2double(RGBframes{idx});background{idx} = im2double(background{idx});
    redDelta = abs(RGBframes{idx}(:,:,1) - background{idx}(:,:,1));
    greenDelta = abs(RGBframes{idx}(:,:,2) - background{idx}(:,:,2));
    blueDelta = abs(RGBframes{idx}(:,:,3) - background{idx}(:,:,3));
    maxDelta = max(redDelta, max(greenDelta,blueDelta));
    binMask{idx}= imbinarize(maxDelta,grayThresh);   
end
%%
%enhencing
maxBWArea = 9000;
BWArea = 1000;
diskEl = strel('Disk',3);
numOfSmoothItr = 1;
wbar =  waitbar(0,'Smoothing in Process, Please Wait...');
for idx=1:size(binMask,2)
    waitbar(idx/size(binMask,2), wbar);
    binMaskSmooth = binMask{idx};
    for j=1:numOfSmoothItr
        binMaskSmooth = bwareaopen(binMaskSmooth, 700);
        binMaskSmooth = imdilate(binMaskSmooth,diskEl);
        binMaskSmooth = medfilt2(binMaskSmooth,[5 5]);
        binMaskSmooth = imerode(binMaskSmooth,diskEl);
        binMaskSmooth = imopen(binMaskSmooth,diskEl);
        binMaskSmooth = imclose(binMaskSmooth,diskEl); 
        binMaskSmooth = bwareaopen(binMaskSmooth, BWArea);
        BWLabel = bwlabel(binMaskSmooth,8);
%        Finding the largest CC in the binary image:
        MaxLabelIndex = max(max(BWLabel));
        MaxCCSize = 0;
        MaxCCIndex = 1;
        for k=1:1:(MaxLabelIndex-1)    
            [MaxCCSize1, ~] = size(find(BWLabel==k));
            [MaxCCSize2, ~] = size(find(BWLabel==(k+1)));
            MaxCCtmp = max(MaxCCSize1,MaxCCSize2);
            if (MaxCCtmp < maxBWArea)
                MaxCCSize = max(MaxCCSize,MaxCCtmp);
                %maxBWArea = MaxCCSize +1000;
            end
            if (MaxCCtmp == MaxCCSize)
                if (MaxCCSize1 > MaxCCSize2)
                    MaxCCIndex = k;
                else
                    MaxCCIndex = k+1;
                end
            end              
        end
        binMaskSmooth = binMaskSmooth & (BWLabel == MaxCCIndex);
    end
    binMaskSmooth = medfilt2(binMaskSmooth);
    binMask{idx} = binMaskSmooth;
end
close(wbar);
%% Appling mask
% for ch=1:3
%     for idx=1:size(binMask,2)
%         postMedFrames{idx}(:,:,ch) = RGBframes{idx}(:,:,ch) .* binMask{idx};
%     end
% end
postMedFrames = cell(size(binMask));
for idx=1: size(binMask,2)
    postMedFrames{idx} = double(binMask{idx});
end
end %function



