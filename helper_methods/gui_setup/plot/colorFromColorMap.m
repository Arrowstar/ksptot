function colorToPlot = colorFromColorMap(bColor)
    try
        cmap = colormap(bColor);
        midRow = round(size(cmap,1)/2);
        bColorRGB = cmap(midRow,:);
        colorToPlot = bColorRGB;
    catch ME
        colorToPlot = [0.5 0.5 0.5];
    end
end