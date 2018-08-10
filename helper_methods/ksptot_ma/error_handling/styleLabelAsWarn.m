function styleLabelAsWarn(hLabel,warnStr)
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here
    strMax = min(52,length(warnStr));
    
    if(length(warnStr) > 52)
        appendStr = '...';
    else
        appendStr = '';
    end
    
    set(hLabel,'Visible','on');
    set(hLabel,'BackgroundColor',[1,1,0]);
    set(hLabel,'ForegroundColor',[0,0,0]);
    set(hLabel,'String',[warnStr(1:strMax),appendStr]);
    set(hLabel,'TooltipString',warnStr);
    set(hLabel,'FontWeight','bold');
end

