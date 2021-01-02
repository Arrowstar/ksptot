function colorStr = getStringFromLineSpecColor(lineSpecColor)    
    if(strcmpi(lineSpecColor,'r'))
        colorStr = 'Red';
        
    elseif((isnumeric(lineSpecColor) && all(lineSpecColor == [178,0,255]/255)) || (ischar(lineSpecColor) && strcmpi(lineSpecColor,'m')))
        colorStr = 'Magenta';
        
	elseif(lineSpecColor == [255,131,0]/255)
        colorStr = 'Orange';
        
    elseif((isnumeric(lineSpecColor) && all(lineSpecColor == [255,216,0]/255)) || (ischar(lineSpecColor) && strcmpi(lineSpecColor,'y')))
        colorStr = 'Yellow';

    elseif((isnumeric(lineSpecColor) && all(lineSpecColor == [76,220,0]/255)) || (ischar(lineSpecColor) && strcmpi(lineSpecColor,'g')))
        colorStr = 'Green';
        
    elseif((isnumeric(lineSpecColor) && all(lineSpecColor == [0,210,255]/255)) || (ischar(lineSpecColor) && strcmpi(lineSpecColor,'c')))
        colorStr = 'Cyan';
        
	elseif(strcmpi(lineSpecColor,'b'))
        colorStr = 'Blue';
        
	elseif(strcmpi(lineSpecColor,'k'))
        colorStr = 'Black';
        
	elseif(strcmpi(lineSpecColor,'w'))
        colorStr = 'White';
        
	elseif(lineSpecColor == [255,0,220]/255)
        colorStr = 'Pink';
        
	elseif(lineSpecColor == [139,69,19]/255)
        colorStr = 'Brown';
        
    else
        colorStr = 'Black';
        warning(['Did not recongize line spec color string: ', num2str(lineSpecColor)]);
    end
end