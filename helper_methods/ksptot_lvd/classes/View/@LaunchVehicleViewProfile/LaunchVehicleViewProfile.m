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
        meshEdgeAlpha(1,1) double = 0.1;

        %render mode
        renderer(1,1) FigureRendererEnum = FigureRendererEnum.OpenGL;
        
        %axis properties
        dispXAxis(1,1) logical = false;
        dispYAxis(1,1) logical = false;
        dispZAxis(1,1) logical = false;
        
        %trajectory view options
        trajEvtsViewType(1,1) ViewEventsTypeEnum = ViewEventsTypeEnum.SoIChunk %either chunked by event/SoI or all
        frame AbstractReferenceFrame
        
        %body fixed options
        showLongLatAnnotations(1,1) logical = true;
        
        %thrust vectors
        showThrustVectors(1,1) logical = false;
        thrustVectColor(1,1) ColorSpecEnum  = ColorSpecEnum.Red;
        thrustVectLineType(1,1) LineSpecEnum = LineSpecEnum.SolidLine;
        thrustVectScale(1,1) double = 1;
        thrustVectEntryIncr(1,1) double = 1;
        
        %SoI and other body options
        showSoIRadius(1,1) logical = false;
        bodiesToPlot(1,:) KSPTOT_BodyInfo = KSPTOT_BodyInfo.empty(1,0);
        bodyPlotStyle(1,1) ViewProfileBodyPlottingStyle = ViewProfileBodyPlottingStyle.Dot;
        
        %show sc body axes
        showScBodyAxes(1,1) logical = false;
        scBodyAxesScale(1,1) double = 100; %km
        
        %lighting
        showLighting(1,1) logical = false;
        showSunVect(1,1) logical = false;
        
        %show atmosphere
        showAtmosphere(1,1) logical = false;
        
        %ground objects
        groundObjsToPlot(1,:) LaunchVehicleGroundObject
        showGndTracks(1,1) logical = true;
        showGrdObjLoS(1,1) logical = true;
        
        %central body transform
        hCBodySurfXForm = matlab.graphics.GraphicsPlaceholder();
        
        %view properties (set by user indirectly through UI controls)
        updateViewAxesLimits(1,1) logical = true;
        orbitNumToPlot(1,1) double = 1;
        viewAzEl(1,2) = [-37.5, 30]; %view(3)
        viewZoomAxLims(3,2) double = NaN(3,2);
    end
    
    properties(Transient)
        markerTrajData(1,:) LaunchVehicleViewProfileTrajectoryData = LaunchVehicleViewProfileTrajectoryData.empty(1,0);
        markerBodyData(1,:) LaunchVehicleViewProfileBodyData = LaunchVehicleViewProfileBodyData.empty(1,0);
        markerTrajAxesData(1,:) LaunchVehicleViewProfileBodyAxesData = LaunchVehicleViewProfileBodyAxesData.empty(1,0);
        markerGrdObjData(1,:) LaunchVehicleViewProfileGroundObjData = LaunchVehicleViewProfileGroundObjData.empty(1,0);
        sunLighting(1,:) LaunchVehicleViewProfileSunLighting = LaunchVehicleViewProfileSunLighting.empty(1,0);
        centralBodyData(1,:) LaunchVehicleViewProfileCentralBodyData = LaunchVehicleViewProfileCentralBodyData.empty(1,0);
    end
    
    properties(Access=private)
        generic3DTrajView(1,1) Generic3DTrajectoryViewType = Generic3DTrajectoryViewType();
    end
    
    methods
        function obj = LaunchVehicleViewProfile()
            
        end
        
        function removeGrdObjFromList(obj, grdObj)
            obj.groundObjsToPlot([obj.groundObjsToPlot] == grdObj) = [];
        end
        
        function plotTrajectory(obj, lvdData, handles)
%             profile on;
            obj.generic3DTrajView.plotStateLog(obj.orbitNumToPlot, lvdData, obj, handles);
%             profile viewer;
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
                    
                    [times,I] = sort(times);
                    rVects = rVects(I,:);
                    
                    if(length(unique(times)) > 1)
                        trajMarkerData.addData(times, rVects, evtColor);
                    end
                end
            end
        end
        
        function createBodyMarkerData(obj, dAxes, subStateLogs, viewInFrame, showSoI, meshEdgeAlpha, evts)
            obj.clearAllBodyData();
            
            timesArr = {};
            rVectArr = {};
            bodyColorsArr = {};
            bodyMarkerDataObjs = {};
            
%             pp = gcp('nocreate');
%             if(isempty(pp))
%                 M = 0;
%             else
%                 M = pp.NumWorkers;
%             end
            
