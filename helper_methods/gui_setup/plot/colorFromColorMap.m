function colorToPlot = colorFromColorMap(bColor)
    cmap = colormap(bColor);
    midRow = round(size(cmap,1)/2);
    bColorRGB = cmap(midRow,:);
    colorToPlot = bColorRGB;
end