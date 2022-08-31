function [x0] = ma_getX0ForEvent(event)
%ma_getX0ForEvent Summary of this function goes here
%   Detailed explanation goes here

    activeVars = event.vars(1,:) == 1;
    switch event.type
        case 'Coast'
            x0 = event.coastToValue(activeVars);
        case 'NBodyCoast'
            x0 = event.coastToValue(activeVars);
        case 'DV_Maneuver'
            dvOrig = event.maneuverValue(activeVars);
            x0 = dvOrig;
        case 'Set_State'
            if(strcmpi(event.subType,'setState'))
                epoch = event.epoch;
                rVect = event.rVect;
                vVect = event.vVect;
                gmu = event.centralBody.gm;
                
                [sma, ecc, inc, raan, arg, tru] = getKeplerFromState(rVect,vVect,gmu, true);
                
                x0 = [epoch, sma, ecc, inc, raan, arg, tru];
                x0 = x0(activeVars);
            elseif(strcmpi(event.subType,'estLaunch'))
                x0 = event.launch.launchValue(activeVars);
            end
        otherwise
            error('Unknown event type, could not determine x0 for optimization: %s', event.type);
    end
end