%             profile off; profile on;
%             parfor(i=1:length(obj.bodiesToPlot), M)
            for(i=1:length(obj.bodiesToPlot))
                bodyToPlot = obj.bodiesToPlot(i); 
                timesInner = {};
                rVectsInner = {};
                
                if(bodyToPlot == viewInFrame.getOriginBody()) 
                    continue;
                end
                
                bColorRGB = bodyToPlot.getBodyRGB();
                
                bodyOrbitPeriod = [];
                if(bodyToPlot.sma > 0)
                    gmu = bodyToPlot.getParentGmuFromCache();
                    
                    if(not(isempty(gmu)) && not(isnan(gmu)) && isfinite(gmu))
                        bodyOrbitPeriod = computePeriod(bodyToPlot.sma, gmu);
                    end
                else
                    bodyOrbitPeriod = Inf;
                end
                
                bodyMarkerData = obj.createBodyData(bodyToPlot, obj.bodyPlotStyle, showSoI, meshEdgeAlpha);
                
                for(j=1:length(subStateLogs))
                    if(size(subStateLogs{j},1) > 0)
                        times = subStateLogs{j}(:,1);
                        
                        evtNum = subStateLogs{j}(1,13);
                        evt = evts(evtNum);
                        
                        if(isfinite(bodyOrbitPeriod))
                            numPeriods = (max(times) - min(times))/bodyOrbitPeriod;
                            times = linspace(min(times), max(times), max(10*numPeriods,length(times)));
                        else
                            times = linspace(min(times), max(times), length(times));
                        end
                        
                        states = bodyToPlot.getElementSetsForTimes(times);
                        if(numel(states) >= 1)
                            doConversion = states(1).frame ~= viewInFrame;
                        else
                            doConversion = true;
                        end
                        
                        for(k=1:length(states))
                            if(doConversion)
                                states(k) = states(k).convertToFrame(viewInFrame);
                            end
                        end
                        
                        rVects = [states.rVect];
                        
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
                                error('Unknown event plotting method: %s', evt.plotMethod.name);
                        end
                        
                        [times,ia,~] = unique(times,'stable');
                        rVects = rVects(:,ia);

                        [times,I] = sort(times);
                        rVects = rVects(:,I);
                        
                        timesInner{j} = times;
                        rVectsInner{j} = rVects;
                    end
                end

                timesArr{i} = timesInner;
                rVectArr{i} = rVectsInner;
                
                bodyColorsArr{i} = bColorRGB;
                bodyMarkerDataObjs{i} = bodyMarkerData;
            end
