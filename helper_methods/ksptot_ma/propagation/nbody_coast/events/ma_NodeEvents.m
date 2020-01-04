function [value,isterminal,direction,eventDesc] = ma_NodeEvents(T,Y, node, bodyInfo, refBody, celBodyData)
    if(strcmpi(T, 'getInfo'))
        value = node;
        isterminal = bodyInfo;
        direction = refBody;
        eventDesc = [];
        
        return
    end
    
    if(~isempty(refBody) && bodyInfo.id ~= refBody.id)
        value = [];
        isterminal = [];
        direction = [];
        eventDesc = {};
        
        return
    end
    
    rVectECI = Y(1:3);
    
    bodyInfoSun = celBodyData.sun;
    [rVectECI,vVectECI] = getAbsPositBetweenSpacecraftAndBody(T, rVectECI, bodyInfoSun, bodyInfo, celBodyData);
    
    [lat, ~, ~] = getLatLongAltFromInertialVect(T, -rVectECI, bodyInfo, vVectECI);
    
    value = lat;
    isterminal = 1;
    
    if(strcmpi(node,'asc'))
        direction = 1;
    else
        direction = -1;
    end
    
    eventDesc = [upper(node), ' Node'];
end