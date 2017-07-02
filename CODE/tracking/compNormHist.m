function normHist = compNormHist(I,s)

Yc=int32(s(2));Xc=int32(s(1));
half_width=int32(s(3));half_height=int32(s(4));   
% getting the object pixels
%fix minimal indicats
y_start = max(Yc-half_height,1);y_end = min(Yc+half_height,size(I,1));
x_start = max(Xc-half_width,1);x_end = min(Xc+half_width,size(I,2));
I_sub = I(((y_start):(y_end)),((x_start):(x_end)),:);
% ErrorErrorErrorErrorErrorErrorErrorError

%doing a quantization
rect_quant=uint8(floor(I_sub./17)+1);

%creating the histogram
normHist = zeros(4096,1);
for row = 1:size(rect_quant,1)
    for col= 1:size(rect_quant,2)
    red = int32(rect_quant(row,col,1));
    green = int32(rect_quant(row,col,2));
    blue = int32(rect_quant(row,col,3));
    barLocation=(red-1)*256+(green-1)*16+blue;
    normHist(barLocation) = normHist(barLocation)+1;
    end
end
%normalizing the histogram
normHist = normHist./sum(normHist);

end
