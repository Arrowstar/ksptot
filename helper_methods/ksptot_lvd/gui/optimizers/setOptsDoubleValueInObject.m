function setOptsDoubleValueInObject(handles, options, optPropName, handlesFieldName)
    strValue = strtrim(get(handles.(handlesFieldName),'String'));

    if(~isempty(strValue)) %allow empty, implies default
        value = str2double(strValue);
    else
        value = NaN;
    end
    options.(optPropName) = value;