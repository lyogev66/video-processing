function imgOut = showParticles(I,S,W)


    AvgPartical=mean(S,2);

if ~isempty(AvgPartical)
    %creating the rectangle according to location and size of object
    %drawing a green rectangle - Average partical
    Yll=max(AvgPartical(2)-AvgPartical(4),1);
    Xll=max(AvgPartical(1)-AvgPartical(3),1);
    greenRect=[Xll,Yll,(2*AvgPartical(3)),(2*AvgPartical(4))];    %[X,Y width,height]
    imgOut = insertShape(I,'Rectangle',greenRect,'Color','green');
    %excluding the Max Partical due to it's jitter
%     maxWight= max(W)==W;
%     MaxPartical=S(:,maxWight);    
     %drawing a red rectangle - Maximal Partical
%     Yll=max(MaxPartical(2)-MaxPartical(4),1);
%     Xll=max(MaxPartical(1)-MaxPartical(3),1);
%     redRect=[Xll,Yll,(2*MaxPartical(3)),(2*MaxPartical(4))];    %[X,Y width,height]    
%     imgOut = insertShape(imgOut,'Rectangle',redRect,'Color','red');
else
    imgOut = I;

end

