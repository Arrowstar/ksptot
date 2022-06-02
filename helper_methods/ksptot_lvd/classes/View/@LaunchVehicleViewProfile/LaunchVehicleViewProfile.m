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
        trajEvtsViewType(1,1) ViewEventsTypeEnum = ViewEventsTypeEnum.All %either chunked by event/SoI or all
        frame AbstractReferenceFrame
        projType ViewProjectionTypeEnum = ViewProjectionTypeEnum.Perspective;
        
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

        %geometric points
        pointsToPlot(1,:) AbstractGeometricPoint
        
        %geometric vectors
        vectorsToPlot(1,:) AbstractGeometricVector
        
        %geometric reference frames
        refFramesToPlot(1,:) AbstractGeometricRefFrame
        
        %geometric angles
        anglesToPlot(1,:) AbstractGeometricAngle
        
        %geometric planes
        planesToPlot(1,:) AbstractGeometricPlane
        
        %sensors
        sensorsToPlot(1,:) AbstractSensor
        
        %sensor targets
        sensorTgtsToPlot(1,:) AbstractSensorTarget
        
        %central body transform
        hCBodySurfXForm = []; %matlab.graphics.GraphicsPlaceholder()
        
        %view properties (set by user indirectly through UI controls)
        updateViewAxesLimits(1,1) logical = false;
        orbitNumToPlot(1,1) double = 1;
        viewAzEl(1,2) = [-37.5, 30]; %view(3)
        viewZoomAxLims(3,2) double = NaN(3,2);
        viewCameraPosition(1,3) double = NaN(1,3);
        viewCameraTarget(1,3) double = NaN(1,3);
        viewCameraUpVector(1,3) double = NaN(1,3);
        viewCameraViewAngle(1,1) double = NaN(1,1);
    end
    
    properties(Transient)
        markerTrajData(1,:) LaunchVehicleViewProfileTrajectoryData = LaunchVehicleViewProfileTrajectoryData.empty(1,0);
        markerBodyData(1,:) LaunchVehicleViewProfileBodyData = LaunchVehicleViewProfileBodyData.empty(1,0);
        markerTrajAxesData(1,:) LaunchVehicleViewProfileBodyAxesData = LaunchVehicleViewProfileBodyAxesData.empty(1,0);
        markerGrdObjData(1,:) LaunchVehicleViewProfileGroundObjData = LaunchVehicleViewProfileGroundObjData.empty(1,0);
        sunLighting(1,:) LaunchVehicleViewProfileSunLighting = LaunchVehicleViewProfileSunLighting.empty(1,0);
        centralBodyData(1,:) LaunchVehicleViewProfileCentralBodyData = LaunchVehicleViewProfileCentralBodyData.empty(1,0);
        
        pointData(1,:) LaunchVehicleViewProfilePointData = LaunchVehicleViewProfilePointData.empty(1,0);
        vectorData(1,:) LaunchVehicleViewProfileVectorData = LaunchVehicleViewProfileVectorData.empty(1,0);
        refFrameData(1,:) LaunchVehicleViewProfileRefFrameData = LaunchVehicleViewProfileRefFrameData.empty(1,0);
        angleData(1,:) LaunchVehicleViewProfileAngleData = LaunchVehicleViewProfileAngleData.empty(1,0);
        planeData(1,:) LaunchVehicleViewProfilePlaneData = LaunchVehicleViewProfilePlaneData.empty(1,0);
        
        sensorData(1,:) LaunchVehicleViewProfileSensorData = LaunchVehicleViewProfileSensorData.empty(1,0);
        sensorTgtData(1,:) LaunchVehicleViewProfileSensorTargetData = LaunchVehicleViewProfileSensorTargetData.empty(1,0);
        
        userDefinedRefFrames(1,:) 
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
        
        function removeGeoPointFromList(obj, point)
            obj.pointsToPlot([obj.pointsToPlot] == point) = [];
        end
        
        function removeGeoVectorFromList(obj, vector)
            obj.vectorsToPlot([obj.vectorsToPlot] == vector) = [];
        end
        
        function removeGeoRefFrameFromList(obj, refFrame)
            obj.refFramesToPlot([obj.refFramesToPlot] == refFrame) = [];
        end
        
        function removeGeoAngleFromList(obj, angle)
            obj.anglesToPlot([obj.anglesToPlot] == angle) = [];
        end
        
        function removeGeoPlaneFromList(obj, plane)
            obj.planesToPlot([obj.planesToPlot] == plane) = [];
        end
        
        function removeSensorFromList(obj, sensor)
            obj.sensorsToPlot([obj.sensorsToPlot] == sensor) = [];
        end
        
        function removeSensorTargetFromList(obj, target)
            obj.sensorTgtsToPlot([obj.sensorTgtsToPlot] == target) = [];
        end
        
        function plotTrajectory(obj, lvdData, handles, app)
            obj.generic3DTrajView.plotStateLog(obj.orbitNumToPlot, lvdData, obj, handles, app);
        end
        
        function createTrajectoryMarkerData(obj, subStateLogs, evts)
            obj.clearAllTrajData();
            trajMarkerData = obj.createTrajData();
            
            for(j=1:length(subStateLogs)) %#ok<*NO4LP> 
                if(size(subStateLogs{j},1) > 0)
                    [times, rVects, evtColor] = LaunchVehicleViewProfile.parseTrajDataFromSubStateLogs(subStateLogs, j, evts);
                    
                    if(length(unique(times)) > 0)
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
            
            for(i=1:length(obj.bodiesToPlot))
                bodyToPlot = obj.bodiesToPlot(i); 
                
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
                
                bodyMarkerData = obj.createBodyData(bodyToPlot, viewInFrame, obj.bodyPlotStyle, showSoI, meshEdgeAlpha);
                
                times = [];
                for(j=1:length(subStateLogs)) %#ok<NO4LP> 
                    if(size(subStateLogs{j},1) > 0)
                        times = [times; subStateLogs{j}(:,1)]; %#ok<AGROW>
                    end
                end
                
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

                if(doConversion)
                    states = convertToFrame(states, viewInFrame);
                end

                rVects = [states.rVect];

                [times,ia,~] = unique(times,'stable');
                rVects = rVects(:,ia);

                [times,I] = sort(times);
                rVects = rVects(:,I);

                timesInner = times; 
                rVectsInner = rVects; 
                
                timesArr{i} = timesInner; %#ok<AGROW>
                rVectArr{i} = rVectsInner; %#ok<AGROW>
                
                bodyColorsArr{i} = bColorRGB; %#ok<AGROW>
                bodyMarkerDataObjs{i} = bodyMarkerData; %#ok<AGROW>
            end
            
            for(i=1:length(timesArr))
                timesInner = timesArr{i};
                rVectsInner = rVectArr{i};
                bColorRGB = bodyColorsArr{i};
                bodyMarkerData = bodyMarkerDataObjs{i};
                
                if(not(isempty(timesInner)))
                    obj.markerBodyData(end+1) = bodyMarkerData;
                    
                    times = timesInner;
                    rVects = rVectsInner;

                    if(length(unique(times)) > 1)
                        plot3(dAxes, rVects(1,:), rVects(2,:), rVects(3,:), '-', 'Color',bColorRGB, 'LineWidth',1.5);
                        bodyMarkerData.addData(times, rVects);
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
        
        function createBodyAxesData(obj, vehPosVelData, vehAttData) %lvdStateLogEntries, evts, viewInFrame
            obj.clearAllBodyAxesData();
            obj.markerTrajAxesData = LaunchVehicleViewProfileBodyAxesData(vehPosVelData, vehAttData, obj.scBodyAxesScale, obj.showScBodyAxes);
            
