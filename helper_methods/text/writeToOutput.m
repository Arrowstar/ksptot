function writeToOutput(handle,str,msgType, varargin)
    if(~isempty(varargin))
        maxlength = varargin{1};
    else
        maxlength=105;
    end

    curStr=char(get(handle,'String'));
    textRows=size(curStr,1);
    
    if(strcmpi(msgType,'append'))
        str=char(linewrap(str, maxlength));
        strToWrite=char(curStr,str);
        set(handle,'String',strToWrite);
    elseif(strcmpi(msgType,'appendSameLine'))
        str=char(linewrap(str, maxlength));
        strToWrite=char(curStr(1:end-1,:),[strtrim(curStr(end,:)),str]);
        set(handle,'String',strToWrite);
    elseif(strcmpi(msgType,'overwrite'))
        str=char(linewrap(str, maxlength));
        strToWrite=str;
        set(handle,'String',strToWrite);
    elseif(strcmpi(msgType,'error'))
        str=char(linewrap(str, maxlength));
        strToWrite=char(curStr,str);
        set(handle,'String',strToWrite);
        set(handle,'BackgroundColor',[1 0.7 0.7])
        beep;
    elseif(strcmpi(msgType,'clear'))
        set(handle,'String',{'                                                       KSP Trajectory Optimization Tool',...
            '                                            Written by Arrowstar", (C) 2018',...
            '#####################################################################'});
        set(handle,'BackgroundColor',[1 1 1])
    elseif(strcmpi(msgType,'resetBGColor'))
        set(handle,'BackgroundColor',[1 1 1])
    elseif(strcmpi(msgType,'clearDAT'))
        set(handle,'String',{'                                                    Departure Analysis Tool',...
                             '##################################################################'});
        set(handle,'BackgroundColor',[1 1 1])
    end
    drawnow;
end