function plotPorkChopPlot(mainGUIHandle)
%plotPorkChopPlot Summary of this function goes here
%   Detailed explanation goes here
    hPlotBtnGrp = findobj(mainGUIHandle,'Tag','porkchopPlotTypeButtonGroup');
    hTypeBtn = get(hPlotBtnGrp,'SelectedObject');
    plotType = get(hTypeBtn, 'Tag');
    
    userData = get(mainGUIHandle,'UserData');
    celBodyData = userData{1,1};
    departTimeArr=userData{1,5};
    arrivalTimeArr=userData{1,6};
    departName = userData{1,7};
    arrivalName = userData{1,8};
    options = userData{1,9};
    hAxes = userData{1,10};
    cla(hAxes, 'reset');
    
    if(not(isempty(departName)) && not(isempty(arrivalName)))
        departBodyInfo = celBodyData.(lower(departName));
        arrivalBodyInfo = celBodyData.(lower(arrivalName));
        gmu = userData{2,5};
    end
    

    if(isempty(departTimeArr))
        departTimeArr=[0,1];
    end
    if(isempty(arrivalTimeArr))
        arrivalTimeArr=[0,1];
    end
    if(isempty(departName))
        departName='';
    end
    if(isempty(arrivalName))
        arrivalName='';
    end
    
    matrixToPlot = [];
    switch plotType
        case 'departDeltaVRadioButton'
            matrixToPlot=userData{1,2};
        case 'arrivalDeltaVRadioButton'
            matrixToPlot=userData{1,3};
        case 'departArrivalDeltaVRadioButton'
            matrixToPlot=userData{1,4};
    end
    
    if(~isempty(matrixToPlot))
        maxValue = userData{1,9}.plotmaxdeltav;
        maxValueInData = min(min(matrixToPlot));
        
        if(all(all(matrixToPlot>maxValue | isnan(matrixToPlot))))
            replaceMaxValue = ceil(maxValueInData*1.1);
            qstring = sprintf('Smallest delta-v value in plot (%f km/s) is greater than the maximum plottable delta-v in the options (%f km/s).\nSet max plottable delta-v to new recommended value of %u km/s?', ...
                              maxValueInData, maxValue,replaceMaxValue);
            button = questdlg(qstring,'Increase max delta-v to plot?','Yes','No','Yes');
            if(strcmpi(button,'Yes'))
                maxValue = replaceMaxValue;
                options.plotmaxdeltav = replaceMaxValue;
                userData{1,9} = options;
                set(mainGUIHandle,'UserData',userData);
                
                helpdlg(['The maximum plottable delta-v on the plot has been set to ', num2str(replaceMaxValue), ' km/s'],'Max Plottable Delta-v Updated');
            else
                warningstring = sprintf('Maximum plottable delta-v has not been updated.\nYour plot may look funny or wrong.');
                warndlg(warningstring,'Max Plottable Delta-V Not Updated');
            end
        end
        
        matrixToPlot(matrixToPlot>maxValue) = NaN;
        
        [~, ~, secInDay, ~] = getSecondsInVariousTimeUnits();
        
        cla(hAxes); xlim('auto'); ylim('auto');
        hold(hAxes,'on');
        [~,h]=contourf(hAxes, departTimeArr/(secInDay),arrivalTimeArr/(secInDay),matrixToPlot, 15);
        set(h,'LineWidth',1);
        porkchopPlotContextMenu = findobj(mainGUIHandle,'Tag','porkchopPlotAxesMenu');
        set(h,'UIContextMenu',porkchopPlotContextMenu);
    end
    
    dcm_obj = datacursormode(mainGUIHandle);
    porkchopUpdate = @(empty, event_obj) porkchopUpdateFcn(empty, event_obj, departTimeArr, arrivalTimeArr, matrixToPlot);
    set(dcm_obj, 'UpdateFcn', porkchopUpdate, 'DisplayStyle','datatip');
        
    if(not(isempty(matrixToPlot)))
        [~, ~, secInDay, ~] = getSecondsInVariousTimeUnits();
        
        [r,c]=find(matrixToPlot==min(min(matrixToPlot)), 1);
        hDatatip = createDatatip(dcm_obj, h);
        xpos = departTimeArr(c)/(secInDay);
        ypos = arrivalTimeArr(r)/(secInDay);
        set(hDatatip,'OrientationMode','manual');
        if(verLessThan('matlab', '8.4'))
            set(hDatatip,'Orientation','bottom-right');
            update(hDatatip, [xpos, ypos, 1; xpos, ypos, -1]);
        else
            set(hDatatip,'Orientation','bottomright');
            set(hDatatip,'Position',[xpos, ypos, 1]);
        end 
    end
    
    %custom color map for colorbar
    cmap = [0 0 0.560784339904785;0 0 0.780392169952393;0 0 1;0 0.0823529437184334 1;0 0.164705887436867 1;0 0.250980406999588 1;0 0.333333343267441 1;0 0.415686279535294 1;0 0.498039215803146 1;0 0.584313750267029 1;0 0.666666686534882 1;0 0.749019622802734 1;0 0.831372559070587 1;0 0.917647063732147 1;0 1 1;0 1 0.858823537826538;0 1 0.713725507259369;0 1 0.572549045085907;0 1 0.427450984716415;0 1 0.286274522542953;0 1 0.141176477074623;0 1 0;0.141176477074623 1 0;0.286274522542953 1 0;0.427450984716415 1 0;0.572549045085907 1 0;0.713725507259369 1 0;0.858823537826538 1 0;1 1 0;1 0.949019610881805 0;1 0.894117653369904 0;1 0.843137264251709 0;1 0.788235306739807 0;1 0.737254917621613 0;1 0.682352960109711 0;1 0.631372570991516 0;1 0.580392181873322 0;1 0.52549022436142 0;1 0.474509805440903 0;1 0.419607847929001 0;1 0.368627458810806 0;1 0.317647069692612 0;1 0.26274511218071 0;1 0.211764708161354 0;1 0.156862750649452 0;1 0.105882354080677 0;1 0.0509803928434849 0;1 0 0;0.968627452850342 0 0;0.937254905700684 0 0;0.905882358551025 0 0;0.874509811401367 0 0;0.843137264251709 0 0;0.811764717102051 0 0;0.780392169952393 0 0;0.752941191196442 0 0;0.721568644046783 0 0;0.690196096897125 0 0;0.658823549747467 0 0;0.627451002597809 0 0;0.596078455448151 0 0;0.564705908298492 0 0;0.533333361148834 0 0;0.501960813999176 0 0];
    
    t=colorbar('peer',hAxes);
    colormap(hAxes, cmap);
    set(get(t,'ylabel'),'String', 'Delta-V [km/s]');
    hX = xlabel(hAxes,[cap1stLetter(lower(departName)),' Departure Time (UT) [day]']);
    hY = ylabel(hAxes,[cap1stLetter(lower(arrivalName)),' Arrival Time (UT) [day]']);
    grid minor;
    
    try
        uistack(hAxes, 'top');
    catch 
        %nothing, doesn't work with AppDesigner uifigures
    end
    
    hold(hAxes,'off'); 
