function imgOut = showParticles(I,S,W)


AvgPartical=mean(S,2);
maxWight= max(W)==W;
MaxPartical=S(:,maxWight);

%creating the rectangle according to location and size of object
Yll=AvgPartical(2)-AvgPartical(4);
Xll=AvgPartical(1)-AvgPartical(3);
greenRect=[Xll,Yll,(2*AvgPartical(3)),(2*AvgPartical(4))];    %[X,Y width,height]

%drawing a green rectangle - Average partical
Yll=MaxPartical(2)-MaxPartical(4);
Xll=MaxPartical(1)-MaxPartical(3);
redRect=[Xll,Yll,(2*MaxPartical(3)),(2*MaxPartical(4))];    %[X,Y width,height]

%drawing a red rectangle - Maximal Partical
imgOut = insertShape(I,'Rectangle',greenRect,'Color','green');
imgOut = insertShape(imgOut,'Rectangle',redRect,'Color','red');

end

