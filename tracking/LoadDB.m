function [ dataBase ] = LoadDB(hVideoSrc,NumberOfFrames)
%Load images to cell struct

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

