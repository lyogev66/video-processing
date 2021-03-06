function Matting(StableVid, BinaryVid, backgroundImage, Output, WidthOfNarrowBand)

backgroundImage = 'background.jpg';
StableVid = 'stabilized.avi';
BinaryVid = 'binary.avi';
Output = 'matted.avi';
WidthOfNarrowBand = 3;
SElement = strel('disk', WidthOfNarrowBand);
SElementBoarder = strel('disk', 3*WidthOfNarrowBand);
factor = 1; %addtional factor for background vs foreground

% Creating I/O objects & Initializing parameters:
InputBackground = sprintf( '../Input/%s', backgroundImage);
InputFile = sprintf('../Output/%s', StableVid);
InputBinaryFile = sprintf('../Output/%s', BinaryVid);


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

% starting algorithm

h = waitbar(0, 'Matting, Please Wait...');
for FrameCount=1:NumberOfFrames
    waitbar(FrameCount/NumberOfFrames, h);
    % Getting a new frame:
    CurrFrameRGB = (dataBaseStable{FrameCount});
    CurrFrameGray = uint8(rgb2gray(CurrFrameRGB));
    CurrFrameRGB = im2double(CurrFrameRGB);
	CurrBinaryFrame = imbinarize(rgb2gray(dataBaseExtracted{FrameCount}));
	BinImage = imfill(CurrBinaryFrame,'holes');

%     InsideIndicator = (BinImage==1);
%     OutsideIndicator = (BinImage~=1) ;

    Perimiter = bwperim(BinImage==1);
    PerimiterDilated = double(imdilate(Perimiter, SElement));
    trimap = double(BinImage); trimap(PerimiterDilated==1) =0.5;
    
    InsideBordrer = BinImage - imerode(imerode(BinImage,SElementBoarder),SElementBoarder);
    InsideBordrer(InsideBordrer == PerimiterDilated) = 0;
%     ;InsideBordrer(imerode(Outside,SElement)==1) = 0;InsideBordrer(Perimiter==1) = 0.5;
    OutsideBorder = imdilate(BinImage,SElementBoarder) - BinImage;
    OutsideBorder(PerimiterDilated==1) = 0;
%     PerimiterDilated;OutsideBorder(imerode(Inside,SElement)==1) = 0;OutsideBorder(Perimiter==1) = 0.5;
%     imshowpair(InsideBordrer,OutsideBorder,'montage')
    
    % getting the value of the inside and outside pixels and calculating
    % their KDE
    InsideValues = CurrFrameGray(InsideBordrer==1);
    OutsideValues = CurrFrameGray(OutsideBorder==1);
    
    % getting a mapping of 256 bins to convert the values later on
    [~,ProbMapIn,~,~] = kde(InsideValues,256,0,255);
    [~,ProbMapOut,~,~] = kde(OutsideValues,256,0,255);
    

    %using the values of each pixel inside the probability function and
    %adding 1 to get all values to at least 1 ( to get Prob(x))
    x = (CurrFrameGray)+1 ; 
    %Calculate PDF for Foreground using Bayes Rule
    PdfFg = ProbMapIn(x) ./ (ProbMapIn(x) + ProbMapOut(x));
    % the Background PDF
    PdfBg = 1-PdfFg;

%     imshowpair(PdfFg,PdfBg,'montage')
    

    %Calculat the discrete weighted Geodesic distance
    Df = graydist(imgradientxy(PdfFg), InsideBordrer==1); 
    Db = graydist(imgradientxy(PdfBg), OutsideBorder==1);
    
%     imshow(Df,[])
%     imshow(Db,[])   
    r = 2;  % r in [0-2] according to Alex lecture
    Wf = PdfFg(x) ./ (Df(x).^r) ;
    Wb = PdfBg(x) ./(Db(x).^r);
%     imshow(Wf,[])
%     imshow(Wb,[])
    
    alpha = (factor * Wf./(factor * Wf+Wb));
    alpha = alpha/max(max(alpha));
%     imshow(alpha)
    % merging the backgound and the frame
    fix = ones(size(trimap));
    fix(trimap ==1) =0;fix(trimap ==0) =0;
    trimap(fix ==1 ) = alpha(fix ==1);
%     imshow(trimap);

    % blending
    

    FrameFg = zeros(size(CurrFrameRGB));
    FrameBg = zeros(size(BackgroundImage));
    for channel=1:3
        FrameFg(:,:,channel) = trimap.* CurrFrameRGB(:,:,channel);
        FrameBg(:,:,channel) = (1-trimap).* (BackgroundImage(:,:,channel));
    end
        

%     imshowpair(BGFrame,FGFrame,'blend')
    % fixing value overflow
    MattedFrame = FrameFg + FrameBg;
    MattedFrame(MattedFrame>1)=1;MattedFrame(MattedFrame<0)=0;

    writeVideo(hVideoOut, MattedFrame);
%      imshow(MattedFrame)
end

close(hVideoOut);
close(h);
end