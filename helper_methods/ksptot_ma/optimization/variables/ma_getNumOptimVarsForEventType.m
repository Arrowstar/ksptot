function [numVar] = ma_getNumOptimVarsForEventType(event)
%getNumOptimVarsForEventType Summary of this function goes here
%   Detailed explanation goes here

    switch event.type
        case 'Coast'
            numVar = 1;
        case 'DV_Maneuver'
            numVar = 3;
        case 'Mass_Dump'
            numVar = 0;
        case 'Set_State'
            numVar = 0;
    end
end

