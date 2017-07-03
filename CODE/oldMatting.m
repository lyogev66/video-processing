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
ExtractedVid = 'extracted.avi';
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