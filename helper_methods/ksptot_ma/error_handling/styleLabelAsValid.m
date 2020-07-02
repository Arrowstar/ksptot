function styleLabelAsValid(hLabel,validStr)
%styleLabelAsValid Summary of this function goes here
%   Detailed explanation goes here
    strMax = min(52,length(validStr));
    
    if(length(validStr) > 52)
        appendStr = '...';
    else
        appendStr = '';
    end
    
    set(hLabel,'Visible','on');
    set(hLabel,'BackgroundColor',[34,139,34]/255);
    set(hLabel,'ForegroundColor',[1,1,1]);
    set(hLabel,'String',[validStr(1:strMax),appendStr]);
    set(hLabel,'TooltipString',validStr);
    set(hLabel,'FontWeight','bold');
end

