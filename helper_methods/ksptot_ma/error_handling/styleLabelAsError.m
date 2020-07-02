function styleLabelAsError(hLabel, errorStr)
%styleLabelAsError Summary of this function goes here
%   Detailed explanation goes here
    strMax = min(52,length(errorStr));
    
    if(length(errorStr) > 52)
        appendStr = '...';
    else
        appendStr = '';
    end
    
    set(hLabel,'Visible','on');
    set(hLabel,'BackgroundColor',[0.847,0.161,0]);
    set(hLabel,'ForegroundColor',[1,1,1]);
    set(hLabel,'String',[errorStr(1:strMax),appendStr]);
    set(hLabel,'TooltipString',errorStr);
    set(hLabel,'FontWeight','bold');
end

