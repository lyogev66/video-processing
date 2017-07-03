function Matting(StableVid, ExtractedVid, backgroundImage, Output, WidthOfNarrowBand)
% Functionality:
%   The function mats the object and the supplied background.
% Arguments:
%   Input                   -   The video after stabilization.
%   InputBinary             -   Binary video after background subtraction.
%   InputBackground         -   New background for the video. 
%   Output                  -   Output file name (the matted video).
%   WidthOfNarrowBand       -   Width for the narrow band.  
% Output:
%   The video after matting (combining the object and the new background) named 'matted.avi'.
%   
backgroundImage = 'background.jpg';
StableVid = 'stabilized.avi';
ExtractedVid = 'binary.avi';
Output = 'matted.avi';
WidthOfNarrowBand = 3;
SElement = strel('disk', WidthOfNarrowBand);

% Creating I/O objects & Initializing parameters:
InputBackground = sprintf( '../Input/%s', backgroundImage);
InputFile = sprintf('../Output/%s', StableVid);
InputBinaryFile = sprintf('../Output/%s', ExtractedVid);


hVideoStable = VideoReader(InputFile);
hVideoExtracted = VideoReader(InputBinaryFile);

ApproxNumberOfFrames = (hVideoStable.Duration*hVideoStable.FrameRate-1);


[dataBaseStable,NumberOfFramesStable] = LoadDB(hVideoStable,ApproxNumberOfFrames);
[dataBaseExtracted,NumberOfFramesExtracted] = LoadDB(hVideoExtracted,ApproxNumberOfFrames);

NumberOfFrames = min(NumberOfFramesStable, NumberOfFramesExtracted);
[Height,Width,~]= size(dataBaseStable{1});


% Resizing background due to the video size:
BackgroundImage = imread(InputBackground);
BackgroundImage = im2double(imresize(BackgroundImage, [Height Width]));

% opening output video
hVideoOut = VideoWriter(sprintf( '../Output/%s', Output));
hVideoOut.Quality = 100;
hVideoOut.FrameRate = hVideoStable.FrameRate;
open(hVideoOut);



% Waitbar:
h = waitbar(0,'Matting, Please Wait...');

% Matting initialization:
RefFrame = dataBaseStable{1};
RefBinary = dataBaseExtracted{1};
RefBinaryV = imbinarize(rgb2gray(RefBinary));

% Sampling foreground and background for histogram calculation:
[FGXIndices, FGYIndices] = find(RefBinaryV == 1); 
[BGXIndices, BGYIndices] = find(RefBinaryV == 0);
[FGIndicesNum,~] = size(FGXIndices); 
[BGIndicesNum,~] = size(BGXIndices);
% at least 1 sample
NumOfSamples = max(min(floor(FGIndicesNum/50),floor(BGIndicesNum/50)),1);
SamplesFG = randsample(1:FGIndicesNum,NumOfSamples); 
SamplesBG = randsample(1:BGIndicesNum,NumOfSamples);
FG_Sampled_X_Indices = FGXIndices(SamplesFG);
FG_Sampled_Y_Indices = FGYIndices(SamplesFG);
BG_Sampled_X_Indices = BGXIndices(SamplesBG); 
BG_Sampled_Y_Indices = BGYIndices(SamplesBG);

% Histogram calculation for foreground and background:
PixelValues = 0:255;
RefFrameHSV = rgb2hsv(RefFrame);
RefVFrame = RefFrameHSV(:,:,3)*255;
FGscribbleColors = RefVFrame(FG_Sampled_X_Indices,FG_Sampled_Y_Indices);
[FG_Dens,~]=ksdensity(FGscribbleColors(:),PixelValues);
BGscribbleColors = RefVFrame(BG_Sampled_X_Indices, BG_Sampled_Y_Indices);
[BG_Dens,~]=ksdensity(BGscribbleColors(:),PixelValues);

