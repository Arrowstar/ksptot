function [str] = printXfrOrbitsMFMSToTextbox(hTransferOrbitsText,waypoints, xferOrbits, numRev, form, form2, paddLen)
%printXfrOrbitsMFMSToTextbox Summary of this function goes here
%   Detailed explanation goes here

        hRule = getHRule();
        
        str = {};
        for(i=1:size(xferOrbits,1))
            str{end+1} = sprintf(['Phase %u Transfer Orbit (%s -> %s)'], i, cap1stLetter(waypoints{i}.name), cap1stLetter(waypoints{i+1}.name));
            str{end+1} = hRule;
            str{end+1} = ['Semi-major Axis = ', paddStrLeft(num2str(xferOrbits(i,1), form),24), ' km'];
            str{end+1} = [paddStr('Eccentricity = ', paddLen), num2str(xferOrbits(i,2), form2)];
            str{end+1} = [paddStr('Inclination = ',paddLen), num2str(rad2deg(AngleZero2Pi(xferOrbits(i,3))), form), ' deg'];
            str{end+1} = [paddStr('Right Ascension of AN = ',paddLen), num2str(rad2deg(AngleZero2Pi(xferOrbits(i,4))), form), ' deg'];
            str{end+1} = [paddStr('Argument of Periapse = ',paddLen), num2str(rad2deg(AngleZero2Pi(xferOrbits(i,5))), form), ' deg'];
            if(xferOrbits(i,1) > 0)
                str{end+1} = ['Period = ', paddStrLeft(num2str(computePeriod(xferOrbits(i,1), xferOrbits(i,10))),32), ' sec'];
            end
            str{end+1} = [paddStr(['Departure True Anomaly = '],paddLen), num2str(rad2deg(AngleZero2Pi(xferOrbits(i,6))), form), ' deg'];
            str{end+1} = [paddStr(['Arrival True Anomaly = '],paddLen), num2str(rad2deg(AngleZero2Pi(xferOrbits(i,7))), form), ' deg'];
            str{end+1} = [paddStr(['Num. Full Revs Prior to Arrival = '],paddLen), num2str(abs(numRev(i)), form)];
            str{end+1} = hRule;
        end
        str = horzcat(str,getDatesStr(waypoints, xferOrbits, form));
        
        set(hTransferOrbitsText,'String',str);
end

function dStr = getDatesStr(waypoints, xferOrbits, form)
    hRule = getHRule();
    
    dStr = {};
    for(i=1:length(waypoints)) %#ok<*NO4LP>
        if(i==1)
            ut =  xferOrbits(i,8);
            tStr = 'Departure';
        else
            ut =  xferOrbits(i-1,9);
            tStr = 'Arrival';
        end
        ddStr = paddStr([cap1stLetter(waypoints{i}.name), ' ', tStr, ' Date = '],17);
        
        [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(ut);
        dateStr = formDateStr(year, day, hour, minute, sec);
        dStr{end+1} = sprintf('%s', ddStr);
        dStr{end+1} = sprintf('%s', paddStrLeft(dateStr,44));
        dStr{end+1} = sprintf('%s',paddStrLeft(['(',num2str(ut, form),' sec UT)'],44));
    end
    dStr{end+1} = hRule;
    
    totMissionDur = xferOrbits(end,9) - xferOrbits(1,8);
    [durationStr] = getDurationStr(totMissionDur);
    dStr{end+1} = sprintf('Total Mission Duration = ');
    dStr{end+1} = sprintf('%s', paddStrLeft(durationStr,44));
end