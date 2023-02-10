function setOptsDoubleValueStrInGUI(handles, options, optPropName, handlesFieldName)
    value = options.(optPropName);
    
    if(isnan(value))
        str = '';
    else
        str = fullAccNum2Str(double(value));
    end
    
    handles.(handlesFieldName).String = str;