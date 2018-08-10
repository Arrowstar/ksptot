function datapt = ma_GAEclipseTask(stateLogEntry, subTask, otherSC, station, celBodyData)
%ma_GAEclipseTask Summary of this function goes here
%   Detailed explanation goes here
    bodyID = stateLogEntry(8);
    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    bodies = fields(celBodyData);
    
    switch subTask
        case 'Eclipse'
            datapt = 0;
            for(i=1:length(bodies)) %#ok<*NO4LP>
                eclipseBodyInfo = celBodyData.(bodies{i});
                targetBodyInfo = celBodyData.sun;

                LoS = LoS2Target(stateLogEntry, bodyInfo, eclipseBodyInfo, targetBodyInfo, celBodyData, []);
                if(LoS == 0)
                    datapt = 1;
                    break;
                end
            end
            
        case 'OtherSC_LOS'
            if(isempty(otherSC))
                datapt = -1;
                return;
            end
            
            datapt = 0;
            for(i=1:length(bodies))
                eclipseBodyInfo = celBodyData.(bodies{i});
                targetBodyInfo = otherSC;

                LoS = LoS2Target(stateLogEntry, bodyInfo, eclipseBodyInfo, targetBodyInfo, celBodyData, []);
                if(LoS == 0)
                    datapt = 0;
                    break;
                else
                    datapt = 1;
                end
            end
            
        case 'Station_LOS'
            if(isempty(station))
                datapt = -1;
                return;
            end
            
            stnBodyInfo = getBodyInfoByNumber(station.parentID, celBodyData);
            
            datapt = 0;
            for(i=1:length(bodies))
                eclipseBodyInfo = celBodyData.(bodies{i});
                targetBodyInfo = stnBodyInfo;

                LoS = LoS2Target(stateLogEntry, bodyInfo, eclipseBodyInfo, targetBodyInfo, celBodyData, station);
                if(LoS == 0)
                    datapt = 0;
                    break;
                else
                    datapt = 1;
                end
            end
    end
end
