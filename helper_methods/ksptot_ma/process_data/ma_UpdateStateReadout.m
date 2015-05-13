function ma_UpdateStateReadout(hStateReadoutLabel, whichState, stateLog, celBodyData)
%ma_UpdateStateReadout Summary of this function goes here
%   Detailed explanation goes here
    if(isempty(stateLog))
        return;
    end
    
    if(strcmpi(whichState,'initial'))
        state = stateLog(1,:);
    elseif(strcmpi(whichState,'final'))
        state = stateLog(end,:);
    else
        error(['Unknown state type "', whichState,'" when generating state readouts.']);
    end
    [stateStr, stateTooltipStr] = generateStateReadoutStr(state, celBodyData);
    set(hStateReadoutLabel,'String',stateStr);
    set(hStateReadoutLabel, 'TooltipString', stateTooltipStr);
    
    bodyID = state(8);

    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    gmu = bodyInfo.gm;
    utSec = state(1);
    rVect = state(2:4)';
    vVect = state(5:7)';
 
    [sma, ecc, inc, raan, arg, tru] = getKeplerFromState(rVect,vVect,gmu);
    clipboardData = [utSec, sma, ecc, inc, raan, arg, tru];
    set(hStateReadoutLabel,'UserData',clipboardData);
    
    hcmenu = uicontextmenu;
    copyCallback = @(src,eventdata) copyOrbitToClipboardFromStateLog(src,eventdata, hStateReadoutLabel);
    uimenu(hcmenu,'Label','Copy Orbit to Clipboard','Callback',copyCallback);
    try
        set(hStateReadoutLabel,'uicontextmenu',hcmenu);
    catch
    end
end

function [stateStr, stateTooltipStr] = generateStateReadoutStr(state, celBodyData)
    num = 7;

    bodyID = state(8);

    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    gmu = bodyInfo.gm;
    utSec = state(1);
    rVect = state(2:4)';
    vVect = state(5:7)';

    masses = state(9:12);   
    [sma, ecc, inc, raan, arg, tru] = getKeplerFromState(rVect,vVect,gmu);
    inc = rad2deg(inc);
    raan = rad2deg(raan);
    arg = rad2deg(arg);
    tru = rad2deg(tru);

    stateStr = {};
    stateStr{end+1} = ['Univ. Time (UT)  = ', num2str(state(1),'%15.3f'), ' sec'];
    stateStr{end+1} = ' ';
    stateStr{end+1} = ['Orbiting About   = ', bodyInfo.name];
    stateStr{end+1} = ['Semi-major Axis  = ', num2str(sma,num),  ' km'];
    stateStr{end+1} = ['Eccentricity     = ', num2str(ecc,num)];
    stateStr{end+1} = ['Inclination      = ', num2str(inc,num),  ' deg'];
    stateStr{end+1} = ['Rt Asc of Asc Nd = ', num2str(raan,num), ' deg'];
    stateStr{end+1} = ['Arg. of Periapse = ', num2str(arg,num),  ' deg'];
    stateStr{end+1} = ['True Anomaly     = ', num2str(tru,num),  ' deg'];
    stateStr{end+1} = ' ';
    stateStr{end+1} = ['Dry Mass         = ', num2str(masses(1),num),    ' tons'];
    stateStr{end+1} = ['Fuel/Ox Mass     = ', num2str(masses(2),num),    ' tons'];
    stateStr{end+1} = ['Monoprop Mass    = ', num2str(masses(3),num),    ' tons'];
    stateStr{end+1} = ['Xenon Mass       = ', num2str(masses(4),num),    ' tons'];
    stateStr{end+1} = ['Total Mass       = ', num2str(sum(masses),num),  ' tons'];
    
    [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(utSec);
    epochStr = formDateStr(year, day, hour, minute, sec);
    try
        period = computePeriod(sma, gmu);
    catch
        period = NaN;
    end
    [rAp, rPe] = computeApogeePerigee(sma, ecc);
    if(ecc >= 1.0)
        rAp = Inf;
        period = 'N/A';
    end
    
    [mean] = computeMeanFromTrueAnom(deg2rad(tru), ecc);
    mean = rad2deg(mean);
    
    [lat, long, alt] = getLatLongAltFromInertialVect(utSec, rVect, bodyInfo);

    stateTooltipStrArr = {};
    stateTooltipStrArr{end+1} = epochStr;
    stateTooltipStrArr{end+1} = ['Period         = ', num2str(period,num), ' sec'];
    stateTooltipStrArr{end+1} = ['Mean Anomaly   = ', num2str(mean,num), ' deg'];
    stateTooltipStrArr{end+1} = [' '];
    stateTooltipStrArr{end+1} = ['Periapsis Rad. = ', num2str(rPe,num), ' km'];
    stateTooltipStrArr{end+1} = ['Periapsis Alt. = ', num2str(rPe-bodyInfo.radius,num), ' km'];
    stateTooltipStrArr{end+1} = [' '];
    stateTooltipStrArr{end+1} = ['Apoapsis Rad.  = ', num2str(rAp,num), ' km'];
    stateTooltipStrArr{end+1} = ['Apoapsis Alt.  = ', num2str(rAp-bodyInfo.radius,num), ' km'];
    stateTooltipStrArr{end+1} = [' '];
    stateTooltipStrArr{end+1} = ['Radius         = ', num2str(norm(rVect),num), ' km'];
    stateTooltipStrArr{end+1} = ['Velocity       = ', num2str(norm(vVect),num), ' km/s'];
    stateTooltipStrArr{end+1} = [' '];
    stateTooltipStrArr{end+1} = ['Longitude      = ', num2str(rad2deg(long)), ' degE'];
    stateTooltipStrArr{end+1} = ['Latitude       =  ', num2str(rad2deg(lat)), ' degN'];
    stateTooltipStrArr{end+1} = ['Altitude       = ', num2str(alt), ' km'];
    
    stateTooltipStr = '';
    for(i=1:length(stateTooltipStrArr))
        stateTooltipStr = [stateTooltipStr, stateTooltipStrArr{i}]; %#ok<AGROW>
        if(i < length(stateTooltipStrArr))
            stateTooltipStr = [stateTooltipStr, '\n']; %#ok<AGROW>
        end
    end
    stateTooltipStr = sprintf(stateTooltipStr);
end

