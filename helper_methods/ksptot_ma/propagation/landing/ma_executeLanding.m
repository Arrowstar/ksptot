function eventLog = ma_executeLanding(landingEvent, initialState, eventNum, celBodyData)
%ma_executeDocking Summary of this function goes here
%   Detailed explanation goes here
    global number_state_log_entries_per_coast;
   
    bodyID = initialState(8);
    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    ut = linspace(initialState(1), initialState(1) + landingEvent.landingDuration, number_state_log_entries_per_coast+1);
    dt = ut(2:end) - ut(1);
    
    rVectECI = initialState(2:4)';
    vVectECI = initialState(5:7)';

    [lat, long, alt, ~, ~, ~] = getLatLongAltFromInertialVect(initialState(1), rVectECI, bodyInfo, vVectECI);
    
    lat = lat * ones(size(ut));
    long = long * ones(size(ut));
    alt = alt * ones(size(ut));
    
    vVectECEF = zeros(3, length(ut)); 
    
    [rVectECI, vVectECI] = getInertialVectFromLatLongAlt(ut, lat, long, alt, bodyInfo, vVectECEF);

    masses = initialState(9:12);
        
    massLoss = landingEvent.massloss;
    if(massLoss.use == 1 && ~isempty(massLoss.lossConvert))
        resRates = ma_getResRates(massLoss);
               
        eventLog = [ut(2:end)', ...
                    rVectECI(:,2:end)', ...
                    vVectECI(:,2:end)', ...
                    landingEvent.bodyID*ones(size(dt')), ...
                    repmat(masses,length(dt),1), ...
                    eventNum*ones(size(dt'))];
                
        for(i=1:length(resRates)) %#ok<*NO4LP>
            eventLog(:,ma_resNumToStateLogCol(i)) = eventLog(1,ma_resNumToStateLogCol(i)) * ones(size(ut(2:end)))' + dt'*resRates(i);
        end
    else
        eventLog = [ut(2:end)', ...
                    rVectECI(:,2:end)', ...
                    vVectECI(:,2:end)', ...
                    bodyID*ones(size(dt')), ...
                    repmat(masses,length(dt),1), ...
                    eventNum*ones(size(dt'))];
    end
end

