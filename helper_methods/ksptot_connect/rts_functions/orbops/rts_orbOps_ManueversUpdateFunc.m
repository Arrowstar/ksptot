function rts_orbOps_ManueversUpdateFunc(~, ~, tcpipClient, hManeuversLabel, celBodyData, orbitTcpipClient)
%rts_orbOps_ManueversUpdateFunc Summary of this function goes here
%   Detailed explanation goes here

    try
        data = get(tcpipClient,'UserData');
        manData = data{1};
        manNumber = get(hManeuversLabel,'UserData');
        if(~isempty(manData))
            %UPDATE MANEUVER PANEL
            if(~isempty(hManeuversLabel))
                maneuversStr = generateManeuversPanelStr(manData, manNumber, hManeuversLabel, celBodyData, orbitTcpipClient);
                set(hManeuversLabel,'String',maneuversStr);
            end
        end
    catch ME
        disp(ME.stack(1));
    end
end

function maneuversStr = generateManeuversPanelStr(manData, manNumber, maneuversTextDispLabel, celBodyData, orbitTcpipClient)
    manNumOffset = 5*manNumber;
    while(length(manData) < manNumOffset + 1)
        manNumber = max(manNumber - 1,0);
        manNumOffset = 5*manNumber;
    end
    set(maneuversTextDispLabel,'UserData',manNumber);

    burnTime = manData(manNumOffset + 1);
    timeUntil = manData(manNumOffset + 2);
    dvR = manData(manNumOffset + 3);
    dvN = manData(manNumOffset + 4);
    dvP = manData(manNumOffset + 5);
    
    if(burnTime ~= 0)
        [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(burnTime);
        burnTimeDate = formDateStr(year, day, hour, minute, sec);
    else
        burnTimeDate = '';
    end

    if(manNumber == 0)
        data = get(orbitTcpipClient,'UserData');
        orbitData = data{1};
        orbitData(8) = orbitData(8); %get mean anomaly into 0->2*pi
        orbitBodyInfo = getBodyInfoStructFromOrbit([orbitData(1:5)', orbitData(8:9)']);
        bodyInfo = getBodyInfoByNumber(orbitData(13), celBodyData);

        [rVect, vVect] = getStateAtTime(orbitBodyInfo, burnTime, bodyInfo.gm);
        [~, ~, ~, ~, ~, tru] = getKeplerFromState(rVect,vVect,bodyInfo.gm);
    end
    
    maneuversDescArr = {};
    maneuversDescArr(end+1,:) = {'Maneuver Num.', manNumber, ''};
    
    maneuversDescArr(end+1,:) = {'hrhrhr','hrhrhr','hrhrhr'};
    maneuversDescArr(end+1,:) = {'Burn UT', burnTime, 'sec'};
    maneuversDescArr(end+1,:) = {'Time Until', timeUntil, 'sec'};
    if(manNumber == 0)
        maneuversDescArr(end+1,:) = {'True Anom.', rad2deg(tru), 'deg'};
    end
    
    maneuversDescArr(end+1,:) = {'hrhrhr','hrhrhr','hrhrhr'};
    maneuversDescArr(end+1,:) = {'Total DV', norm([dvR, dvN, dvP]), 'm/s'};
    maneuversDescArr(end+1,:) = {'Prograde DV', dvP, 'm/s'};
    maneuversDescArr(end+1,:) = {'Normal DV', dvN, 'm/s'};
    maneuversDescArr(end+1,:) = {'Radial DV', dvR, 'm/s'};
    
    maneuversStr = formManeuversText(maneuversDescArr);
end

function maneuverText = formManeuversText(maneuversDescArr) 
    padLengthQuant = 13;
    form = '%9.3f';
    formManNum = '%9.0f';
    maneuverText = {};
    
    for(i=1:size(maneuversDescArr,1))
        row = maneuversDescArr(i,:);
        if(strcmpi(row{1},'hrhrhr'))
            maneuverText{end+1} = '-------------------------------------';
            continue;
        end
        
        formToUse = form;
        if(strcmpi(row{1},'Maneuver Num.'))
            formToUse = formManNum;
        end
        
        quant = paddStr(row{1}, padLengthQuant);
        maneuverText{i} = [quant, ' = ', num2str(row{2}, formToUse), ' ', row{3}];
    end
end




