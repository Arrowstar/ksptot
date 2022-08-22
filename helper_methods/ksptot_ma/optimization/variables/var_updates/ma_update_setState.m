function event = ma_update_setState(event, setStateValue)
%ma_update_launch Summary of this function goes here
%   Detailed explanation goes here
    activeVars = event.vars(1,:) == 1;
    
    if(strcmpi(event.type,'Set_State') && strcmpi(event.subType, 'setState'))
        epoch = event.epoch;
        rVect = event.rVect;
        vVect = event.vVect;
        gmu = event.centralBody.gm;

        [sma, ecc, inc, raan, arg, tru] = getKeplerFromState(rVect,vVect,gmu, true);

        value = [epoch, sma, ecc, inc, raan, arg, tru];
        value(activeVars) = setStateValue;
        
        [rVect,vVect]=getStatefromKepler(value(2), value(3), value(4), value(5), value(6), value(7), gmu, true);
        
        event.epoch = value(1);
        event.rVect = rVect;
        event.vVect = vVect;
    else
        error(['Could not update launch event, it was of the wrong type: ', maneuver.type]);
    end
end