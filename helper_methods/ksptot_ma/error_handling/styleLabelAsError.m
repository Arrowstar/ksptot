function styleLabelAsError(hLabel, errorStr)
%styleLabelAsError Summary of this function goes here
%   Detailed explanation goes here
    lblStr = strWrapForLabel(hLabel, errorStr);
    
    set(hLabel,'Visible','on');
    set(hLabel,'BackgroundColor',[0.847,0.161,0]);
    set(hLabel,'ForegroundColor',[1,1,1]);
    set(hLabel,'String',lblStr);
    set(hLabel,'TooltipString',errorStr);
    set(hLabel,'FontWeight','bold');
end

