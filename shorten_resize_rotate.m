%%
%defining parameters
filename = '2016 04 21 Green Screen Neu3.mp4';
t_start=1;
tend=10;
resize=true;
rotate=true;

%loading video
vidObj = VideoReader(filename);
vidHeight = vidObj.Height;
vidWidth = vidObj.Width;

s = struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'),...
    'colormap',[]);
v = VideoWriter('out.avi');
open(v)

k = 1;
while hasFrame(vidObj)
    s(k).cdata = readFrame(vidObj);
    if vidObj.CurrentTime<30
        continue
    end
    if vidObj.CurrentTime>45
        break
    end
    s(k).cdata = readFrame(vidObj);
    if resize
        frame=imresize(s(k).cdata,[480,600]);
    end
    if rotate
     frame=rot90(frame,2);
    end
    writeVideo(v,frame)
    k = k+1;
end
close(v)
close