% Iterating over the frames and matting the object and background
for FrameNumber=1:NumberOfFrames
    
    % Getting a new frame:
    CurrFrameRGB = double(dataBaseStable{FrameNumber})/255;
    CurrFrameHSV = rgb2hsv(CurrFrameRGB);
    CurrVFrame   = CurrFrameHSV(:,:,3);
	CurrBinaryFrame = imbinarize(rgb2gray(dataBaseExtracted{FrameNumber}));
	
	% Finding perimeter and widenning the object (narrow band):
	NB = imdilate(bwperim(imfill(CurrBinaryFrame,'holes')), SElement);
	NB_VALUES = double(CurrVFrame).*double(NB);
    imshow(NB)
	% Calculating likelihood:
    NB_Indices = find(NB_VALUES == 1);
	FG_P = FG_Dens(NB_VALUES*255+1);
    BG_P = BG_Dens(NB_VALUES*255+1);
	BG_Pf = double(BG_P./(FG_P+BG_P));
	FG_Pf = double(FG_P./(FG_P+BG_P));
    BG_Pf(NB_Indices) = 0;
    FG_Pf(NB_Indices) = 0;
    
    % Calculating alpha map:
    AlphaMap = FG_Pf./(FG_Pf+BG_Pf);
    AlphaMap(isnan(AlphaMap)) = 1-CurrBinaryFrame(isnan(AlphaMap));

    % Building the combined frame:
    BG = cat(3,(1-AlphaMap).*BackgroundImage(:,:,1),(1-AlphaMap).*BackgroundImage(:,:,2),(1-AlphaMap).*BackgroundImage(:,:,3)); 
    FG = cat(3,AlphaMap.*CurrFrameRGB(:,:,1),AlphaMap.*CurrFrameRGB(:,:,2),AlphaMap.*CurrFrameRGB(:,:,3)); 
    MattedFrame = BG + FG;
    writeVideo(hVideoOut, MattedFrame);
    waitbar(FrameNumber/NumberOfFrames);
    imshow(MattedFrame)
end

close(hVideoOut);
close(h);
end









function OurMatting(InputVidName, InputBinary, OutputVid, NewBackground, factor)

% Prepare input and output full names for Matting:
InputFilename = sprintf('../Output/%s',InputVidName);
InputBinaryFilename = sprintf('../Output/%s',InputBinary);
NewBackgroundFilename = sprintf('../Input/%s',NewBackground);
OutputMattedFilename = sprintf('../Output/%s',OutputVid);

vid=VideoReader(InputFilename); %read input video
BinVid=VideoReader(InputBinaryFilename);
MattedVid = VideoWriter(OutputMattedFilename); %create file for output video
open(MattedVid);

NumOfFrames = vid.NumberOfFrames;

toRead = 41;
F=read(vid,toRead); %get 41st frame of the input video
BinFrame=read(BinVid,1); 
F_height=size(F(:,:,1),1); % video frame's height
F_width=size(F(:,:,1),2); %video frame's width
B=imread(NewBackgroundFilename); %get background image
B=imresize(B,[F_height F_width]); %resize background image to fit video frames
B=im2double(B);

F=im2double(F);
%I = imadjust(F,stretchlim(F),[]);
I=uint32(255*F); %convert to uint32 in order to be able to access high indexes in image I

imshow(F); title('Please click on numerous points of the foreground object, double click for last point');
[Yf,Xf]=getpts;
Yf=uint32(Yf);  Xf=uint32(Xf);

imshow(F); title('Please click on numerous points of the background, double click for last point');
[Yb,Xb]=getpts;
close;
Yb=uint32(Yb);  Xb=uint32(Xb);

IntensityF1=zeros(1,size(Xf,1));
IntensityF2=zeros(1,size(Xf,1));
IntensityF3=zeros(1,size(Xf,1));

%create intensity samples vector of foreground for each color channel, from user's
%samples
for i=1:size(Xf)
    IntensityF1(i)=I(Xf(i),Yf(i),1);
    IntensityF2(i)=I(Xf(i),Yf(i),2);
    IntensityF3(i)=I(Xf(i),Yf(i),3);
end

IntensityB1=zeros(1,size(Xb,1));
IntensityB2=zeros(1,size(Xb,1));
IntensityB3=zeros(1,size(Xb,1));

%create intensity samples vector of background for each color channel, from user's
%samples
for i=1:size(Xb)
    IntensityB1(i)=I(Xb(i),Yb(i),1);
    IntensityB2(i)=I(Xb(i),Yb(i),2);
    IntensityB3(i)=I(Xb(i),Yb(i),3);
