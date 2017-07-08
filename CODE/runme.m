
%% MAIN function for final project
%% this script is writen by Niv Wiesman and Yogev Laks

close all; clc; clearvars;
%%
% all the scripts assume that the Input and Output  folders are already created
% and contatins the required files
%%
%%%%%%%%%%% PART 1: Video Stabilization %%%%%%%%%%%%%%%
close all; clearvars;
InputFile = 'INPUT.avi';
StableVid = 'stabilized.avi';
% the maximal distance between two points - for more jittery video use
% higher value
stablizerParam.MaxDistance = 1;
stablizerParam.type = 'similarity'; % 'affine' for less shaky 'similarity' for shaky video
stablizerParam.MinQuality = 0.2;  % use arround 0.2
stablizerParam.MinContrast = 0.01;  % use below 0.1 value to get more points
% precentage from video borders to crop [0-1]-> 10% -100%
cropParam.facor = 0.1;
Stabilize(InputFile,StableVid,stablizerParam,cropParam);



%%
%%%%%%%%%%% PART 2: Background Subtraction %%%%%%%%%%%%%%%
close all; clearvars;
StableVid = 'stabilized.avi';
Binary = 'binary.avi';
ExtractedVid = 'extracted.avi';
BackgroundSubstract(StableVid,Binary)
% BackgroundSubstract(StableVid,Binary,ExtractedVid);
%%
%%%%%%%%%%% PART 3: Matting %%%%%%%%%%%%%%%
close all; clearvars;
% backgroundImage = 'background.jpg';
% StableVid = 'stabilized.avi';
% BinaryVid = 'binary.avi';
% MattedVid = 'matted.avi';
% WidthOfNarrowBand = 3;

backgroundImage = 'background.jpg';
StableVid = 'stabilized.avi';
BinaryVid = 'binary.avi';
MattedVid = 'matted.avi';
WidthOfNarrowBand = 3;
factor = 1; %addtional factor for background vs foreground


Matting(StableVid, BinaryVid, backgroundImage, MattedVid, WidthOfNarrowBand)
%%
%%%%%%%%%%% PART 4: Tracking %%%%%%%%%%%%%%%
close all; clearvars;
MattedVid = 'matted.avi';
outVid = 'output.avi';
TrackParam.maxMovment = 30;
TrackParam.Particals = 100;
%is by any chance the object does not apper at the first frame choose the
%first frame that the object appears in
TrackParam.chooseRectFrame = 1;

Tracker(MattedVid,outVid,TrackParam);