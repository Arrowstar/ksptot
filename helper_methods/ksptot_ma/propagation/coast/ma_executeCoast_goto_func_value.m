function eventLog = ma_executeCoast_goto_func_value(event, initialState, eventNum, considerSoITransitions, soiSkipIds, massLoss, orbitDecay, maData, celBodyData)
%ma_executeCoast_goto_func_value Summary of this function goes here
%   Detailed explanation goes here
    global number_state_log_entries_per_coast;
    
    old_number_state_log_entries_per_coast = number_state_log_entries_per_coast;
    number_state_log_entries_per_coast = 5; %#ok<NASGU>
    
    bnds = [0, event.maxPropTime];
    funcNoAbs = @(dt) getCoastFuncValue(dt, event.funcHandle, event.coastToValue, initialState, eventNum, considerSoITransitions, soiSkipIds, massLoss, orbitDecay, maData, celBodyData, false);
    funcAbs = @(dt) getCoastFuncValue(dt, event.funcHandle, event.coastToValue, initialState, eventNum, considerSoITransitions, soiSkipIds, massLoss, orbitDecay, maData, celBodyData, true);

    odeFunc = @(t,y) odefun(t,y);
    evtFnc = @(t,y) odeEventsFun(t,y,funcNoAbs);
    options = odeset('RelTol',1E-6, 'AbsTol',1E-6, 'Events',evtFnc, 'MaxStep',abs(diff(bnds))/50);
    [~,~,te,~,ie] = ode45(odeFunc, bnds, bnds(1), options);
    
    if(isempty(ie)) %fall back to old way of doing things
        options = optimset('TolX',1E-6);
        [x, fval, exitflag] = fminbnd(funcAbs, bnds(1), bnds(2), options);

        if(exitflag == 0 || abs(fval) > 1E-4)
            x = event.maxPropTime;
        end
    else
        x = te(1);
    end
    
    number_state_log_entries_per_coast = old_number_state_log_entries_per_coast;
    eventLog = ma_executeCoast_goto_dt(x, initialState, eventNum, considerSoITransitions, soiSkipIds, massLoss, orbitDecay, celBodyData);
end

function ydot = odefun(~,~)
    ydot = 1;
end

function [value,isterminal,direction] = odeEventsFun(t,~, func)
    value = func(t);
    isterminal = 1;
    direction = 0;
end

function value = getCoastFuncValue(dt, funcHandle, desiredValue, initialState, eventNum, considerSoITransitions, soiSkipIds, massLoss, orbitDecay, maData, celBodyData, useAbs)
    eventLog = ma_executeCoast_goto_dt(dt, initialState, eventNum, considerSoITransitions, soiSkipIds, massLoss, orbitDecay, celBodyData);
    finalState = eventLog(end,:);
    
    [datapt, ~, ~, taskStr, refBodyInfo, otherSC, station] = funcHandle(finalState, false, maData);
    
    if(useAbs)
        value = abs(datapt - desiredValue);
    else
        value = datapt - desiredValue;
    end
end