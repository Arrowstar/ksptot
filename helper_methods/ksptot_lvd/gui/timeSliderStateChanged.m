function timeSliderStateChanged(src,evt, lvdData, handles, app)
    arguments
        src matlab.ui.control.Slider
        evt matlab.ui.eventdata.ValueChangingData
        lvdData LvdData
        handles struct
        app ma_LvdMainGUI_App
    end

    persistent lastCall

    if(isempty(lastCall))
        lastCall = tic;
    end

    elapsedTime = toc(lastCall);
    if(elapsedTime < 0.05)
        return;
    end

    %We need to do this because for some reason the slider rotates, pans,
    %or zooms the axes if a camera toolbar mode is selected.
    m = cameratoolbar(app.ma_LvdMainGUI, 'GetMode');
    if(not(isempty(m)))
        cameratoolbar(app.ma_LvdMainGUI, 'SetMode','nomode');
        app.panPushMenuToggle.State ="off";
        app.rotatePushMenuToggle.State ="off";
        app.zoomOutPushMenuToggle.State ="off";
        app.zoomInPushMenuToggle.State ="off";
    end

%     s = dbstack;
%     matches = strfind({s.name},'timeSliderStateChanged');
%     matches = cell2mat(matches(2:end));
%     tf = any(matches == 1);
    
    tf = false;

    if(not(tf))
        try
            time = evt.Value;
        catch ME
            time = src.Value;
        end

        time = double(time);
        hAx = app.dispAxes;
        grdTrkAx = app.GroundTrackAxes;

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
        vehGrdTrkData = lvdData.viewSettings.selViewProfile.vehicleGrdTrackData;
        celBodyGrdTrackData = lvdData.viewSettings.selViewProfile.celBodyGrdTrackData;
        grdObjGrdTrkData = lvdData.viewSettings.selViewProfile.grdObjGrdTrackData;
        
%         notify(app, 'GenericStatusLabelUpdate', GenericStatusLabelUpdate('Drawing Scene...'));
        
%         notify(app, 'GenericStatusLabelUpdate', GenericStatusLabelUpdate('Drawing Vehicle Trajectory...'));
        markerTrajData.plotBodyMarkerAtTime(time, hAx);
        
%         notify(app, 'GenericStatusLabelUpdate', GenericStatusLabelUpdate('Drawing Celestial Bodies...'));
        for(i=1:length(markerBodyData)) %#ok<*NO4LP> 
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

        %set vehicle location on ground track
        if(not(isempty(vehGrdTrkData)))
            vehGrdTrkData.plotBodyMarkerAtTime(time,grdTrkAx);
        end

        %plot celestial bodies on ground track
        for(i=1:length(celBodyGrdTrackData))
            celBodyGrdTrackData(i).plotCelBodyMarkerAtTime(time, grdTrkAx);
        end

        %plot grd obj on ground track
        for(i=1:length(grdObjGrdTrkData))
            grdObjGrdTrkData(i).plotGrdObjMarkerAtTime(time, grdTrkAx);
        end
        
        centralBodyData.setCentralBodyRotation(time);
        
%         notify(app, 'GenericStatusLabelUpdate', GenericStatusLabelUpdate('Creating Light Source...'));
        lvdData.viewSettings.selViewProfile.updateLightPosition(time);
        lvdData.viewSettings.selViewProfile.grdTrackLighting.updateSunLightingPosition(time);
        
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
        
        app.timeSliderValueLabel.Text = epochStr;
        app.timeSliderValueLabel.Tooltip = tooltipStr;
        
        setappdata(app.DispAxesTimeSlider,'lastTime',time);
        drawnow limitrate;
        lastCall = tic;
    end
end