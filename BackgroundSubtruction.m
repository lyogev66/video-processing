function BackgroundSubtruction()
clear;clc;close all
filename = 'stable.avi';
hVideoSrc = VideoReader(filename);
% vision.VideoFileReader(filename, 'ImageColorSpace', 'Intensity');
hVideoOut = VideoWriter('binary.avi');
% NumberOfFrames=hVideoSrc.NumberOfFrames;

NumberOfFrames=hVideoSrc.Duration*hVideoSrc.FrameRate;
hVideoOut.Quality = 75;
hVideoOut.FrameRate = hVideoSrc.FrameRate;
open(hVideoOut);

%load the Video and crop it
dataBase=LoadDB(hVideoSrc);

BackSub(dataBase,hVideoOut,NumberOfFrames)
% ShowCurrentResult()

close(hVideoOut);
close(hVideoSrc);
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


function total_m=BackSub(dataBase,hVideoOut,NumberOfFrames)
frame=rgb2hsv(dataBase{1});
imgA=frame(:,:,1);
% imshow(imgA)
medianSize=NumberOfFrames;

medData=cell(medianSize,1);
wbar = waitbar(0,'Extracting Background, Please Wait...');

total_M=[];
for FrameCount=2:medianSize:NumberOfFrames
    waitbar(FrameCount/NumberOfFrames, wbar);
%     imgA = imgB;
%     imgAp = imgBp; 
    frameRow=[];
    for medIndexme=FrameCount:FrameCount+medianSize
        if medIndexme>NumberOfFrames
            break
        end
        frameHsv=rgb2hsv(dataBase{medIndexme});
        frame=frameHsv(:,:,1);
        frameRow=cat(3, frameRow, frame);
        
%     imgA=frame(:,:,1);
%     imshow(imgA); % Read frame into imgB
    end
    M = median(frameRow,3);
     imshow(M)
    total_M=cat(3,total_M,M);
%     writeVideo(hVideoOut,imgBp);  
end
close(wbar);
save('back.mat');
load('back.mat');
BWsize=500;
se = strel('disk',3);
for FrameCount=2:NumberOfFrames
frameHsv=rgb2hsv(dataBase{FrameCount});
frame=frameHsv(:,:,1);
new_f=abs(frame-total_M(:,:,ceil(1)));
% new_f=frame-total_M(:,:,ceil(FrameCount/medianSize));
BW2=(new_f>graythresh(new_f));
% imshow(BW2)
% imshow(medfilt2(BW2))
BW2 = imopen(BW2,se);
BW2 = imclose(BW2,se);
BW2=bwareaopen(BW2,BWsize);
% BW2=imfill(BW2,'holes');
imshow(BW2)

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