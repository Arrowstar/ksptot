classdef LaunchVehicleViewProfileSensorData < matlab.mixin.SetGet
    %LaunchVehicleViewProfileSensorData Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %Objects
        sensor AbstractSensor
        targets AbstractSensorTarget
        
        %Modeled vehicle position/vel/attitude
        vehPosVelData LaunchVehicleViewPosVelInterp
        vehAttData LaunchVehicleViewProfileAttitudeData
        
        %Sensor State Data
        timesArr cell
        sensorStateArr cell
        
        %display objects
        sensorMeshPlot(1,:) matlab.graphics.primitive.Patch = matlab.graphics.primitive.Patch.empty(1,0);
        viewFrame AbstractReferenceFrame
    end
    
    methods
        function obj = LaunchVehicleViewProfileSensorData(sensor, targets, lvdStateLogEntries, vehPosVelData, vehAttData, viewFrame)
            obj.sensor = sensor;
            obj.targets = targets;
            obj.vehPosVelData = vehPosVelData;
            obj.vehAttData = vehAttData;
            obj.viewFrame = viewFrame;
            
            obj.parseLvdStateData(lvdStateLogEntries);
        end
        
        function results = plotSensorAtTime(obj, time, hAx)
            results = SensorTargetResults.empty(1,0);
            
            [rVects, vVects] = obj.vehPosVelData.getPositionVelocityAtTime(time);
            dcms = obj.vehAttData.getDCMatTime(time);
            sensorStates = obj.getSensorStatesForTime(time);
            if(width(rVects) > 0 && size(dcms,3) > 0 && width(rVects) == size(dcms,3))                
                for(i=1:width(rVects))
                    rVect = rVects(:,i);
                    vVect = vVects(:,i);
                    dcm = dcms(:,:,i);
                    sensorState = sensorStates(i);
                    
                    scElem = CartesianElementSet(time, rVect, vVect, obj.viewFrame);
                    
                    bodyInfo = obj.viewFrame.getOriginBody();
                    bodyInfos = [bodyInfo, bodyInfo.getParBodyInfo(), bodyInfo.getChildrenBodyInfo(bodyInfo.celBodyData)];
                    
                    [results, V, F] = obj.sensor.evaluateSensorTargets(sensorState, obj.targets, scElem, dcm, bodyInfos, obj.viewFrame); %TODO Needs to handle multiple states
                    
                    if(numel(obj.sensorMeshPlot) < i || isempty(obj.sensorMeshPlot(i)))
                        hold(hAx,'on');
                        color = obj.sensor.getMeshColor().color;
                        alpha = obj.sensor.getMeshAlpha();
                        showMeshEdges = obj.sensor.getDisplayMeshEdges();
                        
                        if(showMeshEdges)
                            meshLineStyle = '-';
                        else
                            meshLineStyle = 'none';
                        end
                        
                        obj.sensorMeshPlot(i) = drawMesh(hAx, V, F, 'FaceColor',color,'FaceAlpha',alpha, 'LineStyle',meshLineStyle, 'EdgeAlpha',alpha);
                        hold(hAx,'off');
                    else
                        obj.sensorMeshPlot(i).Vertices = V;
                        obj.sensorMeshPlot(i).Faces = F;
                        obj.sensorMeshPlot(i).Visible = 'on';
                    end
                end
                
                if(numel(obj.sensorMeshPlot) > width(rVects))
                    for(i=width(rVects)+1 : length(obj.sensorMeshPlot))
                        if(not(isempty(obj.sensorMeshPlot(i))) && isvalid(obj.sensorMeshPlot(i)))
                            obj.sensorMeshPlot(i).Visible = 'off';
                        end
                    end
                end
            end
        end
    end
    
    methods(Access=private)
        function parseLvdStateData(obj, lvdStateLogEntries)
            obj.timesArr = {};
            obj.sensorStateArr = {};
            
            events = unique([lvdStateLogEntries.event],'stable');
            for(i=1:numel(events))
                event = events(i);
                eventLogEntries = lvdStateLogEntries([lvdStateLogEntries.event] == event);
                
                times = [eventLogEntries.time];
                
                sensorState = AbstractSensorState.empty(1,0);
                for(j=1:length(eventLogEntries))
                    sensorState(j) = eventLogEntries(j).getSensorStateForSensor(obj.sensor);
                end
                
                switch(event.plotMethod)
                    case EventPlottingMethodEnum.PlotContinuous
                        %nothing
                        
                    case EventPlottingMethodEnum.SkipFirstState
                        times = times(2:end);
                        sensorState = sensorState(2:end);
                        
                    case EventPlottingMethodEnum.DoNotPlot
                        times = [];
                        sensorState = [];
                        
                    otherwise
                        error('Unknown event plotting method: %s', event.plotMethod);
                end
                
                if(length(times) >= 2 && length(unique(times)) > 1)
                    obj.timesArr{end+1} = times;
                    obj.sensorStateArr{end+1} = sensorState;
                end
            end
        end
        
        function sensorStates = getSensorStatesForTime(obj, time)
            sensorStates = AbstractSensorState.empty(1,0);
            
            for(i=1:length(obj.timesArr))
                times = obj.timesArr{i};
                sensorStatesForTimes = obj.sensorStateArr{i};
                
                if(length(unique(times)) > 1)
                    if(time >= min(times) && time <= max(times))
                        [times,I] = sort(times);
                        sensorStatesForTimes = sensorStatesForTimes(I);

                        bool = time == times;
                        if(any(bool))
                            ind = find(bool, 1, 'last');
                        else
                            ind = find(time >= times, 1, 'last');
                        end

                        sensorStates(end+1) = sensorStatesForTimes(ind); %#ok<AGROW>
                    end
                end
            end
        end
    end
end