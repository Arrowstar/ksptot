function timeSliderStateChanged(src,evt, lvdData, handles)
    s = dbstack;
    matches = strfind({s.name},'timeSliderStateChanged');
    matches = cell2mat(matches(2:end));
    tf = any(matches == 1);
    
    if(getappdata(handles.hDispAxesTimeSlider,'lastTime') ~= javaMethodEDT('getValue',src) && not(tf))
        time = javaMethodEDT('getValue',src);
        hAx = handles.dispAxes;        

        markerTrajData = lvdData.viewSettings.selViewProfile.markerTrajData;
        markerBodyData = lvdData.viewSettings.selViewProfile.markerBodyData;
        markerBodyAxesData = lvdData.viewSettings.selViewProfile.markerTrajAxesData;
        markerGrdObjData = lvdData.viewSettings.selViewProfile.markerGrdObjData;
        
        markerTrajData.plotBodyMarkerAtTime(time, hAx);
        for(i=1:length(markerBodyData))
            markerBodyData(i).plotBodyMarkerAtTime(time, hAx);
        end
        
        markerBodyAxesData.plotBodyAxesAtTime(time, hAx);
        
        for(i=1:length(markerGrdObjData))
            markerGrdObjData(i).plotBodyMarkerAtTime(time, hAx);
        end
        
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
        
        setappdata(handles.hDispAxesTimeSlider,'lastTime',time);
        drawnow limitrate;
    end
end