function lineSpecColor = getLineSpecColorFromString(colorStr)
    switch colorStr
        case 'Red'
            lineSpecColor = 'r';
        case 'Magenta'
            lineSpecColor = [178,0,255]/255;
        case 'Orange'
            lineSpecColor = [255,131,0]/255;
        case 'Yellow'
            lineSpecColor = [255,216,0]/255;
        case 'Green'
            lineSpecColor = [76,220,0]/255;
        case 'Cyan'
            lineSpecColor = [0,210,255]/255;
        case 'Blue'
            lineSpecColor = 'b';
        case 'Black'
            lineSpecColor = 'k';
        case 'White'
            lineSpecColor = 'w';
        case 'Pink'
            lineSpecColor = [255,0,220]/255;
        case 'Brown'
            lineSpecColor = [139,69,19]/255;
        otherwise
            lineSpecColor = 'k';
    end
end