end

%use kernel density estimation to estimate histograms of foreground, for
%G & B color channels

[~,densityf2,~,~]= kde(IntensityF2,2^12 ,0,255);
[~,densityf3,~,~]= kde(IntensityF3,2^12 ,0,255);

%use kernel density estimation to estimate histograms of background, for
%G & B color channels

[~,densityb2,~,~]=kde(IntensityB2,2^12 ,0,255);
[~,densityb3,~,~]=kde(IntensityB3,2^12 ,0,255);

%calculate probability of pixel to belong to foreground

Pf2=densityf2./(densityf2+densityb2);
Pf3=densityf3./(densityf3+densityb3);

%calculate probability of pixel to belong to background

Pb2=densityb2./(densityf2+densityb2);
Pb3=densityb3./(densityf3+densityb3);

trimap=zeros(size(I(:,:,1)));
prob_f_map=zeros(size(I(:,:,1)));
prob_b_map=zeros(size(I(:,:,1)));

%F=read(vid,1);
%F=im2double(F);

%Main loop:

w = waitbar(0, 'Matting...');
for FrameIdx=1:NumOfFrames
    
    F=read(vid, FrameIdx);
    F=im2double(F);
    BinFrame=read(BinVid, FrameIdx);
    BinFrame=im2double(BinFrame);
   % I = imadjust(F,stretchlim(F),[]);
    I=uint32(255*F);
  
for i=1:size(I(:,:,1),1)
    for j=1:size(I(:,:,1),2)
      
        prob_f_map(i,j)=((Pf2((16*I(i,j,2))+1)).*(Pf3((16*I(i,j,3))+1))); %calc foreground prob map for each pixel

        prob_b_map(i,j)=(Pb2((16*I(i,j,2))+1)).*(Pb3((16*I(i,j,3))+1)); %calc background prob map for each pixel
       
    
    end
end
 
 %calc gradient of foreground and background prob maps
[Gxf,Gyf]=imgradientxy(prob_f_map);
Mag_grad_f=sqrt(Gxf.^2+Gyf.^2);
[Gxb,Gyb]=imgradientxy(prob_b_map);
Mag_grad_b=sqrt(Gxb.^2+Gyb.^2);

%calc geodesic distance for foreground and background
Tf=graydist(Mag_grad_f,Yf,Xf);
Tb=graydist(Mag_grad_b,Yb,Xb);

%create trimap
for i=1:size(Tf,1)
    for j=1:size(Tf,2)
        if(Tf(i,j)-Tb(i,j)<=0)
            trimap(i,j)=1;
        else
            trimap(i,j)=0;
        end
    end
end

%close holes in foreground object:
trimap=imdilate(trimap,strel('disk',6));
trimap=imerode(trimap,strel('disk',6));

%create narrowband:
perim=bwperim(trimap);
Narrow_Band = imdilate(perim,strel('disk',3));

%calculate alpha map:
NB_perim=bwperim(Narrow_Band);

[NB_perim_rows,NB_perim_cols]=find(NB_perim);
NB_geo_distF=graydist(Mag_grad_f,NB_perim_cols,NB_perim_rows);
NB_geo_distB=graydist(Mag_grad_b,NB_perim_cols,NB_perim_rows);

Wf=((NB_geo_distF)).*(prob_f_map);
Wb=((NB_geo_distB)).*(prob_b_map);

alpha=factor*Wf./(factor*Wf+Wb); 
alpha(isnan(alpha))=BinFrame(isnan(alpha));

%build each result frame:
res=zeros(size(F));
res(:,:,1)=alpha.*F(:,:,1)+(1.-alpha).*B(:,:,1); 
res(:,:,2)=alpha.*F(:,:,2)+(1.-alpha).*B(:,:,2); 
res(:,:,3)=alpha.*F(:,:,3)+(1.-alpha).*B(:,:,3); 

%Write result into output video and continue to next frame:
writeVideo(MattedVid,(res));

waitbar(FrameIdx/NumOfFrames,w);
end

%release files:
close(w);
%release(vid);
close(MattedVid);
%release(BinVid);
















