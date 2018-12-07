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
    end
end