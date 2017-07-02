
%% MAIN function for final project
%% this script is writen by Niv Wiesman and Yogev Laks

close all; clc; clearvars;
%%
%all the scripts assume that the Input and Output are allready created
% and contatins the required files
%%
%%%%%%%%%%%PART 1: Video Stabilization %%%%%%%%%%%%%%%
InputFile = 'INPUT.avi';
StableVid = 'stabilized.avi';
% stablizerParam.MinContrast=0.3;
stablizerParam.MinQuality=0.2;
cropParam.facor = 0.3;
Stabilize(InputFile,StableVid,stablizerParam,cropParam);
%%
%%%%%%%%%%%PART 2: Background Subtraction %%%%%%%%%%%%%%%
close all; clc; clearvars;
StableVid = 'stabilized.avi';
Binary = 'binary.avi';
ExtractedVid = 'extracted.avi';
BackgroundSubstract(StableVid,Binary,ExtractedVid);
%%
%%%%%%%%%%%PART 3: Matting %%%%%%%%%%%%%%%
close all; clc; clearvars;
backgroundImage = 'background.jpg';
StableVid = 'stabilized.avi';
BinaryVid = 'binary.avi';
MattedVid = 'matted.avi';
WidthOfNarrowBand = 3;

Matting(StableVid, BinaryVid, backgroundImage, MattedVid, WidthOfNarrowBand)
%%
%%%%%%%%%%%PART 4: Tracking %%%%%%%%%%%%%%%
close all; clc; clearvars;
MattedVid = 'matted.avi';
outVid = 'output.avi';
TrackParam.maxMovment = 3;
TrackParam.Particals = 100;
TrackParam.chooseRectFrame = 3;

Tracker(MattedVid,outVid,TrackParam);