function S_next = predictParticles(S_next_tag,maxPixelMovment)

[rows,cols]=size(S_next_tag);
%add noise
maxPixelMovment=30;
noiseMat= randi(maxPixelMovment,rows,cols) - maxPixelMovment/2;
% The height and width stay the same
noiseMat(3:4,:)=0;
%the speed value doesn't needs to get accoumlted value
S_next_tag(5:6,:)=0;
S_next=noiseMat+S_next_tag;

end