%             profile viewer;
            
            for(i=1:length(timesArr))
                timesInner = timesArr{i};
                rVectsInner = rVectArr{i};
                bColorRGB = bodyColorsArr{i};
                bodyMarkerData = bodyMarkerDataObjs{i};
                
                if(not(isempty(timesInner)))
                    obj.markerBodyData(end+1) = bodyMarkerData;
                    
                    for(j=1:length(timesInner))
                        times = timesInner{j};
                        rVects = rVectsInner{j};

                        if(length(unique(times)) > 1)
                            plot3(dAxes, rVects(1,:), rVects(2,:), rVects(3,:), '-', 'Color',bColorRGB, 'LineWidth',1.5);
                            bodyMarkerData.addData(times, rVects);
                        end
                    end
                end
            end
        end
        
        function createSunLightSrc(obj, dAxes, viewInFrame)
            obj.sunLighting = LaunchVehicleViewProfileSunLighting(dAxes, viewInFrame, obj.showLighting, obj.showSunVect);
        end
        
        function updateLightPosition(obj, time)
            obj.sunLighting.updateSunLightingPosition(time);
        end
        
        function createBodyAxesData(obj, lvdStateLogEntries, evts, viewInFrame)
            obj.clearAllBodyAxesData();
            obj.markerTrajAxesData = LaunchVehicleViewProfileBodyAxesData(obj.scBodyAxesScale);
            
            if(obj.showScBodyAxes)
                for(i=1:length(evts))
                    evt = evts(i);
                    evtStateLogEntries = lvdStateLogEntries([lvdStateLogEntries.event] == evt);
                                                            
                    times = [evtStateLogEntries.time];
                    rVects = NaN(3, length(evtStateLogEntries));
                    rotMatsBodyToView = NaN(3, 3, length(evtStateLogEntries));
                    for(j=1:length(evtStateLogEntries))
                        %get body position in view frame
                        entry = evtStateLogEntries(j);
                        cartElem = entry.getCartesianElementSetRepresentation();
                        cartElem = cartElem.convertToFrame(viewInFrame);

                        rVects(:,j) = cartElem.rVect;

                        %get body axes in view frame
                        rotMatBodyToInertial = entry.steeringModel.getBody2InertialDcmAtTime(entry.time, entry.position, entry.velocity, entry.centralBody);

                        [~, ~, ~, rotMatToInertial12] = viewInFrame.getOffsetsWrtInertialOrigin(entry.time);
                        [~, ~, ~, rotMatToInertial32] = entry.centralBody.getBodyCenteredInertialFrame().getOffsetsWrtInertialOrigin(entry.time);

                        rotMatsBodyToView(:,:,j) = rotMatToInertial12' * rotMatToInertial32 * rotMatBodyToInertial; %body to inertial -> inertial to inertial -> inertial to view frame
                    end

                    [times,ia,~] = unique(times,'stable');
                    rVects = rVects(:,ia);
                    rotMatsBodyToView = rotMatsBodyToView(:,:,ia);

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

                    if(length(times) >= 2 && all(diff(times)>0))
                        obj.markerTrajAxesData.addData(times, rVects, rotMatsBodyToView);
                    end
                end
            end
        end
        
        function createGroundObjMarkerData(obj, dAxes, lvdStateLogEntries, evts, viewInFrame, celBodyData)
            obj.clearAllGrdObjData();
            
            for(i=1:length(obj.groundObjsToPlot))
                grdObj = obj.groundObjsToPlot(i);
                
                if(ismember(grdObj.centralBodyInfo, obj.bodiesToPlot) || grdObj.centralBodyInfo == viewInFrame.getOriginBody())
                    grdObjData = LaunchVehicleViewProfileGroundObjData(grdObj, celBodyData);
                    obj.markerGrdObjData(end+1) = grdObjData;
                    
                    for(j=1:length(evts))
                        evt = evts(j);
                        evtStateLogEntries = lvdStateLogEntries([lvdStateLogEntries.event] == evt);
                        
                        times = [];
                        rVectsGrdObj = [];
                        rVectsSc = [];
                        for(k=1:length(evtStateLogEntries))
                            entry = evtStateLogEntries(k);
                            scCartElem = entry.getCartesianElementSetRepresentation();
                            scCartElem = scCartElem.convertToFrame(viewInFrame);
                            
                            time = entry.time;
                            
                            elemSet = grdObj.getStateAtTime(time);
                            if(not(isempty(elemSet)))
                                elemSet = elemSet.convertToCartesianElementSet().convertToFrame(viewInFrame);
                                
                                times(end+1) = time;
                                rVectsGrdObj(:,end+1) = elemSet.rVect;
                                rVectsSc(:,end+1) = scCartElem.rVect;
                            end
                        end
                        
                        [times,ia,~] = unique(times);
                        rVectsGrdObj = rVectsGrdObj(:,ia);
                        rVectsSc = rVectsSc(:,ia);

                        switch(evt.plotMethod)
                            case EventPlottingMethodEnum.PlotContinuous
                                %nothing

                            case EventPlottingMethodEnum.SkipFirstState
                                times = times(2:end);
                                rVectsGrdObj = rVectsGrdObj(2:end,:);
                                rVectsSc = rVectsSc(2:end,:);
                                
                            case EventPlottingMethodEnum.DoNotPlot
                                times = [];
                                rVectsGrdObj = [];
                                rVectsSc = [];

                            otherwise
                                error('Unknown event plotting method: %s', EventPlottingMethodEnum.DoNotPlot.name);
                        end
                        
                        if(length(times) >= 2 && all(diff(times)>0))
                            grdObjData.addData(times, rVectsGrdObj, rVectsSc, viewInFrame, obj.showGrdObjLoS);
                        
                            if(obj.showGndTracks)
                                hold(dAxes,'on');
                                plot3(dAxes, rVectsGrdObj(1,:), rVectsGrdObj(2,:), rVectsGrdObj(3,:), 'Color',grdObj.grdTrkLineColor.color, 'LineStyle',grdObj.grdTrkLineSpec.linespec);
                                hold(dAxes,'off');
                            end
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
                       
            lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
            timeSliderCb = @(src,evt) timeSliderStateChanged(src,evt, lvdData, handles);
            set(handles.hDispAxesTimeSlider, 'StateChangedCallback', timeSliderCb); 
            
            handles.hDispAxesTimeSlider.StateChangedCallback(timeSlider, true);
        end
        
        function trajData = createTrajData(obj)
            trajData = LaunchVehicleViewProfileTrajectoryData();
            obj.markerTrajData = trajData;
        end
        
        function createCentralBodyData(obj, bodyInfo, hCBodySurfXForm, viewFrame)
            obj.centralBodyData = LaunchVehicleViewProfileCentralBodyData(bodyInfo, hCBodySurfXForm, viewFrame);
        end
        
        function bodyData = createBodyData(obj, bodyInfo, bodyPlotStyle, showSoI,meshEdgeAlpha)
            bodyData = LaunchVehicleViewProfileBodyData(bodyInfo, bodyPlotStyle, showSoI, meshEdgeAlpha);
            obj.markerBodyData(end+1) = bodyData;
        end
        
        function clearAllTrajData(obj)
            obj.markerTrajData = LaunchVehicleViewProfileTrajectoryData.empty(1,0);
        end
        
        function clearAllBodyData(obj)
            obj.markerBodyData = LaunchVehicleViewProfileBodyData.empty(1,0);
        end
        
        function clearAllBodyAxesData(obj)
            obj.markerTrajAxesData = LaunchVehicleViewProfileBodyAxesData.empty(1,0);
        end
        
        function clearAllGrdObjData(obj)
            obj.markerGrdObjData = LaunchVehicleViewProfileGroundObjData.empty(1,0);
        end
    end
end