%             if(obj.showScBodyAxes)
%                 for(i=1:length(evts))
%                     evt = evts(i);
%                     evtStateLogEntries = lvdStateLogEntries([lvdStateLogEntries.event] == evt);
%                     evtStateLogEntries = evtStateLogEntries(:)';           
%                     
%                     cartElem = convertToFrame(getCartesianElementSetRepresentation(evtStateLogEntries), viewInFrame);
%                     
%                     times = [evtStateLogEntries.time];
% 
%                     rVects = [cartElem.rVect];
%                     rotMatsBodyToView = NaN(3, 3, length(evtStateLogEntries));
%                     for(j=1:length(evtStateLogEntries))
%                         %get body position in view frame
%                         entry = evtStateLogEntries(j);
% 
%                         %get body axes in view frame
%                         rotMatBodyToInertial = entry.steeringModel.getBody2InertialDcmAtTime(entry.time, entry.position, entry.velocity, entry.centralBody);
% 
%                         [~, ~, ~, rotMatToInertial12] = viewInFrame.getOffsetsWrtInertialOrigin(entry.time, cartElem(j));
%                         [~, ~, ~, rotMatToInertial32] = entry.centralBody.getBodyCenteredInertialFrame().getOffsetsWrtInertialOrigin(entry.time, cartElem(j));
% 
%                         rotMatsBodyToView(:,:,j) = rotMatToInertial12' * rotMatToInertial32 * rotMatBodyToInertial; %body to inertial -> inertial to inertial -> inertial to view frame
%                     end
% 
%                     [times,ia,~] = unique(times,'stable');
%                     rVects = rVects(:,ia);
%                     rotMatsBodyToView = rotMatsBodyToView(:,:,ia);
% 
%                     [times,I] = sort(times);
%                     rVects = rVects(:,I);
%                     rotMatsBodyToView = rotMatsBodyToView(:,:,I);
%                     
%                     switch(evt.plotMethod)
%                         case EventPlottingMethodEnum.PlotContinuous
%                             %nothing
% 
%                         case EventPlottingMethodEnum.SkipFirstState
%                             times = times(2:end);
%                             rVects = rVects(:,2:end);
%                             rotMatsBodyToView = rotMatsBodyToView(:,:,2:end);
% 
%                         case EventPlottingMethodEnum.DoNotPlot
%                             times = [];
%                             rVects = [];
%                             rotMatsBodyToView = [];
% 
%                         otherwise
%                             error('Unknown event plotting method: %s', EventPlottingMethodEnum.DoNotPlot.name);
%                     end
% 
%                     if(length(times) >= 2 && all(diff(times)>0))
%                         obj.markerTrajAxesData.addData(times, rVects, rotMatsBodyToView);
%                     end
%                 end
%             end
        end
        
        function createGroundObjMarkerData(obj, dAxes, lvdStateLogEntries, vehPosVelData, evts, viewInFrame, celBodyData)
            obj.clearAllGrdObjData();
            
            for(i=1:length(obj.groundObjsToPlot))
                grdObj = obj.groundObjsToPlot(i);
                
                if(ismember(grdObj.centralBodyInfo, obj.bodiesToPlot) || grdObj.centralBodyInfo == viewInFrame.getOriginBody())
                    grdObjData = LaunchVehicleViewProfileGroundObjData(grdObj, vehPosVelData, celBodyData);
                    obj.markerGrdObjData(end+1) = grdObjData;
                    
                    for(j=1:length(evts))
                        evt = evts(j);
                        evtStateLogEntries = lvdStateLogEntries([lvdStateLogEntries.event] == evt);
                        numEntries = length(evtStateLogEntries);
                        
