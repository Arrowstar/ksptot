function value = findValueFromComboBox(itemStr, hCombo)
%findValueFromComboBox Summary of this function goes here
%   Detailed explanation goes here
    contents = cellstr(get(hCombo,'String'));
    
    for(i=1:length(contents)) %#ok<*NO4LP>
        content = contents{i};
        if(strcmpi(strtrim(content), strtrim(itemStr)))
            value = i;
            return;
        end
    end
    
    value = [];
end

