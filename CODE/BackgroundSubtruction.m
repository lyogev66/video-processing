function BackgroundSubtruction()
clear;clc;close all
filename = 'stable2.avi';
hVideoSrc = VideoReader(filename);
% vision.VideoFileReader(filename, 'ImageColorSpace', 'Intensity');
hVideoOut = VideoWriter('binary.avi');
% NumberOfFrames=hVideoSrc.NumberOfFrames;

NumberOfFrames=hVideoSrc.Duration*hVideoSrc.FrameRate;
hVideoOut.Quality = 100;
hVideoOut.FrameRate = hVideoSrc.FrameRate;
medianSize=ceil(NumberOfFrames/4);
open(hVideoOut);

%load the Video and crop it
dataBase=LoadDB(hVideoSrc);

BackSub(dataBase,hVideoOut,NumberOfFrames,medianSize)
% ShowCurrentResult()

close(hVideoOut);
% close(hVideoSrc);
end

function fullVideo=LoadDB(hVideoSrc)
NumberOfFrames = hVideoSrc.Duration*hVideoSrc.FrameRate;
fullVideo=cell(3,NumberOfFrames);

wbar = waitbar(0,'Loading DataBase, Please Wait...');
for FrameNumber=1:NumberOfFrames
    waitbar(FrameNumber/NumberOfFrames, wbar);
    frame=readFrame(hVideoSrc);
    fullVideo{FrameNumber}=frame;
end
close(wbar);
end


function total_m=BackSub(dataBase,hVideoOut,NumberOfFrames,medianSize)
frame=rgb2hsv(dataBase{1});
imgA=frame(:,:,1);
% imshow(imgA)


medData=cell(medianSize,1);
wbar = waitbar(0,'Extracting Background, Please Wait...');

total_M=[];
for FrameCount=2:medianSize:NumberOfFrames
    waitbar(FrameCount/NumberOfFrames, wbar);
%     imgA = imgB;
%     imgAp = imgBp; 
    frameTotalHue=[];
    frameTotalGray=[];
    for medIndexme=FrameCount:FrameCount+medianSize
        if medIndexme>NumberOfFrames
            break
        end
        frameHsv=rgb2hsv(dataBase{medIndexme});
        frame=frameHsv(:,:,1);
        frameTotalHue=cat(3, frameTotalHue, frame);

    end
    M = median(frameTotalHue,3);
     imshow(M)
    total_M=cat(3,total_M,M);
%     writeVideo(hVideoOut,imgBp);  
end
close(wbar);
%save('back.mat');
% load('back.mat');
BWsize=500;
se = strel('disk',3);
for FrameCount=2:NumberOfFrames
    frameHsv=rgb2hsv(dataBase{FrameCount});
    frame=frameHsv(:,:,1);
%     new_f=abs(frame-total_M(:,:,ceil(1)));
    new_f=frame-total_M(:,:,ceil(FrameCount/medianSize));
%     imshow(new_f)
    BW2=(new_f>graythresh(new_f));
     imshow(BW2)
    % imshow(medfilt2(BW2))
%     BW2 = imopen(BW2,se);
%     BW2 = imclose(BW2,se);
%     BW2=imfill(BW2,'holes');    
%     BW2=bwareaopen(BW2,BWsize);
%     
%     imshow(BW2)

    %imshow(medfilt2(BW2))
end




end





% function BackSub(dataBase,hVideoOut,NumberOfFrames)
% frame=rgb2hsv(dataBase{1});
% imgA=frame(:,:,1);
% imshow(imgA)
% 
% wbar = waitbar(0,'Stablizing Video, Please Wait...');
% for FrameCount=2:NumberOfFrames
%     waitbar(FrameCount/NumberOfFrames, wbar);
% %     imgA = imgB;
% %     imgAp = imgBp; 
%     frame=rgb2hsv(dataBase{FrameCount});
%     imgA=frame(:,:,1);
%     imshow(imgA); % Read frame into imgB
% 
% %     writeVideo(hVideoOut,imgBp);  
% end
% close(wbar);
% 
% end