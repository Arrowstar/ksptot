function generatePorkChopPlot(mainGUIHandle)
    %generatePorkChopPlot Summary of this function goes here
    %   Detailed explanation goes here
    userData = get(mainGUIHandle,'UserData');
    celBodyData = userData{1,1};

    hCentralBodyCombo = findobj(mainGUIHandle,'Tag','centralBodyCombo');
    try
        contents = cellstr(get(hCentralBodyCombo,'String'));
        cbName = lower(contents{get(hCentralBodyCombo,'Value')});
    catch
        cbName = lower(hCentralBodyCombo.Value);
    end
    cBodyInfo = celBodyData.(cbName);
    gmu = cBodyInfo.gm;

    hDepartBodyCombo = findobj(mainGUIHandle,'Tag','departBodyCombo');
    try
        contents = cellstr(get(hDepartBodyCombo,'String'));
        departName = lower(contents{get(hDepartBodyCombo,'Value')});
    catch
        departName = lower(hDepartBodyCombo.Value);
    end

    hArrivalBodyCombo = findobj(mainGUIHandle,'Tag','arrivalBodyCombo');
    try
        contents = cellstr(get(hArrivalBodyCombo,'String'));
        arrivalName = lower(contents{get(hArrivalBodyCombo,'Value')});
    catch
        arrivalName = lower(hArrivalBodyCombo.Value);
    end

    hEarlyDepartTime = findobj(mainGUIHandle,'Tag','departBodyEarliestTimeText');
    try
        earlyDepartTime = str2double(get(hEarlyDepartTime,'String'));
    catch
        earlyDepartTime = str2double(hEarlyDepartTime.Value);
    end

    hEarlyArrivalTime = findobj(mainGUIHandle,'Tag','arrivalBodyEarliestTimeText');
    try
        earlyArrivalTime = str2double(get(hEarlyArrivalTime,'String'));
    catch
        earlyArrivalTime = str2double(hEarlyArrivalTime.Value);
    end

    options = userData{1,9};
    [departDV, arrivalDV, totalDV, departTimeArr, arrivalTimeArr, numSynPeriods] = computePorkChopData(celBodyData, departName, earlyDepartTime, arrivalName, earlyArrivalTime, gmu, options, mainGUIHandle);
    options.porkchopnumsynperiods = numSynPeriods;
    userData{1,9} = options;
    set(mainGUIHandle,'UserData',userData);
    updateAppOptions(mainGUIHandle, 'ksptot', 'porkchopnumsynperiods', options.porkchopnumsynperiods);
    
    hPlotBtnGrp = findobj(mainGUIHandle,'Tag','porkchopPlotTypeButtonGroup');
    hTypeBtn = get(hPlotBtnGrp,'SelectedObject');
    plotType = get(hTypeBtn, 'Tag');
       
    userData = get(mainGUIHandle,'UserData');
    userData{1,2} = departDV';
    userData{1,3} = arrivalDV';
    userData{1,4} = totalDV';
    userData{1,5} = departTimeArr;
    userData{1,6} = arrivalTimeArr;
    userData{1,7} = departName;
    userData{1,8} = arrivalName;
    
    userData{2,1} = departName;
    userData{2,2} = arrivalName;
    userData{2,3} = earlyDepartTime;
    userData{2,4} = earlyArrivalTime;
    userData{2,5} = gmu;
    userData{2,6} = cbName;
    set(mainGUIHandle,'UserData',userData);
    
    if(not(isempty(departName)) && not(isempty(arrivalName)))
        departBodyInfo = celBodyData.(lower(departName));
        arrivalBodyInfo = celBodyData.(lower(arrivalName));
        gmu = userData{2,5};
    end
    
    matrixToPlot = userData{1,4};
    if(all(all(isnan(matrixToPlot))))
        errordlg('Could not compute optimal departure solution.  Your departure date may be too far ahead of your arrival date.');
        return;
    end   
    
    plotPorkChopPlot(mainGUIHandle);
    userData = get(mainGUIHandle,'UserData'); %there may be updates in this function to some options

    if(true)
        departUT=-1;
        arrivalUT=-1;
        dv=NaN;
        if(not(isempty(matrixToPlot)))
            [r,c]=find(matrixToPlot==min(min(matrixToPlot)), 1);
            [~, ~, secInDay, ~] = getSecondsInVariousTimeUnits();
            xpos = departTimeArr(c)/(secInDay);
            ypos = arrivalTimeArr(r)/(secInDay);

            [arrivalUT, departUT, dv] = findOptimalDepartArrivalFromPorkChop(ypos*(secInDay), xpos*(secInDay), departBodyInfo, arrivalBodyInfo, gmu, options.quant2opt, departTimeArr, arrivalTimeArr, mainGUIHandle);
        end
        userData{2,7} = departUT;
        userData{2,8} = arrivalUT;
        set(mainGUIHandle,'UserData',userData);

        hStatusBox = findall(mainGUIHandle,'tag','statusText');

        deltaVStrName = deltaVTypeEnum(options.quant2opt);
        departHeader = ['Optimal ', cap1stLetter(departName),' Departure: '];
        arrivalHeader = ['Optimal ', cap1stLetter(arrivalName),' Arrival: '];
        padLngth = max([length(deltaVStrName)+2, length(departHeader), length(arrivalHeader)]);
        deltaVStrName = [paddStr([deltaVStrName, ': '], padLngth), num2str(dv), ' km/s'];

        [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(departUT);
        [departUTStr] = formDateStr(year, day, hour, minute, sec);
        departUTStr = [paddStr(departHeader,padLngth), departUTStr];
        departUTStr = [departUTStr, ' (', num2str(departUT), ' sec UT)'];

        [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(arrivalUT);
        [arrivalUTStr] = formDateStr(year, day, hour, minute, sec);
        arrivalUTStr = [paddStr(arrivalHeader, padLngth), arrivalUTStr];
        arrivalUTStr = [arrivalUTStr, ' (', num2str(arrivalUT), ' sec UT)'];

        duration = arrivalUT-departUT;
        [durationStr] = getDurationStr(duration);
        durationStr = [paddStr('Transfer Duration: ', padLngth), durationStr];

    %     str = {statusBoxHR(), departUTStr, arrivalUTStr, deltaVStrName};
        headerStr = ['Porkchop Plot Results - ', datestr(now)];
        headerSubStr = repmat('-',1,length(headerStr));
        writeToOutput(hStatusBox, headerStr,'append');
        writeToOutput(hStatusBox, headerSubStr,'append');
        writeToOutput(hStatusBox, departUTStr,'append');
        writeToOutput(hStatusBox, arrivalUTStr,'append');
        writeToOutput(hStatusBox, durationStr,'append');
        writeToOutput(hStatusBox, deltaVStrName,'append');
        writeToOutput(hStatusBox, statusBoxHR(),'append');
    end
end

