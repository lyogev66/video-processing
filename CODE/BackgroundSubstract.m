function [] = BackgroundSubstract(stbaleVid,binaryVid)
clc;close all
time=tic;
%stbaleVid = 'stabilized.avi';
%binaryVid='binary.avi'
hVideoSrc = VideoReader(sprintf('../Output/%s',stbaleVid));
[dataBase,NOF]=LoadVid(hVideoSrc,floor(hVideoSrc.Duration*hVideoSrc.FrameRate)-1);
%save('Frames.mat', 'dataBase' , 'hVideoSrc');
frames = FastTimeMedian(dataBase,ceil(NOF/4)-1);
CreateVid(sprintf('../Output/%s',binaryVid),frames,hVideoSrc.FrameRate);
disp('done');
toc(time);
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
    Vid = VideoWriter(Name_Str);
    Vid.FrameRate = FPS;
        open(Vid);
        for k=1:size(Frames,2)
            currframe = Frames{k};
            writeVideo(Vid,currframe);
        end
        close(Vid);
end
