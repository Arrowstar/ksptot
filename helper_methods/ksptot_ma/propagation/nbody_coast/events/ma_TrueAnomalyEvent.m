function [value,isterminal,direction,eventDesc] = ma_TrueAnomalyEvent(T,Y, truTarget, bodyInfo, refBody, celBodyData)
    if(strcmpi(T, 'getInfo'))
        value = truTarget;
        isterminal = bodyInfo;
        direction = refBody;
        eventDesc = [];
        
        return;
    end
   
	if(~isempty(refBody) && bodyInfo.id ~= refBody.id)
        value = [];
        isterminal = [];
        direction = [];
        eventDesc = {};
        
        return
	end

    rVect = Y(1:3);
    vVect = Y(4:6);

    topLevelBodyInfo = getTopLevelCentralBody(celBodyData);
    bodyInfoSun = topLevelBodyInfo;
    [rVect,vVect] = getAbsPositBetweenSpacecraftAndBody(T, rVect, bodyInfoSun, bodyInfo, celBodyData, vVect);
    
    [~, ~, ~, ~, ~, tru] = getKeplerFromState(-rVect, -vVect, bodyInfo.gm, true);
    
    if(abs(rad2deg(truTarget)) < 30 && abs(rad2deg(angleNegPiToPi(tru))) < 30)
        tru = angleNegPiToPi(tru);
    end

    value = tru - truTarget;
    isterminal = 1;
    direction = 1;
    
    %fprintf('%f - %f - %f - %f\n', T, tru, truTarget, value);
    
    eventDesc = 'True Anomaly';
end