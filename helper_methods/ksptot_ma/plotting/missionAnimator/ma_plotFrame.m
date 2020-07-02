function [bodyPlotted] = ma_plotFrame(hFig, mAxes, maData, stateLog, time, prevBody, orbitToPlot, celBodyData, handles)
%ma_plotFrame Summary of this function goes here
%   Detailed explanation goes here      
    global GLOBAL_VideoWriter GLOBAL_isRecording;
    persistent usrScMarker hCBodySurf preCbRotateAngle hCbGrdStn hOtherScPts hOtherScOrbits hCbGrdStnText hAnnote hChildBodies hChildBodyOrbits hSunBody hLight prevFrameTime curFrameTime;

    if(~isempty(usrScMarker) && ishandle(usrScMarker))
        delete(usrScMarker);
        usrScMarker = []; %#ok<NASGU>
    end
    
    [orbitToPlot, stateLog] = ma_getOrbitToPlot(stateLog, time);
    stateLogRow = getStateLogRowAtTime(stateLog, time);
    
    if(isempty(preCbRotateAngle))
        preCbRotateAngle = 0;
    end
    
    if(isempty(prevFrameTime) && isempty(curFrameTime))
        prevFrameTime = clock;
        curFrameTime = prevFrameTime;
    else
        curFrameTime = clock;
    end
       
    bodyPlotted = stateLogRow(8);
    if(bodyPlotted ~= prevBody)
        unfreezeColors(mAxes);
        cla(mAxes,'reset');
        [hCBodySurf] = plotStateLog(stateLog, handles, false, false, false, false, orbitToPlot, [], maData, celBodyData, mAxes, hFig);
        freezeColors(mAxes);
        set(hCBodySurf,'AmbientStrength',0.1);
        preCbRotateAngle = 0;
        
        if(~isnan(prevBody))
            set(handles.cameraSrcCombo,'Value',1);
            setSrcComboUserData(handles.cameraSrcCombo, handles, false);
            set(handles.cameraTgtCombo,'Value',2);
            setTgtComboUserData(handles.cameraTgtCombo, handles, false);
        end
        setCamSrcTgtComboBoxes(handles, time);
        
        axisWasReset = true;
    else
        axisWasReset = false;
    end
    
    if(axisWasReset && ~strcmpi(get(handles.cameraTypeCombo,'UserData'),'Inertially Fixed'))
