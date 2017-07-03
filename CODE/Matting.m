function Matting(StableVid, BinaryVid, backgroundImage, MattedVid, WidthOfNarrowBand)

% default parameters
% backgroundImage = 'background.jpg';
% StableVid = 'stabilized.avi';
% BinaryVid = 'binary.avi';
% MattedVid = 'matted.avi';
% WidthOfNarrowBand = 1;

hVideoStable = VideoReader(sprintf('../Output/%s', StableVid));
hVideoBinary = VideoReader(sprintf('../Output/%s', BinaryVid));
ApproxNumberOfFrames = (hVideoStable.Duration*hVideoStable.FrameRate-1);


[dataBaseStable,NumberOfFramesStable] = LoadDB(hVideoStable,ApproxNumberOfFrames);
[dataBaseBinary,NumberOfFramesExtracted] = LoadDB(hVideoBinary,ApproxNumberOfFrames);

NumberOfFrames = min(NumberOfFramesStable, NumberOfFramesExtracted);
[Height,Width,~]= size(dataBaseStable{1});

% Resizing background due to the video size:
Background = imread(sprintf( '../Input/%s', backgroundImage));
Background = double(imresize(Background, [Height Width]));

%creating Structuring element
SElement = strel('disk', WidthOfNarrowBand);

% opening output video
hVideoOut = VideoWriter(sprintf( '../Output/%s', MattedVid));
hVideoOut.Quality = 100;
hVideoOut.FrameRate = hVideoStable.FrameRate;
open(hVideoOut);

h = waitbar(0, 'Matting, Please Wait...');
for FrameCount=1:NumberOfFrames
    waitbar(FrameCount/NumberOfFrames, h);

    % Read current frame from Stable and Binary video
    frame = dataBaseStable{FrameCount};
    grayImg = rgb2gray(frame);
    binImg = im2bw(dataBaseBinary{FrameCount});

    %creating trimap
    %Find perimeter of object in binary image widen it and make it as
    %the trimap in the binary image ( i.e it will be an undecided zone)
    perim = bwperim(binImg);
    perim = imdilate(perim, SElement); 
    trimap = double(binImg);
    trimap(perim == 1) = 0.5; 

    %Creating an outer and inner borders for the binary image
    InnerBorder = (binImg - imerode(binImg,SElement));
    OuterBorder = (imdilate(binImg,SElement) - binImg);       
    trimap(OuterBorder == 1) = 0;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
    %Define 'scribbles' for FG and BG:
    FG_Mask = (InnerBorder == 1);
%         imshow(FG_Mask);
    scribbles_FG = grayImg(FG_Mask);

    BG_Mask = (OuterBorder == 1);
%         imshow(BG_Mask);       
    scribbles_BG = grayImg(BG_Mask);

    %Estimate probability map using KDE function:
    [~,Pr_C_FG,~,~] = kde(scribbles_FG, 256, 0, 255);
    [~,Pr_C_BG,~,~] = kde(scribbles_BG, 256, 0, 255);

    %Calculate PDFs using Bayes equation:
    i = grayImg+1;
    Pr_FG = Pr_C_FG(i) ./ (Pr_C_FG(i) + Pr_C_BG(i));
    Pr_BG = 1-Pr_FG;

    %Calculate Gradient:
    Grad_FG = imgradientxy(Pr_FG);
    Grad_BG = imgradientxy(Pr_BG);

    %Calculat the discrete weighted Geodesic distance:
    Df = graydist(Grad_FG, FG_Mask); %computes the gray-weighted distance transform of the grayscale image
    Db = graydist(Grad_BG, BG_Mask);
    %imshow (Df);
    %imshow (Db);

    %%%%%%%%%%%%%%Step (2) - Refinement: %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    Wf = Pr_FG(i) ./ (Df(i) .^ WidthOfNarrowBand);
    Wb = Pr_BG(i) ./ (Db(i) .^ WidthOfNarrowBand);

    Alpha = Wf ./ (Wf + Wb);

    %%%%%%%%%%%%%%Step (3) - T' generation: %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    AlphaTrimap = double(trimap);
%         imshow(Alpha);
%         imshow(Alpha_Trimap);
    AlphaTrimap(trimap == 0.5) = Alpha(trimap == 0.5);
%         imshow(Alpha_Trimap);

    % blending
    AlphaColors = cat(3, AlphaTrimap, AlphaTrimap, AlphaTrimap);
    FGFrame = uint8(AlphaColors .* double(frame));
    BGFrame = uint8((1-AlphaColors).* (Background));
%     imshowpair(BGFrame,FGFrame,'blend')
    Matted_Frame = FGFrame + BGFrame;
%     imshow (Matted_Frame)
%         imshow( uint8(Matted_Frame));
    writeVideo(hVideoOut, Matted_Frame);
end
close(h);
close(hVideoOut);
end