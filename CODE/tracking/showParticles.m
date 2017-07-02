function imgOut = showParticles(I,S,W)


    AvgPartical=mean(S,2);
    maxWight= max(W)==W;
    MaxPartical=S(:,maxWight);
if ~isempty(MaxPartical)
    %creating the rectangle according to location and size of object
    Yll=max(AvgPartical(2)-AvgPartical(4),1);
    Xll=max(AvgPartical(1)-AvgPartical(3),1);
    greenRect=[Xll,Yll,(2*AvgPartical(3)),(2*AvgPartical(4))];    %[X,Y width,height]

    %drawing a green rectangle - Average partical
    Yll=max(MaxPartical(2)-MaxPartical(4),1);
    Xll=max(MaxPartical(1)-MaxPartical(3),1);
    redRect=[Xll,Yll,(2*MaxPartical(3)),(2*MaxPartical(4))];    %[X,Y width,height]

    %drawing a red rectangle - Maximal Partical
    imgOut = insertShape(I,'Rectangle',greenRect,'Color','green');
    imgOut = insertShape(imgOut,'Rectangle',redRect,'Color','red');
else
    imgOut = I;

end

