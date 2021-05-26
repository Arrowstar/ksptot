function timeSliderStateChanged(src,evt, lvdData, handles, app)
    s = dbstack;
    matches = strfind({s.name},'timeSliderStateChanged');
    matches = cell2mat(matches(2:end));
    tf = any(matches == 1);
    
    if(not(tf))
        try
            time = evt.Value;
        catch
            time = src.Value;
        end
        hAx = handles.dispAxes;        

        markerTrajData = lvdData.viewSettings.selViewProfile.markerTrajData;
        markerBodyData = lvdData.viewSettings.selViewProfile.markerBodyData;
        markerBodyAxesData = lvdData.viewSettings.selViewProfile.markerTrajAxesData;
        markerGrdObjData = lvdData.viewSettings.selViewProfile.markerGrdObjData;
        centralBodyData = lvdData.viewSettings.selViewProfile.centralBodyData;
        pointData = lvdData.viewSettings.selViewProfile.pointData;
        vectorData = lvdData.viewSettings.selViewProfile.vectorData;
        refFrameData = lvdData.viewSettings.selViewProfile.refFrameData;
        angleData = lvdData.viewSettings.selViewProfile.angleData;
        planeData = lvdData.viewSettings.selViewProfile.planeData;
        
        markerTrajData.plotBodyMarkerAtTime(time, hAx);
        
        for(i=1:length(markerBodyData))
            markerBodyData(i).plotBodyMarkerAtTime(time, hAx);
        end
        
        markerBodyAxesData.plotBodyAxesAtTime(time, hAx);
        
        for(i=1:length(markerGrdObjData))
            markerGrdObjData(i).plotBodyMarkerAtTime(time, hAx);
        end
        
        for(i=1:length(refFrameData))
            refFrameData(i).plotRefFrameAtTime(time, hAx);
        end
        
        for(i=1:length(vectorData))
            vectorData(i).plotVectorAtTime(time, hAx);
        end
        
        for(i=1:length(angleData))
            angleData(i).plotAngleAtTime(time, hAx);
        end
        
        for(i=1:length(planeData))
            planeData(i).plotPlaneAtTime(time, hAx);
        end
        
        for(i=1:length(pointData))
            pointData(i).plotPointAtTime(time, hAx);
        end
        
        centralBodyData.setCentralBodyRotation(time);
        
        lvdData.viewSettings.selViewProfile.updateLightPosition(time);
        
        [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(time);
        epochStr = formDateStr(year, day, hour, minute, sec);
        
        [~, timeEvtsListboxStrs] = lvdData.script.getAllEvtsThatOccurAtTime(time);
        for(i=1:length(timeEvtsListboxStrs))
            timeEvtsListboxStrs(i) = sprintf('Event: %s',timeEvtsListboxStrs(i));
        end
        evtsStr = strjoin(timeEvtsListboxStrs,'\n');
        
        if(not(isempty(timeEvtsListboxStrs)))
            dashes = repmat('-',1,max(strlength(timeEvtsListboxStrs)));
        else
            dashes = '';
        end
        
        tooltipStr = sprintf('UT = %0.3f sec\n%s\n%s', time, dashes, evtsStr);
        
        handles.timeSliderValueLabel.String = epochStr;
        handles.timeSliderValueLabel.TooltipString = tooltipStr;
        
        setappdata(app.DispAxesTimeSlider,'lastTime',time);
        drawnow limitrate;
    end
end