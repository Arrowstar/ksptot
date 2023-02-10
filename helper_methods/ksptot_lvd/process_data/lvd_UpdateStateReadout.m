function [stateStr, stateTooltipStr, clipboardData] = lvd_UpdateStateReadout(tgtFrame, tgtElementSet, whichState, stateLog, showRightClickMessage)
    arguments
        tgtFrame AbstractReferenceFrame
        tgtElementSet(1,1) ElementSetEnum
        whichState(1,:) char 
        stateLog(1,1) LaunchVehicleStateLog
        showRightClickMessage(1,1) logical = false;
    end

    [tStart, tEnd] = stateLog.getStartAndEndTimes();
    if(strcmpi(whichState,'initial'))
        s = stateLog.getStateLogEntriesBetweenTimes(tStart, tStart);
        if(numel(s) > 1)
            evts = [s.event];
            nums = getEventNum(evts);
            minEvtNum = min(nums);
            I = find(nums == minEvtNum, 1, "first");
            state = s(I);
        else
            state = s;
        end
             
    elseif(strcmpi(whichState,'final'))
        s = stateLog.getStateLogEntriesBetweenTimes(tEnd, tEnd);
        if(numel(s) > 1)
            evts = [s.event];
            nums = getEventNum(evts);
            maxEvtNum = max(nums);
            I = find(nums == maxEvtNum, 1, "last");
            state = s(I);
        else
            state = s;
        end
        
    else
        error(['Unknown state type "', whichState,'" when generating state readouts.']);
    end

    if(isempty(tgtFrame))
        tgtFrame = state.centralBody.getBodyCenteredInertialFrame();
    end

    cartElemSet = state.getCartesianElementSetRepresentation();
    cartElemSet = cartElemSet.convertToFrame(tgtFrame);

    switch tgtElementSet
        case ElementSetEnum.CartesianElements
            convertedElemSet = cartElemSet;
            
        case ElementSetEnum.KeplerianElements
            convertedElemSet = convertToKeplerianElementSet(cartElemSet);
            
        case ElementSetEnum.GeographicElements
            convertedElemSet = convertToGeographicElementSet(cartElemSet);
            
        case ElementSetEnum.UniversalElements
            convertedElemSet = convertToUniversalElementSet(cartElemSet);
            
        otherwise
            error('Unknown element set: %s', string(obj(1).typeEnum));
    end

    [stateStr, stateTooltipStr] = generateStateReadoutStr(state, convertedElemSet, showRightClickMessage);

    ce = state.getCartesianElementSetRepresentation();
    ke = ce.convertToFrame(state.centralBody.getBodyCenteredInertialFrame()).convertToKeplerianElementSet();

    clipboardData = [ke.time, ke.sma, ke.ecc, ke.inc, ke.raan, ke.arg, ke.tru, state.centralBody.id];
end

function [stateStr, stateTooltipStr] = generateStateReadoutStr(state, elemSet, showRightClickMessage)
    arguments
        state(1,1) LaunchVehicleStateLogEntry
        elemSet(1,1) AbstractElementSet
        showRightClickMessage(1,1) logical
    end

    num = 7;

    utSec = state.time;
%     bodyInfo = state.centralBody;
    bodyInfo = elemSet.frame.getOriginBody();

    dryMass = state.getTotalVehicleDryMass();
    massesByType = state.getTotalVehiclePropMassesByFluidType();
    fluidTypes = state.launchVehicle.tankTypes.types;
    totalMass = state.getTotalVehicleMass();

    stateStr = {};
    stateStr{end+1} = ['Univ. Time (UT)  = ', num2str(utSec,'%15.3f'), ' sec'];
    stateStr{end+1} = ' ';
    stateStr{end+1} = ['Orbiting About   = ', bodyInfo.name];
    stateStr = horzcat(stateStr, elemSet.getDisplayText(num));
    stateStr{end+1} = ' ';
    stateStr{end+1} = ['Dry Mass         = ', num2str(dryMass,num),    ' tons'];

    for(i=1:length(massesByType)) %#ok<*NO4LP> 
        propName = fluidTypes(i).name;

        if(length(propName) > 11)
            propNameLength = 11;
        else
            propNameLength = length(propName);
        end

        stateStr{end+1} = [paddStr([propName(1:propNameLength), ' Mass'], 16), ' = ', num2str(massesByType(i),num),    ' tons'];
    end
    stateStr{end+1} = ['Total Mass       = ', num2str(totalMass,num),  ' tons'];

    %%% Do tooltip string here
    [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(utSec);
    epochStr = formDateStr(year, day, hour, minute, sec);
    ke = elemSet.convertToKeplerianElementSet();
    try
        period = ke.getPeriod();
    catch
        period = NaN;
    end
    [rAp, rPe] = computeApogeePerigee(ke.sma, ke.ecc);
    if(ke.ecc >= 1.0)
        rAp = Inf;
        period = 'N/A';
    end
    
    mean = rad2deg(ke.getMeanAnomaly());

    ce = elemSet.convertToCartesianElementSet();
    [~, ~, ~, ~, horzVel, vertVel] = getLatLongAltFromInertialVect(utSec, ce.rVect, bodyInfo, ce.vVect);

    stateTooltipStrArr = {};
    stateTooltipStrArr{end+1} = ['Frame            = ', elemSet.frame.getNameStr()];
    stateTooltipStrArr{end+1} = [' '];
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
    stateTooltipStrArr{end+1} = ['Radius         = ', num2str(norm(ce.rVect),num), ' km'];
    stateTooltipStrArr{end+1} = ['Velocity       = ', num2str(norm(ce.vVect),num), ' km/s'];
    stateTooltipStrArr{end+1} = [' '];
%     stateTooltipStrArr{end+1} = ['Longitude      = ', num2str(rad2deg(long)), ' degE'];
%     stateTooltipStrArr{end+1} = ['Latitude       =  ', num2str(rad2deg(lat)), ' degN'];
%     stateTooltipStrArr{end+1} = ['Altitude       = ', num2str(alt), ' km'];
    stateTooltipStrArr{end+1} = ['Surface Vel.   = ', num2str(horzVel), ' km/s'];
    stateTooltipStrArr{end+1} = ['Vertical Vel.  = ', num2str(vertVel), ' km/s'];
    
    if(showRightClickMessage)
        stateTooltipStrArr{end+1} = [' '];
        stateTooltipStrArr{end+1} = ['Right-click this orbit display to change the element set and reference frame used to display the orbit data.'];
    end

    stateTooltipStr = '';
    for(i=1:length(stateTooltipStrArr))
        stateTooltipStr = [stateTooltipStr, stateTooltipStrArr{i}]; %#ok<AGROW>
        if(i < length(stateTooltipStrArr))
            stateTooltipStr = [stateTooltipStr, '\n']; %#ok<AGROW>
        end
    end
    stateTooltipStr = sprintf(stateTooltipStr);
end