function Matting(Input, InputBinary, Background, Output, WidthOfNarrowBand)
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
% Input='stabilized.avi';InputBinary='extracted.avi';Background=
% 'background.jpg';Output= 'matted.avi';WidthOfNarrowBand=3;

% Creating I/O objects & Initializing parameters:
InputFile = sprintf('../Output/%s', Input);
InputBinaryFile = sprintf('../Output/%s', InputBinary);
OutputFile = sprintf( '../Output/%s', Output);
InputBackground = sprintf( '../Input/%s', Background);
InputReader = VideoReader(InputFile);
InputBinaryReader = VideoReader(InputBinaryFile);
Frames = InputReader.NumberOfFrames;
Width = InputReader.Width;
Height = InputReader.Height;
videoWriter = VideoWriter(OutputFile);
open(videoWriter);

% Resizing background due to the video size:
BackgroundImage = imread(InputBackground);
BackgroundImage = imresize(BackgroundImage, [Height Width]);
BackgroundImage = double(BackgroundImage)/255;

% Waitbar:
h = waitbar(0,'Matting Progress:');

% Matting initialization:
RefFrame = read(InputReader, 1);
RefBinary = read(InputBinaryReader, 1);
RefBinaryV = im2bw(RefBinary);

% Sampling foreground and background for histogram calculation:
[FGXIndices, FGYIndices] = find(RefBinaryV == 0); [BGXIndices, BGYIndices] = find(RefBinaryV == 1);
[FGIndicesNum,~] = size(FGXIndices); [BGIndicesNum,~] = size(BGXIndices);
NumOfSamples = min(floor(FGIndicesNum/50),floor(BGIndicesNum/50));
SamplesFG = randsample(1:FGIndicesNum,NumOfSamples); SamplesBG = randsample(1:BGIndicesNum,NumOfSamples);
FG_Sampled_X_Indices = FGXIndices(SamplesFG); BG_Sampled_X_Indices = BGXIndices(SamplesBG); 
FG_Sampled_Y_Indices = FGYIndices(SamplesFG); BG_Sampled_Y_Indices = BGYIndices(SamplesBG);

% Histogram calculation for foreground and background:
PixelValues = 0:255;
RefFrameHSV = rgb2hsv(RefFrame);
RefVFrame = RefFrameHSV(:,:,3)*255;
FGscribbleColors = RefVFrame(FG_Sampled_X_Indices,FG_Sampled_Y_Indices);
[FG_Dens,~]=ksdensity(FGscribbleColors(:),PixelValues);
BGscribbleColors = RefVFrame(BG_Sampled_X_Indices, BG_Sampled_Y_Indices);
[BG_Dens,~]=ksdensity(BGscribbleColors(:),PixelValues);

% Iterating over the frames and matting the object and background
for Frame=1:Frames
    
    % Getting a new frame:
    CurrFrameRGB = double(read(InputReader, Frame))/255;
    CurrFrameHSV = rgb2hsv(CurrFrameRGB);
    CurrVFrame   = CurrFrameHSV(:,:,3);
	CurrBinaryFrame = im2bw(read(InputBinaryReader, Frame));
	
	% Finding perimeter and widenning the object (narrow band):
	NB = imdilate(bwperim(CurrBinaryFrame), strel('disk', WidthOfNarrowBand, 0));
	NB_VALUES = double(CurrVFrame).*double(NB);

	% Calculating likelihood:
    NB_Indices = find(NB_VALUES == 0);
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
    writeVideo(videoWriter, MattedFrame);
    waitbar(Frame/Frames);
end

close(videoWriter);
close(h);
end