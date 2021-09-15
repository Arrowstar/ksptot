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
        sensorData = lvdData.viewSettings.selViewProfile.sensorData;
        sensorTgtData = lvdData.viewSettings.selViewProfile.sensorTgtData;
        
        notify(app, 'GenericStatusLabelUpdate', GenericStatusLabelUpdate('Drawing Scene...'));
        
%         notify(app, 'GenericStatusLabelUpdate', GenericStatusLabelUpdate('Drawing Vehicle Trajectory...'));
        markerTrajData.plotBodyMarkerAtTime(time, hAx);
        
%         notify(app, 'GenericStatusLabelUpdate', GenericStatusLabelUpdate('Drawing Celestial Bodies...'));
        for(i=1:length(markerBodyData))
            markerBodyData(i).plotBodyMarkerAtTime(time, hAx);
        end
        
%         notify(app, 'GenericStatusLabelUpdate', GenericStatusLabelUpdate('Drawing Vehicle Body Axes...'));
        markerBodyAxesData.plotBodyAxesAtTime(time, hAx);
        
%         notify(app, 'GenericStatusLabelUpdate', GenericStatusLabelUpdate('Drawing Ground Objects...'));
        for(i=1:length(markerGrdObjData))
            markerGrdObjData(i).plotBodyMarkerAtTime(time, hAx);
        end
        
%         notify(app, 'GenericStatusLabelUpdate', GenericStatusLabelUpdate('Drawing Geometric Reference Frames...'));
        for(i=1:length(refFrameData))
            refFrameData(i).plotRefFrameAtTime(time, hAx);
        end
        
%         notify(app, 'GenericStatusLabelUpdate', GenericStatusLabelUpdate('Drawing Geometric Vectors...'));
        for(i=1:length(vectorData))
            vectorData(i).plotVectorAtTime(time, hAx);
        end
        
%         notify(app, 'GenericStatusLabelUpdate', GenericStatusLabelUpdate('Drawing Geometric Angles...'));
        for(i=1:length(angleData))
            angleData(i).plotAngleAtTime(time, hAx);
        end
        
%         notify(app, 'GenericStatusLabelUpdate', GenericStatusLabelUpdate('Drawing Geometric Planes...'));
        for(i=1:length(planeData))
            planeData(i).plotPlaneAtTime(time, hAx);
        end
        
%         notify(app, 'GenericStatusLabelUpdate', GenericStatusLabelUpdate('Drawing Geometric Points...'));
        for(i=1:length(pointData))
            pointData(i).plotPointAtTime(time, hAx);
        end
        
%         notify(app, 'GenericStatusLabelUpdate', GenericStatusLabelUpdate('Drawing Sensors...'));
        sensorTgtResults = SensorTargetResults.empty(1,0);
        for(i=1:length(sensorData))
            subResults = sensorData(i).plotSensorAtTime(time, hAx);
            sensorTgtResults = horzcat(sensorTgtResults, subResults(:)'); %#ok<AGROW>
        end
        
        if(numel(sensorTgtResults) > 0)
%             notify(app, 'GenericStatusLabelUpdate', GenericStatusLabelUpdate('Drawing Sensor Targets...'));
            
            mergedResults = SensorTargetResults.mergeResults(sensorTgtResults);
            for(i=1:length(sensorTgtData))
                sensorTgtData(i).plotTargetResults(mergedResults, hAx);
            end
        end
        
        centralBodyData.setCentralBodyRotation(time);
        
%         notify(app, 'GenericStatusLabelUpdate', GenericStatusLabelUpdate('Creating Light Source...'));
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