function errMsg = validateDoubleValue(handles, errMsg, handlesFieldName, numberName, lb, ub, isInt)
    strValue = strtrim(get(handles.(handlesFieldName),'String'));
    
    if(~isempty(strValue)) %allow empty, implies default
        value = str2double(strValue);
        enteredStr = get(handles.(handlesFieldName),'String');
        errMsg = validateNumber(value, numberName, lb, ub, isInt, errMsg, enteredStr);
    end
end