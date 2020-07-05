classdef LaunchVehicleViewProfile < matlab.mixin.SetGet
    %LaunchVehicleViewProfile Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %profile properties
        name(1,:) char = 'Untitled View Profile';
        desc(1,1) string = "";
        
        %axes properties
        backgroundColor(1,1) ColorSpecEnum = ColorSpecEnum.White;
        gridType(1,1) ViewGridTypeEnum = ViewGridTypeEnum.Major;
        majorGridColor(1,1) ColorSpecEnum = ColorSpecEnum.DarkGrey;
        minorGridColor(1,1) ColorSpecEnum = ColorSpecEnum.DarkGrey;
        gridTransparency(1,1) double = 0.15;
        
        %trajectory view options
        trajEvtsViewType(1,1) ViewEventsTypeEnum = ViewEventsTypeEnum.SoIChunk %either chunked by event/SoI or all
        frame AbstractReferenceFrame
                
        %body fixed options
        showLongLatAnnotations(1,1) logical = true;
        
        %SoI and other body options
        showSoIRadius(1,1) logical = false;
        bodiesToPlot(1,:) KSPTOT_BodyInfo = KSPTOT_BodyInfo.empty(1,0);
        bodyPlotStyle(1,1) ViewProfileBodyPlottingStyle = ViewProfileBodyPlottingStyle.Dot;
        
        %view properties (set by user indirectly through UI controls)
        orbitNumToPlot(1,1) double = 1;
        viewAzEl(1,2) = [-37.5, 30]; %view(3)
        markerTrajData(1,:) LaunchVehicleViewProfileTrajectoryData = LaunchVehicleViewProfileTrajectoryData.empty(1,0);
        markerBodyData(1,:) LaunchVehicleViewProfileBodyData = LaunchVehicleViewProfileBodyData.empty(1,0);
    end
    
    properties(Access=private)
        generic3DTrajView(1,1) Generic3DTrajectoryViewType = Generic3DTrajectoryViewType();
    end
    
    methods
        function obj = LaunchVehicleViewProfile()           
            
        end
                
        function plotTrajectory(obj, lvdData, handles)
            obj.generic3DTrajView.plotStateLog(obj.orbitNumToPlot, lvdData, obj, handles);
        end
        
        function createTrajectoryMarkerData(obj, subStateLogs, evts)
            obj.clearAllTrajData();
            trajMarkerData = obj.createTrajData();
            
            for(j=1:length(subStateLogs))
                if(size(subStateLogs{j},1) > 0)
                    times = subStateLogs{j}(:,1);
                    rVects = subStateLogs{j}(:,2:4);

                    evtNum = subStateLogs{j}(1,13);
                    evt = evts(evtNum);
                    evtColor = evt.colorLineSpec.color;

                    switch(evt.plotMethod)
                        case EventPlottingMethodEnum.PlotContinuous
                            %nothing

                        case EventPlottingMethodEnum.SkipFirstState
                            times = times(2:end);
                            rVects = rVects(2:end,:);

                        case EventPlottingMethodEnum.DoNotPlot
                            times = [];
                            rVects = [];

                        otherwise
                            error('Unknown event plotting method: %s', EventPlottingMethodEnum.DoNotPlot.name);
                    end

                    [times,ia,~] = unique(times,'stable','rows');
                    rVects = rVects(ia,:);

                    if(length(unique(times)) > 1)
                        trajMarkerData.addData(times, rVects, evtColor);
                    end
                end
            end
        end
        
        function createBodyMarkerData(obj, dAxes, subStateLogs, viewInFrame, showSoI)
            obj.clearAllBodyData();
            
            for(i=1:length(obj.bodiesToPlot))
                bodyToPlot = obj.bodiesToPlot(i);
                bColorRGB = bodyToPlot.getBodyRGB();
                
                if(bodyToPlot.sma > 0)
                    bodyOrbitPeriod = computePeriod(bodyToPlot.sma, bodyToPlot.gm);
                else
                    bodyOrbitPeriod = Inf;
                end
                
                bodyMarkerData = obj.createBodyData(bodyToPlot, obj.bodyPlotStyle, showSoI);
                
                for(j=1:length(subStateLogs))
                    if(size(subStateLogs{j},1) > 0)
                        times = subStateLogs{j}(:,1);

                        if(isfinite(bodyOrbitPeriod))
                            numPeriods = (max(times) - min(times))/bodyOrbitPeriod;
                            times = linspace(min(times), max(times), max(1000*numPeriods,length(times)));
                        else
                            times = linspace(min(times), max(times), length(times));
                        end

                        states = bodyToPlot.getElementSetsForTimes(times);

                        for(k=1:length(states))
                            states(k) = states(k).convertToFrame(viewInFrame);
                        end

                        rVects = [states.rVect];
                        plot3(dAxes, rVects(1,:), rVects(2,:), rVects(3,:), '-', 'Color',bColorRGB, 'LineWidth',1.5);

                        if(length(unique(times)) > 1)
                            bodyMarkerData.addData(times, rVects);
                        end
                    end
                end
            end
        end
        
        function configureTimeSlider(obj, minTime, maxTime, subStateLogs, handles)
            timeSlider = handles.jDispAxesTimeSlider;
            curSliderTime = timeSlider.getValue();
            if(not(isfinite(minTime) && isfinite(maxTime)))
                onlyTime = subStateLogs{1}(1,1);
                
                minTime = onlyTime;
                maxTime = onlyTime + 1;
            end
            timeSlider.setMinimum(minTime);
            timeSlider.setMaximum(maxTime);
            timeSlider.setMajorTickSpacing((maxTime - minTime)/10);
            timeSlider.setMinorTickSpacing((maxTime - minTime)/100);
            
            if(curSliderTime > maxTime)
                timeSlider.setValue(maxTime);
            elseif(curSliderTime < minTime)
                timeSlider.setValue(minTime);
            end
            
            handles.hDispAxesTimeSlider.StateChangedCallback(timeSlider, []);
        end
        
        function trajData = createTrajData(obj)
            trajData = LaunchVehicleViewProfileTrajectoryData();
            obj.markerTrajData = trajData;
        end
        
        function bodyData = createBodyData(obj, bodyInfo, bodyPlotStyle, showSoI)
            bodyData = LaunchVehicleViewProfileBodyData(bodyInfo, bodyPlotStyle, showSoI);
            obj.markerBodyData(end+1) = bodyData;
        end
        
        function clearAllTrajData(obj)
            obj.markerTrajData = LaunchVehicleViewProfileTrajectoryData.empty(1,0);
        end
        
        function clearAllBodyData(obj)
            obj.markerBodyData = LaunchVehicleViewProfileBodyData.empty(1,0);
        end
    end
end

