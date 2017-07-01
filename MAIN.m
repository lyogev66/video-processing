
%% MAIN function for final project
%% this script is writen by Niv Wiesman and Yogev Laks

close all; clc; clearvars;
ID = 'GROUP_XX_YY'; % FIX THIS LINE - LEAVE IT AS A STRING!
%%%%%%%%%%%PART 1: Video Stabilization%%%%%%%%%%%%%%%
vidName = 'name.avi';
stableVid = VideoStabilizer(vidName);
%stableVid='';
[binaryVid,stableSubstructVid] = BackgroundSubstract(stableVid);
backgroundImage = '';
mattedVid = Matter(backgroundImage,binaryVid,stableSubstructVid);
OutputVid = Tracker(mattedVid);