function checkAerobrakingAltitude(stateLog, script, celBodyData)
%checkAerobrakingAltitude Summary of this function goes here
%   Detailed explanation goes here

    for(i=1:length(script)) %#ok<*NO4LP>
        event = script{i};
        
        if(strcmpi(event.type,'Aerobrake'))
            eventLog = stateLog(stateLog(:,13) == i,:);
            eventLog = eventLog(end,:);
            ut = eventLog(1);
            rVect = eventLog(2:4)';
            bodyID = eventLog(8);
            
            bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
            [~, ~, alt] = getLatLongAltFromInertialVect(ut, rVect, bodyInfo);
            
            if(alt > bodyInfo.atmohgt || alt < 0.0)
                warnStr = sprintf('Aerobraking does not occur in atmosphere. (Altitude: %g km)', alt);
                addToExecutionWarnings(warnStr, i, bodyID, celBodyData);
            end
        end
    end
end

