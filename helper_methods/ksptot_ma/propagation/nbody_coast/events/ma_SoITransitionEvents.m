function [value,isterminal,direction,eventDesc] = ma_SoITransitionEvents(T,Y, bodyInfo, celBodyData)
%ma_SoITransitionEvents Summary of this function goes here
%   Detailed explanation goes here
    value = [];
    isterminal = [];
    direction = [];
    
    rVect = Y(1:3);
    
    eventDesc = {};
    
    %First do upwards transition
	parentBodyInfo = getParentBodyInfo(bodyInfo, celBodyData);
    if(~isempty(parentBodyInfo))
        soiRadius = getSOIRadius(bodyInfo, parentBodyInfo);
        
        value(end+1) = soiRadius - norm(rVect);
        isterminal(end+1) = 1;
        direction(end+1) = -1;
        
        eventDesc{end + 1} = 'SoI Transition Up';
    end
    
    %Then do downwards transitions
    [children, ~] = getChildrenOfParentInfo(celBodyData, bodyInfo.name);
    for(i=1:length(children)) %#ok<*NO4LP>
        childBodyInfo = children{i};
        [rVectChild, ~] = getStateAtTime(childBodyInfo, T, bodyInfo.gm);
        soiRadiusChild = getSOIRadius(childBodyInfo, bodyInfo);
        
        scDistFromChild = norm(rVectChild - rVect);
        
        value(end+1) = scDistFromChild - soiRadiusChild; %#ok<AGROW>
        isterminal(end+1) = 1; %#ok<AGROW>
        direction(end+1) = -1; %#ok<AGROW>
        
        eventDesc{end + 1} = ['SoI Transition Down (',childBodyInfo.name, ' - ', num2str(childBodyInfo.id), ')']; %#ok<AGROW>
    end
end

