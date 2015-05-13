function datapt = ma_GAEclipseTask(stateLogEntry, subTask, celBodyData)
%UNTITLED Summary of this function goes here
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
            hRefSCCombo = findobj('Tag','refSpacecraftCombo');

            if(strcmpi(get(hRefSCCombo,'Enable'),'off'))
                datapt = -1;
                return;
            end

            try
                refSCInd = get(hRefSCCombo,'Value');
                hGA = findobj('Tag','ma_GraphicalAnalysisGUI');
                handles = guidata(hGA);
                maData = getappdata(handles.ma_MainGUI,'ma_data');
                otherSCs = maData.spacecraft.otherSC;
                otherSC = otherSCs{refSCInd};
            catch
                datapt = -1;
                return;
            end

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
            hRefStnCombo = findobj('Tag','refStationCombo');

            if(strcmpi(get(hRefStnCombo,'Enable'),'off'))
                datapt = -1;
                return;
            end

            try
                refSCInd = get(hRefStnCombo,'Value');
                hGA = findobj('Tag','ma_GraphicalAnalysisGUI');
                handles = guidata(hGA);
                maData = getappdata(handles.ma_MainGUI,'ma_data');
                stations = maData.spacecraft.stations;
                station = stations{refSCInd};
            catch
                datapt = -1;
                return;
            end

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

function LoS = LoS2Target(stateLogEntry, bodyInfo, eclipseBodyInfo, targetBodyInfo, celBodyData, station)
    eBodyRad = eclipseBodyInfo.radius;
    rVectSC2EBody = getAbsPositBetweenSpacecraftAndBody(stateLogEntry(1), stateLogEntry(2:4)',...
                        bodyInfo, eclipseBodyInfo, celBodyData);
    rVectSC2Target = getAbsPositBetweenSpacecraftAndBody(stateLogEntry(1), stateLogEntry(2:4)',...
                        bodyInfo, targetBodyInfo, celBodyData);
                    
	if(~isempty(station))
        stnBodyInfo = getBodyInfoByNumber(station.parentID, celBodyData);
        stnRVectECIRelToParent = getInertialVectFromLatLongAlt(stateLogEntry(1), station.lat, station.long, station.alt, stnBodyInfo);
        rVectSC2Target = rVectSC2Target + stnRVectECIRelToParent;
	end

    if(all(rVectSC2EBody==rVectSC2Target)) %eclipse body and target body are the same, eclipse not possible
        LoS = 1;
        return;
    end

    rVectDAng = dang(rVectSC2EBody,rVectSC2Target);                
    angleSizeOfEBody = atan(eBodyRad/norm(rVectSC2EBody));

    if(rVectDAng <= angleSizeOfEBody && norm(rVectSC2Target) > norm(rVectSC2EBody))
        LoS = 0; %we're in eclipse or we can't see the target
    else
        LoS = 1;
    end
end



