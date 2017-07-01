function WriteVideoFromDB(dataBase,hVideoOut,NumberOfFrames)
% write the Data base into a given video file
%define crop rectangle

%load and crop
wbar = waitbar(0,'Writing Video, Please Wait...');
for FrameNumber=1:NumberOfFrames
    waitbar(FrameNumber/NumberOfFrames, wbar);
    frame=dataBase{FrameNumber};
    if ~isempty(frame)
        writeVideo(hVideoOut,frame);
    end
end
close(wbar);
end