end

function txt = porkchopUpdateFcn(~, event_obj, xArr, yArr, zMat) 
    [~, ~, secInDay, ~] = getSecondsInVariousTimeUnits();

    pos = get(event_obj,'Position');
    secPerDay=secInDay;
    xpos = pos(1)*secPerDay;
    ypos = pos(2)*secPerDay;
    
    xind = find(abs(xArr-xpos)<1, 1);
    yind = find(abs(yArr-ypos)<1, 1);
    zMat = zMat';
    dv = zMat(xind,yind);
    
    [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(xpos);
    dateStrDept = formDateStr(year, day, hour, minute, sec);
    
    [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(ypos);
    dateStrArrive = formDateStr(year, day, hour, minute, sec);
    
    durationStr = getDurationStr(ypos - xpos);
    
    strLen = 19;
    
    if(isnan(dv))
        dvStr = '(no solution or above plot max)';
    else
        dvStr = [num2str(dv), ' km/s'];
    end
    
    txt = {[paddStr('Departure: ', strLen), dateStrDept], ...
           [paddStr('Arrival: ', strLen), dateStrArrive], ...
           [paddStr('Transfer Duration: ', strLen), durationStr], ...
           [paddStr('Est. Delta-V: ', strLen), dvStr]};
       
    set(0,'ShowHiddenHandles','on');                       
    hText = findobj('Type','text','Tag','DataTipMarker');  
    set(0,'ShowHiddenHandles','off');
    set(hText, 'FontName', 'fixedwidth');
    set(hText, 'FontSize', 8);
end