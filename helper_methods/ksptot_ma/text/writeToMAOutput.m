function writeToMAOutput(handle,str,msgType,output_text_max_line_length)
%writeToMAOutput Summary of this function goes here
%   Detailed explanation goes here
    if(strcmpi(msgType,'append'))
        date = datestr(now,' (HH:MM:SS) ');
    else
        date = '';
    end
    
    if(strcmpi(msgType,'appendNoDate'))
        msgType = 'append';
    end
    
    str = [date,str];
    writeToOutput(handle, str, msgType, output_text_max_line_length);
end

