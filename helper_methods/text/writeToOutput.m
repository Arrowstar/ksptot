function writeToOutput(handle,str,msgType, varargin)
    if(~isempty(varargin))
        maxlength = varargin{1};
    else
        maxlength=105;
    end

    try
        curStr=char(get(handle,'String'));
    catch
        curStr=char(handle.Value);
    end
            
    if(strcmpi(msgType,'append'))
        str=char(str);
        strToWrite=char(curStr,str);

    elseif(strcmpi(msgType,'appendSameLine'))
        str=char([strtrim(curStr(end,:)),str]);
        strToWrite=char(curStr(1:end-1,:),str);

    elseif(strcmpi(msgType,'overwrite'))
        str=char(str);
        strToWrite=str;

    elseif(strcmpi(msgType,'error'))
        str=char(str);
        strToWrite=char(curStr,str);
        
        set(handle,'BackgroundColor',[1 0.7 0.7])
        beep;
    elseif(strcmpi(msgType,'clear'))
%         hr = {repmat('#',1,10000)};
        hr = getLVD_HR(handle);
        
        strToWrite = {'                                                       KSP Trajectory Optimization Tool',...
            '                                            Written by Arrowstar", (C) 2021',...
            hr};
        set(handle,'BackgroundColor',[1 1 1])
        
    elseif(strcmpi(msgType,'resetBGColor'))
        set(handle,'BackgroundColor',[1 1 1])
        
    elseif(strcmpi(msgType,'clearDAT'))
        strToWrite = {'                                                    Departure Analysis Tool',...
                             '##################################################################'};
        set(handle,'BackgroundColor',[1 1 1])
    end
    
    strToWriteStr = cellstr(string(strToWrite));

    try
        lblStrCell = textwrap(handle,strToWriteStr);
        set(handle,'String',lblStrCell);
    catch ME
        try
            set(handle,'String',strToWriteStr);
        catch
            try
                handle.Value = strToWriteStr;
            catch ME
                a=1;
            end
        end
    end
    
    drawnow;
end