function styleLabelAsWarn(hLabel,warnStr)
%styleLabelAsWarn Summary of this function goes here
%   Detailed explanation goes here
    lblStr = strWrapForLabel(hLabel, warnStr);
    
    set(hLabel,'Visible','on');
    set(hLabel,'BackgroundColor',[1,1,0]);
    set(hLabel,'ForegroundColor',[0,0,0]);
    set(hLabel,'String',lblStr);
    set(hLabel,'TooltipString',warnStr);
    set(hLabel,'FontWeight','bold');
end