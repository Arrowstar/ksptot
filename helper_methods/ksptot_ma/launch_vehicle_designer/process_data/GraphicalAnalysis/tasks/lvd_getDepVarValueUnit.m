function [depVarValue, depVarUnit, taskStr, refBodyInfo] = lvd_getDepVarValueUnit(i, subLog, taskStr, refBodyId, celBodyData, onlyReturnTaskStr)
%lvd_getDepVarValueUnit Summary of this function goes here
%   Detailed explanation goes here
    
    if(~isempty(refBodyId))
        refBodyInfo = getBodyInfoByNumber(refBodyId, celBodyData);
    else
        refBodyInfo = [];
    end
    
%     if(~isempty(oscId))
%         otherSC = getOtherSCInfoByID(maData, oscId);
%     else
%         otherSC = [];
%     end
%     
%     if(~isempty(stnId))
%         station = getStationInfoByID(maData, stnId);
%     else
%         station = [];
%     end

    if(onlyReturnTaskStr == true)
        depVarValue = NaN;
        depVarUnit = NaN;
        
        return;
    end
    
    switch taskStr
        case 'Yaw Angle'
            depVarValue = lvd_SteeringAngleTask(subLog(i), 'yaw');
            depVarUnit = 'deg';
        case 'Pitch Angle'
            depVarValue = lvd_SteeringAngleTask(subLog(i), 'pitch');
            depVarUnit = 'deg';
        case 'Roll Angle'
            depVarValue = lvd_SteeringAngleTask(subLog(i), 'roll');
            depVarUnit = 'deg';
        case 'Bank Angle'
            depVarValue = lvd_SteeringAngleTask(subLog(i), 'bank');
            depVarUnit = 'deg';
        case 'Angle of Attack'
            depVarValue = lvd_SteeringAngleTask(subLog(i), 'angleOfAttack');
            depVarUnit = 'deg';
        case 'SideSlip Angle'
            depVarValue = lvd_SteeringAngleTask(subLog(i), 'sideslip');
            depVarUnit = 'deg';
        case 'Throttle'
            depVarValue = lvd_ThrottleTask(subLog(i), 'throttle');
            depVarUnit = 'Percent';
        case 'Thrust to Weight Ratio'
            depVarValue = lvd_ThrottleTask(subLog(i), 't2w');
            depVarUnit = ' ';
        otherwise %is a programmatically generated string that we'll handle here
            tankMassPattern = 'Tank (\d+?) Mass - ".*"';
            stageDryMassPattern = 'Stage (\d+?) Dry Mass - ".*"';
            stageActivePattern = 'Stage (\d+?) Active State - ".*"';
            engineActivePattern = 'Engine (\d+?) Active State - ".*"';
            
            if(not(isempty(regexpi(taskStr, tankMassPattern))))
                tokens = regexpi(taskStr, tankMassPattern, 'tokens');
                tokens = tokens{1};
                tokens = tokens{1};
                tankInd = str2double(tokens);
                
                [~,tanks] = subLog(i).launchVehicle.getTanksGraphAnalysisTaskStrs();
                tank = tanks(tankInd);
                
                depVarValue = lvd_TankMassTasks(subLog(i), 'tankMass', tank);
                depVarUnit = 'mT';
                
            elseif(not(isempty(regexpi(taskStr, stageDryMassPattern))))
                tokens = regexpi(taskStr, stageDryMassPattern, 'tokens');
                tokens = tokens{1};
                tokens = tokens{1};
                stageInd = str2double(tokens);
                
                [~,stages] = subLog(i).launchVehicle.getStagesGraphAnalysisTaskStrs();
                stage = stages(stageInd);
                
                depVarValue = lvd_StageTasks(subLog(i), 'dryMass', stage);
                depVarUnit = 'mT';
                
            elseif(not(isempty(regexpi(taskStr, stageActivePattern))))
                tokens = regexpi(taskStr, stageActivePattern, 'tokens');
                tokens = tokens{1};
                tokens = tokens{1};
                stageInd = str2double(tokens);
                
                [~,stages] = subLog(i).launchVehicle.getStagesGraphAnalysisTaskStrs();
                stage = stages(stageInd);
                
                depVarValue = lvd_StageTasks(subLog(i), 'active', stage);
                depVarUnit = '';
                
            elseif(not(isempty(regexpi(taskStr, engineActivePattern))))
                tokens = regexpi(taskStr, engineActivePattern, 'tokens');
                tokens = tokens{1};
                tokens = tokens{1};
                engineInd = str2double(tokens);
                
                [~,engines] = subLog(i).launchVehicle.getEnginesGraphAnalysisTaskStrs();
                engine = engines(engineInd);
                
                depVarValue = lvd_EngineTasks(subLog(i), 'active', engine);
                depVarUnit = '';
                
            end
    end
end