classdef LaunchVehicleViewProfileSensorData < matlab.mixin.SetGet
    %LaunchVehicleViewProfileSensorData Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        sensor AbstractSensor
        targets AbstractSensorTarget
        
        vehPosVelData LaunchVehicleViewPosVelInterp
        vehAttData LaunchVehicleViewProfileAttitudeData
        
        sensorMeshPlot = matlab.graphics.GraphicsPlaceholder.empty(1,0)
        viewFrame AbstractReferenceFrame
    end
    
    methods
        function obj = LaunchVehicleViewProfileSensorData(sensor, targets, vehPosVelData, vehAttData, viewFrame)
            obj.sensor = sensor;
            obj.targets = targets;
            obj.vehPosVelData = vehPosVelData;
            obj.vehAttData = vehAttData;
            obj.viewFrame = viewFrame;
        end
        
        function results = plotSensorAtTime(obj, time, hAx)
            results = SensorTargetResults.empty(1,0);
            
            [rVect, vVect] = obj.vehPosVelData.getPositionVelocityAtTime(time);
            if(width(rVect) > 0 && width(vVect) > 0)
                scElem = CartesianElementSet(time, rVect, vVect, obj.viewFrame);

                dcm = obj.vehAttData.getDCMatTime(time);

                bodyInfo = obj.viewFrame.getOriginBody();
                bodyInfos = [bodyInfo, bodyInfo.getParBodyInfo(), bodyInfo.getChildrenBodyInfo(bodyInfo.celBodyData)];

                [results, V, F] = obj.sensor.evaluateSensorTargets(obj.targets, scElem, dcm, bodyInfos, obj.viewFrame);
                
                if(isempty(obj.sensorMeshPlot))
                    hold(hAx,'on'); 
                    color = obj.sensor.getMeshColor().color;
                    alpha = obj.sensor.getMeshAlpha();
                    obj.sensorMeshPlot = drawMesh(hAx, V, F, 'FaceColor',color,'FaceAlpha',alpha, 'LineStyle','none');
                    hold(hAx,'off');
                else
                    obj.sensorMeshPlot.Vertices = V;
                    obj.sensorMeshPlot.Faces = F;
                end
            end
        end
    end
end