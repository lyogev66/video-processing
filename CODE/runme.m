
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
stablizerParam.MinContrast=0.3;
stablizerParam.MinQuality=0.2;
cropParam.facor = 0.3;
Stabilize(InputFile,StableVid,stablizerParam,cropParam);
%%
%%%%%%%%%%%PART 2: Background Subtraction %%%%%%%%%%%%%%%

StableVid = 'stabilized.avi';
BackgroundSubstract(stableVid);
%%%%%%%%%%%PART 3: Matting %%%%%%%%%%%%%%%
backgroundImage = '';
Matting(backgroundImage,binaryVid,stableSubstructVid);
%%
%%%%%%%%%%%PART 4: Tracking %%%%%%%%%%%%%%%
close all; clc; clearvars;
mattedVid = 'stabilized.avi';
% mattedVid = 'matted.avi';
outVid = 'output.avi';
TrackParam.maxMovment = 3;
TrackParam.Particals = 100;

Tracker(mattedVid,outVid,TrackParam);