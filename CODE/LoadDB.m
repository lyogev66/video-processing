function [dataBase,NumberOfFrames]=LoadDB(hVideoSrc,ApproxNumberOfFrames)
%% loading the frames into a cell struct
dataBase = cell(3,ApproxNumberOfFrames);

%define crop rectangle

%load and crop
wbar = waitbar(0,'Loading DataBase, Please Wait...');
FrameNumber=1;
while hasFrame(hVideoSrc)
% for FrameNumber=1:NumberOfFrames
    waitbar(FrameNumber/ApproxNumberOfFrames, wbar);
    frame = readFrame(hVideoSrc);
    dataBase{FrameNumber} = frame;
    FrameNumber = FrameNumber+1;
end
NumberOfFrames = min(FrameNumber-1,ApproxNumberOfFrames);
close(wbar);
end

% 
% 
% function [ dataBase ] = LoadDB(hVideoSrc,NumberOfFrames)
% %Load images to cell struct
% 
% dataBase = cell(3,NumberOfFrames);
% 
% %define crop rectangle
% 
% %load and crop
% wbar = waitbar(0,'Loading DataBase, Please Wait...');
% for FrameNumber=1:NumberOfFrames
%     waitbar(FrameNumber/NumberOfFrames, wbar);
%     frame=readFrame(hVideoSrc);
%     dataBase{FrameNumber}=frame;
% end
% close(wbar);
% end