%         axisLimMult = 15;
        axisLimMult = get(handles.axesScaleFactorText,'UserData');
    else
        axisLimMult = 1;
    end
    
    lims = zeros(0,2);
    lims(1,:) = get(mAxes,'XLim');
    lims(2,:) = get(mAxes,'YLim');
    lims(3,:) = get(mAxes,'ZLim');
    maxMax = axisLimMult * max(max(lims));
    maxMaxArr = [-maxMax maxMax -maxMax maxMax -maxMax maxMax];
    cLim = get(mAxes,'CLim');
    maxMaxArr = [maxMaxArr, cLim];
    axis(maxMaxArr);
    
    bodyID = stateLogRow(1,8);
    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);  
    
    bgColors = get(handles.backgroundColorCombo,'UserData');
    showGrid = get(handles.showGridCheckbox,'UserData');
    if(strcmpi(showGrid,'on'))
        set(mAxes,'Color',bgColors(1),'XColor',bgColors(2),'YColor',bgColors(3),'ZColor',bgColors(4));
    else
        set(mAxes,'Color',bgColors(1),'XColor',bgColors(1),'YColor',bgColors(1),'ZColor',bgColors(1));
    end
    grid(mAxes,showGrid);
    
	switch(get(handles.cameraTypeCombo,'UserData'))
        case 'Inertially Fixed'
            azView = get(handles.azOffsetText,'UserData');
            elView = get(handles.elOffsetText,'UserData');
            
            view(mAxes, [azView,elView]);
        case 'Spacecraft Fixed'
            camSrcStr = get(handles.cameraSrcCombo,'UserData');
            camTgtStr = get(handles.cameraTgtCombo,'UserData');
            
            [typeStrSrc, ~, idStrSrc] = parseSrcTgtStrings(camSrcStr);
            [typeStrTgt, ~, idStrTgt] = parseSrcTgtStrings(camTgtStr);
            
            rPosCam = getPositOfObject(maData, time, stateLogRow, typeStrSrc, idStrSrc, bodyInfo, celBodyData);
            rPosTgt = getPositOfObject(maData, time, stateLogRow, typeStrTgt, idStrTgt, bodyInfo, celBodyData);

            camViewVect = rPosTgt - rPosCam;
            
            [cAz,cEl,cR] = cart2sph(camViewVect(1),camViewVect(2),camViewVect(3));
            
            azAdd = deg2rad(get(handles.azOffsetText,'UserData'));
            elAdd = deg2rad(get(handles.elOffsetText,'UserData'));
            rngAdd = get(handles.rngOffsetText,'UserData');
            
            cAz = cAz + azAdd;
            cEl = cEl - elAdd;
            cR = cR + rngAdd;
           
            [cX,xY,cZ] = sph2cart(cAz,cEl,cR);
            camViewVect = [cX,xY,cZ];
            
            rPosCam = rPosTgt - camViewVect;
            
            campos(mAxes,rPosCam); camtarget(mAxes,rPosTgt);
            camva(mAxes,get(handles.fieldOfViewText,'UserData'));
    end
      
    topLevelBodyInfo = getTopLevelCentralBody(celBodyData);
    rVectSun = getAbsPositBetweenSpacecraftAndBody(time, [0,0,0]', bodyInfo, topLevelBodyInfo, celBodyData);
    if(norm(rVectSun) < 0.01)
        rVectSun = [0 0 0.01];
    end
    
    rVectSun = normVector(rVectSun);
    if(isempty(hLight) || ~ishghandle(hLight))
        hLight = light('Position',rVectSun,'Parent',mAxes,'style','infinite');
    else
        set(hLight,'Position',rVectSun);
    end
    
    hold(mAxes,'on');
    markerColor = get(handles.spacecraftMarkerColorCombo,'UserData');
    lineSpec = [get(handles.spacecraftMarkerCombo,'UserData'),markerColor];
    markerSize = get(handles.scMarkerSizeCombo,'UserData');
    usrScMarker = plot3(mAxes, stateLogRow(2),stateLogRow(3),stateLogRow(4),lineSpec,'MarkerSize',markerSize,'MarkerFaceColor',markerColor);
    hold(mAxes,'off');
    
%     cbSpinAngle = getBodySpinAngle(bodyInfo, time);
%     dAlpha = rad2deg(cbSpinAngle) - preCbRotateAngle;
%     rotate(hCBodySurf,[0,0,1],dAlpha,[0,0,0]);
%     set(hCBodySurf,'NormalMode','auto');
%     preCbRotateAngle = rad2deg(cbSpinAngle);
    
    if(~isempty(hCbGrdStn(ishghandle(hCbGrdStn))))
        delete(hCbGrdStn(ishghandle(hCbGrdStn))); hCbGrdStn = [];
    end
    
    if(get(handles.showGroundStationsCheckbox,'UserData')==1)
        stations = maData.spacecraft.stations;
        bdyStnFHdl = @(stnStruct) plotLocOfGrndStation(mAxes, stnStruct, bodyID, time, [0,0,0]', bodyInfo);
        
        [hCbGrdStn] = cellfun(bdyStnFHdl, stations,'UniformOutput',false);
        hCbGrdStn = [hCbGrdStn{:}];
    end
    
    delete(hOtherScPts(ishghandle(hOtherScPts)));
    delete(hOtherScOrbits(ishghandle(hOtherScOrbits)));
    if(get(handles.showOtherScCheckbox,'UserData')==1)
        otherSCs = maData.spacecraft.otherSC; %hOtherScOrbits
        
        otherScFHdl = @(oScStruct) plotLocOfOtherSC(mAxes, oScStruct, bodyID, time, [0,0,0]', bodyInfo, true, true);
        
        [hOtherScPts, hOtherScOrbits] = cellfun(otherScFHdl, otherSCs,'UniformOutput',false);
        hOtherScPts = [hOtherScPts{:}];
        hOtherScOrbits = [hOtherScOrbits{:}];
    end
        
    delete(hChildBodies(ishghandle(hChildBodies))); hChildBodies = [];
    showChildBodies = get(handles.showChildBodiesCheckbox,'UserData');
    showChildBodyOrbits = get(handles.showChildBodyOrbitsCheckbox,'UserData');
    if(showChildBodies == 1 || showChildBodyOrbits == 1)
        [children, ~] = getChildrenOfParentInfo(celBodyData, bodyInfo.name);
        for(i=1:length(children)) %#ok<*NO4LP>
            child = children{i};
            
            if(showChildBodies==1)
                [rVect, ~] = getStateAtTime(child, time, bodyInfo.gm);

                useR = child.radius;
                mColor = colorFromColorMap(child.bodycolor);
                
                [cX, cY, cZ] = sphere(30);
                hold(mAxes,'on')
                hChildBodies(end+1) = plot3(rVect(1), rVect(2), rVect(3),'Marker','o','MarkerEdgeColor',mColor,'MarkerFaceColor',mColor,'MarkerSize',3); %#ok<AGROW>
                hold(mAxes,'off')
                hChildBodies(end+1) = surface(rVect(1) + useR*cX, rVect(2) + useR*cY, rVect(3) + useR*cZ); %#ok<AGROW>
                colormap(mAxes, child.bodycolor)
                freezeColors(mAxes);
            end
            
            if(showChildBodyOrbits == 1) 
                if(axisWasReset || length(hChildBodyOrbits) < length(children))
                    if(length(hChildBodyOrbits) < length(children))
                        if(i==1)
                            delete(hChildBodyOrbits(ishghandle(hChildBodyOrbits)));
                            hChildBodyOrbits = [];
                        end
                    end
                    hChildBodyOrbits(end+1) = plotBodyOrbit(child, '', bodyInfo.gm, false, mAxes, 0.5, '--'); %#ok<AGROW>
                end
            else
                delete(hChildBodyOrbits(ishghandle(hChildBodyOrbits))); hChildBodyOrbits = [];
            end
        end
    elseif(showChildBodyOrbits ~= 1)
        delete(hChildBodyOrbits(ishghandle(hChildBodyOrbits))); hChildBodyOrbits = [];
    end
        
    aShowUT = get(handles.annoteShowUTCheckbox,'UserData');
	aShowOrbit = get(handles.annoteShowOrbitCheckbox,'UserData');
    aShowLatLong = get(handles.annoteShowLatLongCheckbox,'UserData');
    aShowMass = get(handles.annoteShowMassCheckbox,'UserData');
    aShowFps = get(handles.showFpsCheckbox,'UserData');
    aShowEvent = get(handles.showEventNameCheckbox,'UserData');
    
    if(aShowUT==1 || aShowOrbit==1 || aShowLatLong==1 || aShowMass==1 || aShowFps==1 || aShowEvent==1)
        annonStr = cell(0,1);
        
        if(aShowUT==1)
            [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(time);
            dateStr = formDateStr(year, day, hour, minute, sec);
            annonStr{end+1} = dateStr;
        end
        
        if(aShowOrbit==1)
            rVect = stateLogRow(2:4);
            vVect = stateLogRow(5:7);
            gmu = bodyInfo.gm;
            [sma, ecc, inc, raan, arg, tru] = getKeplerFromState(rVect,vVect,gmu);
            oStr = sprintf('Orbit\n   Orbiting=%s\n   SMA=%g km\n   Ecc=%g\n   Inc=%g deg\n   RAAN=%g deg\n   Arg=%g deg\n   Tru=%g deg', bodyInfo.name, sma, ecc, rad2deg(inc), rad2deg(raan), rad2deg(arg), rad2deg(tru));
            annonStr{end+1} = oStr;
        end
        
        if(aShowEvent==1)
            eventName = maData.script{stateLogRow(13)}.name;
            annonStr{end+1} = sprintf('Event: %s', eventName);
        end

        if(aShowLatLong==1)
            rVect = stateLogRow(2:4)';
            vVect = stateLogRow(5:7)';
            [lat, long, alt] = getLatLongAltFromInertialVect(time, rVect, bodyInfo, vVect);
            ffStr = sprintf('Rotating Frame Position\n   Lat.=%g deg\n   Long.=%g deg\n   Alt.=%g km', rad2deg(lat), rad2deg(long), alt);
            annonStr{end+1} = ffStr;
        end

        if(aShowMass==1)
            totMass = sum(stateLogRow(9:12));
            dryMass = sum(stateLogRow(9));
            fuelOxMass = sum(stateLogRow(10));
            mpMass = sum(stateLogRow(11));
            xeMass = sum(stateLogRow(12));
            
            propNames = maData.spacecraft.propellant.names;
            if(length(propNames{1}) > 11)
                propNames{1} = propNames{1}(1:11);
            end
            if(length(propNames{2}) > 11)
                propNames{2} = propNames{2}(1:11);
            end
            if(length(propNames{3}) > 11)
                propNames{3} = propNames{3}(1:11);
            end
            
            massStr = sprintf('Spacecraft Masses\n   Total Mass=%g ton\n   Dry Mass=%g ton\n   %s=%g ton\n   %s=%g ton\n   %s=%g ton', totMass, dryMass, propNames{1}, fuelOxMass, ...
                              propNames{2}, mpMass, propNames{3}, xeMass);
            annonStr{end+1} = massStr;
        end
        
        if(aShowFps==1)
            fps = 1/etime(curFrameTime,prevFrameTime);
            if(~isfinite(fps))
                fps = 0;
            end
            annonStr{end+1} = sprintf('Frame Rate\n   FPS=%g',fps);
        end
        
%         annonStr =  strtrim(char(annonStr));
        annonStrN = {}; 
        for(i=1:length(annonStr))
            ss = strsplit(annonStr{i},char(10))';
            for(j=1:length(ss))
                ss{j} = horzcat(ss{j},'          ');
            end
            annonStrN = vertcat(annonStrN,ss); %#ok<AGROW>
        end
        
        if(isempty(hAnnote) || ~ishghandle(hAnnote))
            hAnnote = annotation('textbox',[0.77 0.84 0.22 0.1], 'String',annonStrN,'Tag','dataText','VerticalAlignment','top','BackgroundColor','w','FontName','FixedWidth','FontSize',8,'FitBoxToText','on','Margin',5);
        else
            set(hAnnote,'String',annonStrN);
        end
    else
        delete(hAnnote(ishghandle(hAnnote)));
        delete(findall(mAxes,'Tag','dataText'));
    end
       
    prevFrameTime = curFrameTime;
    
    if(GLOBAL_isRecording)
        GLOBAL_VideoWriter.writeVideo(getframe(hFig,get(mAxes,'Position')));
    end
    
    shading(mAxes,'interp');
    drawnow;
end

function rPosCam = getPositOfObject(maData, time, stateLogRow, typeStr, idStr, bodyInfo, celBodyData)
    switch(typeStr)
        case 'sc'
            rPosCam = [stateLogRow(2),stateLogRow(3),stateLogRow(4)];
        case 'cb'
            rPosCam = [0,0,0];
        case 'osc'
            rPosCam = getRelPositionOfOtherSpacecraft(maData, idStr, stateLogRow(1), bodyInfo, celBodyData);
        case 'grd'
            rPosCam = getRelPositionOfGroundStation(maData, idStr, stateLogRow(1), bodyInfo, celBodyData);
        case 'chBd'        
            bodyOther = getBodyInfoByNumber(str2double(idStr), celBodyData);
            [rVect, ~] = getStateAtTime(bodyOther, time, bodyInfo.gm);
            
            rPosCam = rVect;
        otherwise
            error('Unknown type string when computing position of object for mission animator camera.');
    end
    
    rPosCam = reshape(rPosCam,1,3);
end

function rPosCam = getRelPositionOfGroundStation(maData, grnID, time, mainScOrbitingBodyInfo, celBodyData)
    lookingFor = str2double(grnID);

    station = [];
    stations = maData.spacecraft.stations;
    for(i=1:length(stations))
        stationTemp = stations{i};
        if(abs(stationTemp.id == lookingFor) < 1E-12)
            station = stationTemp;
            break;
        end
    end
    
    if(isempty(station))
        error('Did not find ground station with ID %s for use in setting camera src/tgt.', oscID);
    end
    
    bodyInfoStn = getBodyInfoByNumber(station.parentID, celBodyData);
    
    lat = station.lat;
    long = station.long;
    alt = station.alt;
    
    rVectStn = getInertialVectFromLatLongAlt(time, lat, long, alt, bodyInfoStn, [NaN;NaN;NaN]);
    rPosCam = -getAbsPositBetweenSpacecraftAndBody(time, rVectStn, bodyInfoStn, mainScOrbitingBodyInfo, celBodyData); %might need a negative sign here
end

function rPosCam = getRelPositionOfOtherSpacecraft(maData, oscID, time, mainScOrbitingBodyInfo, celBodyData)
    lookingFor = str2double(oscID);

    otherSC = [];
    otherSCs = maData.spacecraft.otherSC;
    for(i=1:length(otherSCs))
        otherSCTemp = otherSCs{i};
        if(abs(otherSCTemp.id - lookingFor) < 1E-12)
            otherSC = otherSCTemp;
            break;
        end
    end
    
    if(isempty(otherSC))
        error('Did not find other spacecraft with ID %s for use in setting camera src/tgt.', oscID);
    end
    
    bodyInfoOSC = getBodyInfoByNumber(otherSC.parentID, celBodyData);
    
    epoch = otherSC.epoch;
    sma = otherSC.sma;
    ecc = otherSC.ecc;
    inc = deg2rad(otherSC.inc);
    raan =  deg2rad(otherSC.raan);
    arg = deg2rad(otherSC.arg);
    mean = deg2rad(otherSC.mean);

    inputOrbit = [sma, ecc, inc, raan, arg, mean, epoch];
    otherScInfo = getBodyInfoStructFromOrbit(inputOrbit);

    [rVectSC, ~] = getStateAtTime(otherScInfo, time, bodyInfoOSC.gm);
    rPosCam = -getAbsPositBetweenSpacecraftAndBody(time, rVectSC, bodyInfoOSC, mainScOrbitingBodyInfo, celBodyData); %might need a negative sign here
end

function [typeStr, nameStr, idStr] = parseSrcTgtStrings(str)
    pattern1 = '([\w]*): ([\w ]*)';
    pattern2 = '(id: ([0-9\.]+)\)*?';
    tokens1 = regexp(str,pattern1,'tokens');
    tokens2 = regexp(str,pattern2,'tokens');
    
    typeStr = strtrim(tokens1{1}{1});
    nameStr = strtrim(tokens1{1}{2});
    if(~isempty(tokens2))
        idStr = tokens2{1}{1};
    else
        idStr = '';
    end
end

function [hCbGrdStn] = plotLocOfGrndStation(hAxis, stnStruct, validBodyID, ut, posOffset, bodyInfo)
    hCbGrdStn = [];
    if(stnStruct.parentID == validBodyID)
        lat = stnStruct.lat;
        long = stnStruct.long;
        alt = stnStruct.alt;
        color = stnStruct.color;
        markerSym = stnStruct.markerSymbol;
        rVectECI = getInertialVectFromLatLongAlt(ut, lat, long, alt, bodyInfo, [NaN;NaN;NaN]);
        
        hold on;
        pos = rVectECI+posOffset;
        hCbGrdStn = plot3(hAxis, pos(1), pos(2), pos(3), markerSym, 'Color',color, 'MarkerFaceColor',color, 'MarkerSize', 6);
%         hCbGrdStnText = text(pos(1), pos(2), pos(3),stnStruct.name,'BackgroundColor','w'); 
        hold off;
    end
end