function value = findValueFromComboBox(itemStr, hCombo)
%findValueFromComboBox Summary of this function goes here
%   Detailed explanation goes here
    contents = cellstr(get(hCombo,'String'));
    
    for(i=1:length(contents))
        content = contents{i};
        if(strcmpi(deblank(content), deblank(itemStr)))
            value = i;
            return;
        end
    end
    
    value = [];
end