%                         scCartElem = convertToFrame(getCartesianElementSetRepresentation(evtStateLogEntries), viewInFrame);
                        allTimes = [evtStateLogEntries.time];
                        
                        elemSet = GeographicElementSet.empty(1,0);
                        
                        for(k=1:numEntries)                            
                            ge = grdObj.getStateAtTime(allTimes(k));
                            if(not(isempty(ge)))
                                elemSet(end+1) = ge; %#ok<AGROW>
                            end
                        end
                        elemSet = convertToFrame(convertToCartesianElementSet(elemSet), viewInFrame);

                        times = [elemSet.time];
                        rVectsGrdObj = [elemSet.rVect];
%                         rVectsSc= [scCartElem.rVect];
                        
                        [times,ia,~] = unique(times);
                        rVectsGrdObj = rVectsGrdObj(:,ia);
%                         rVectsSc = rVectsSc(:,ia);

                        switch(evt.plotMethod)
                            case EventPlottingMethodEnum.PlotContinuous
                                %nothing

                            case EventPlottingMethodEnum.SkipFirstState
                                times = times(2:end);
                                rVectsGrdObj = rVectsGrdObj(2:end,:);
%                                 rVectsSc = rVectsSc(2:end,:);
                                
                            case EventPlottingMethodEnum.DoNotPlot
                                times = [];
                                rVectsGrdObj = [];
%                                 rVectsSc = [];

                            otherwise
                                error('Unknown event plotting method: %s', EventPlottingMethodEnum.DoNotPlot.name);
                        end
                        
                        if(length(times) >= 2 && all(diff(times)>0))
                            grdObjData.addData(times, rVectsGrdObj, viewInFrame, obj.showGrdObjLoS);
                        
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
        
        function configureTimeSlider(obj, minTime, maxTime, subStateLogs, handles, app)
            timeSlider = app.DispAxesTimeSlider;
            curSliderTime = timeSlider.Value;
            if(not(isfinite(minTime) && isfinite(maxTime)) || ...
               minTime == maxTime)
                onlyTime = subStateLogs{1}(1,1);
                
                minTime = onlyTime;
                maxTime = onlyTime + 1;
            end
            timeSlider.Limits = [minTime maxTime];
            timeSlider.MajorTicks = linspace(minTime, maxTime, 10);
            timeSlider.MinorTicks = linspace(minTime, maxTime, 100);
            timeSlider.MajorTickLabels = "";
            
            if(curSliderTime > maxTime)
                timeSlider.Value = maxTime;
            elseif(curSliderTime < minTime)
                timeSlider.Value = minTime;
            end
                       
            lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
            timeSliderCb = @(src,evt) timeSliderStateChanged(src,evt, lvdData, handles, app);
            timeSlider.ValueChangingFcn = timeSliderCb; 
            
            timeSlider.ValueChangingFcn(timeSlider, true);
        end
        
        function trajData = createTrajData(obj)
            trajData = LaunchVehicleViewProfileTrajectoryData();
            obj.markerTrajData = trajData;
        end
        
        function createCentralBodyData(obj, bodyInfo, hCBodySurfXForm, viewFrame)
            obj.centralBodyData = LaunchVehicleViewProfileCentralBodyData(bodyInfo, hCBodySurfXForm, viewFrame);
        end
        
        function bodyData = createBodyData(obj, bodyInfo, viewInFrame, bodyPlotStyle, showSoI,meshEdgeAlpha)
            bodyData = LaunchVehicleViewProfileBodyData(bodyInfo, viewInFrame, bodyPlotStyle, showSoI, meshEdgeAlpha);
            obj.markerBodyData(end+1) = bodyData;
       end
        
        function createPointData(obj, viewFrame, subStateLogs, evts)
            obj.clearPointData();
            points = obj.pointsToPlot;
            
            for(i=1:length(points))
                obj.pointData(end+1) = LaunchVehicleViewProfilePointData(points(i), viewFrame);
            end
            
            for(i=1:length(subStateLogs))
                if(size(subStateLogs{i},1) > 0)
                    [times, rVects, ~, vVects] = LaunchVehicleViewProfile.parseTrajDataFromSubStateLogs(subStateLogs, i, evts);
                    
                    if(length(unique(times)) > 1)
                        for(j=1:length(obj.pointData))
                            obj.pointData(j).addData(times, rVects, vVects);
                        end
                    end
                end
            end
        end
        
        function createVectorData(obj, viewFrame, subStateLogs, evts)
            obj.clearVectorData();
            vectors = obj.vectorsToPlot;
            
            for(i=1:length(vectors))
                obj.vectorData(end+1) = LaunchVehicleViewProfileVectorData(vectors(i), viewFrame);
            end
            
            for(i=1:length(subStateLogs))
                if(size(subStateLogs{i},1) > 0)
                    [times, rVects, ~, vVects] = LaunchVehicleViewProfile.parseTrajDataFromSubStateLogs(subStateLogs, i, evts);
                    
                    if(length(unique(times)) > 1)
                        for(j=1:length(obj.vectorData))
                            obj.vectorData(j).addData(times, rVects, vVects);
                        end
                    end
                end
            end
        end
        
        function createRefFrameData(obj, viewFrame, subStateLogs, evts)
            obj.clearRefFrameData();
            refFrames = obj.refFramesToPlot;
            
            for(i=1:length(refFrames))
                obj.refFrameData(end+1) = LaunchVehicleViewProfileRefFrameData(refFrames(i), viewFrame);
            end
            
            for(i=1:length(subStateLogs))
                if(size(subStateLogs{i},1) > 0)
                    [times, rVects, ~, vVects] = LaunchVehicleViewProfile.parseTrajDataFromSubStateLogs(subStateLogs, i, evts);
                    
                    if(length(unique(times)) > 1)
                        for(j=1:length(obj.refFrameData))
                            obj.refFrameData(j).addData(times, rVects, vVects);
                        end
                    end
                end
            end
        end
        
        function createAngleData(obj, viewFrame, subStateLogs, evts)
            obj.clearAngleData();
            angles = obj.anglesToPlot;
            
            for(i=1:length(angles))
                obj.angleData(end+1) = LaunchVehicleViewProfileAngleData(angles(i), viewFrame);
            end
            
            for(i=1:length(subStateLogs))
                if(size(subStateLogs{i},1) > 0)
                    [times, rVects, ~, vVects] = LaunchVehicleViewProfile.parseTrajDataFromSubStateLogs(subStateLogs, i, evts);
                    
                    if(length(unique(times)) > 1)
                        for(j=1:length(obj.angleData))
                            obj.angleData(j).addData(times, rVects, vVects);
                        end
                    end
                end
            end
        end
        
        function createPlaneData(obj, viewFrame, subStateLogs, evts)
            obj.clearPlaneData();
            planes = obj.planesToPlot;
            
            for(i=1:length(planes))
                obj.planeData(end+1) = LaunchVehicleViewProfilePlaneData(planes(i), viewFrame);
            end
            
            for(i=1:length(subStateLogs))
                if(size(subStateLogs{i},1) > 0)
                    [times, rVects, ~, vVects] = LaunchVehicleViewProfile.parseTrajDataFromSubStateLogs(subStateLogs, i, evts);
                    
                    if(length(unique(times)) > 1)
                        for(j=1:length(obj.planeData))
                            obj.planeData(j).addData(times, rVects, vVects);
                        end
                    end
                end
            end
        end
        
        function createSensorData(obj, lvdStateLogEntries, vehPosVelData, vehAttData, viewFrame)
            obj.clearSensorData();
            
            for(i=1:length(obj.sensorsToPlot))
                sensor = obj.sensorsToPlot(i);
                obj.sensorData(i) = LaunchVehicleViewProfileSensorData(sensor, obj.sensorTgtsToPlot, lvdStateLogEntries, vehPosVelData, vehAttData, viewFrame);
            end
        end
        
        function createSensorTargetData(obj, viewFrame)
            obj.clearSensorTgtData();

            for(i=1:length(obj.sensorTgtsToPlot))
                target = obj.sensorTgtsToPlot(i);
                obj.sensorTgtData(i) = LaunchVehicleViewProfileSensorTargetData(target, viewFrame);
            end
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
        
        function clearPointData(obj)
            obj.pointData = LaunchVehicleViewProfilePointData.empty(1,0);
        end
        
        function clearVectorData(obj)
            obj.vectorData = LaunchVehicleViewProfileVectorData.empty(1,0);
        end
        
        function clearRefFrameData(obj)
            obj.refFrameData = LaunchVehicleViewProfileRefFrameData.empty(1,0);
        end
        
        function clearAngleData(obj)
            obj.angleData = LaunchVehicleViewProfileAngleData.empty(1,0);
        end
        
        function clearPlaneData(obj)
            obj.planeData = LaunchVehicleViewProfilePlaneData.empty(1,0);
        end
        
        function clearSensorData(obj)
            obj.sensorData = LaunchVehicleViewProfileSensorData.empty(1,0);
        end

        function clearSensorTgtData(obj)
            obj.sensorTgtData = LaunchVehicleViewProfileSensorTargetData.empty(1,0);
        end
        
        
    end
    
    methods(Static)
        function vehPosVelData = createVehPosVelData(subStateLogs, evts, viewFrame)
            vehPosVelData = LaunchVehicleViewPosVelInterp(viewFrame);
                        
            for(i=1:length(subStateLogs))
                if(size(subStateLogs{i},1) > 0)
                    [times, rVects, ~, vVects] = LaunchVehicleViewProfile.parseTrajDataFromSubStateLogs(subStateLogs, i, evts);
                    
                    if(length(unique(times)) > 1)
                        vehPosVelData.addData(times, rVects, vVects);
                    end
                end
            end
        end
        
        function vehAttData = createVehAttitudeData(vehPosVelData, lvdStateLogEntries, evts, viewInFrame)
            vehAttData = LaunchVehicleViewProfileAttitudeData();            
            
            for(i=1:length(evts))
                evt = evts(i);
                bool = [lvdStateLogEntries.event] == evt;
                evtStateLogEntries = lvdStateLogEntries(bool);
                evtStateLogEntries = evtStateLogEntries(:)';
                
                if(isempty(evtStateLogEntries))
                    continue;
                end
                
                cartElem = convertToFrame(getCartesianElementSetRepresentation(evtStateLogEntries), viewInFrame);
                
                times = [evtStateLogEntries.time];
                
                rotMatsBodyToView = NaN(3, 3, length(evtStateLogEntries));
                for(j=1:length(evtStateLogEntries))
                    %get body position in view frame
                    entry = evtStateLogEntries(j);
                    
                    %get body axes in view frame
                    rotMatBodyToInertial = entry.steeringModel.getBody2InertialDcmAtTime(entry.time, entry.position, entry.velocity, entry.centralBody);
                    
                    [~, ~, ~, rotMatToInertial12] = viewInFrame.getOffsetsWrtInertialOrigin(entry.time, cartElem(j));
                    [~, ~, ~, rotMatToInertial32] = entry.centralBody.getBodyCenteredInertialFrame().getOffsetsWrtInertialOrigin(entry.time, cartElem(j));
                    
                    rotMatsBodyToView(:,:,j) = rotMatToInertial12' * rotMatToInertial32 * rotMatBodyToInertial; %body to inertial -> inertial to inertial -> inertial to view frame
                end
                                
                switch(evt.plotMethod)
                    case EventPlottingMethodEnum.PlotContinuous
                        %nothing
                        
                    case EventPlottingMethodEnum.SkipFirstState
                        times = times(2:end);
                        rotMatsBodyToView = rotMatsBodyToView(:,:,2:end);
                        
                    case EventPlottingMethodEnum.DoNotPlot
                        times = [];
                        rotMatsBodyToView = [];
                        
                    otherwise
                        error('Unknown event plotting method: %s', evt.plotMethod);
                end
                
                [times,ia,~] = unique(times,'stable');
                rotMatsBodyToView = rotMatsBodyToView(:,:,ia);
                
                [times,I] = sort(times);
                rotMatsBodyToView = rotMatsBodyToView(:,:,I);
                
                if(length(times) >= 2 && all(diff(times)>0))
                    vehAttData.addData(times, rotMatsBodyToView);
                end
            end
        end
    end
    
    methods(Static, Access=private)
        function [times, rVects, evtColor, vVects] = parseTrajDataFromSubStateLogs(subStateLogs, j, evts)
            times = subStateLogs{j}(:,1);
            rVects = subStateLogs{j}(:,2:4);
            vVects = subStateLogs{j}(:,5:7);

            evtNum = subStateLogs{j}(1,13);
            if(isempty(evtNum) || isnan(evtNum))
                times = [];
                rVects = [];
                evtColor = [];
                vVects = [];
                
                return;
            end
            evt = evts(evtNum);
            evtColor = evt.colorLineSpec.color;

            switch(evt.plotMethod)
                case EventPlottingMethodEnum.PlotContinuous
                    %nothing

                case EventPlottingMethodEnum.SkipFirstState
                    times = times(2:end);
                    rVects = rVects(2:end,:);
                    vVects = vVects(2:end,:);

                case EventPlottingMethodEnum.DoNotPlot
                    times = [];
                    rVects = [];
                    vVects = [];

                otherwise
                    error('Unknown event plotting method: %s', event.plotMethod);
            end

            if(not(isempty(times)))
                [times,ia,~] = unique(times,'stable','rows');
                rVects = rVects(ia,:);
                vVects = vVects(ia,:);

                [times,I] = sort(times);
                rVects = rVects(I,:);
                vVects = vVects(I,:);
            end
        end
    end
end