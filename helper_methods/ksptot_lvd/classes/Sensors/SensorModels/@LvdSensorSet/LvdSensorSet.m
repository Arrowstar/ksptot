classdef LvdSensorSet < matlab.mixin.SetGet
    %LvdSensorSet Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        sensors(1,:) AbstractSensor
        
        lvdData LvdData
    end
    
    methods
        function obj = LvdSensorSet(lvdData)
            obj.lvdData = lvdData;
        end
        
        function addSensor(obj, sensor)
            obj.sensors(end+1) = sensor;
        end
        
        function removeSensor(obj, sensor)
            obj.sensors([obj.sensors] == sensor) = [];
        end
        
        function [listBoxStr, sensors] = getListboxStr(obj)
            listBoxStr = {};
            
            for(i=1:length(obj.sensors))
                listBoxStr{end+1} = obj.sensors(i).getListboxStr(); %#ok<AGROW>
            end
            
            sensors = obj.sensors;
        end
        
        function indPoints = getSensorsForInds(obj, inds)
            indPoints = obj.sensors(inds);
        end
        
        function inds = getIndsForSensors(obj, indSensors)
            inds = [];
            for(i=1:length(indSensors))
                for(j=1:length(obj.sensors))
                    if(indSensors(i) == obj.sensors(j))
                        inds(end+1) = j; %#ok<AGROW>
                        break;
                    end
                end
            end
        end
        
        function indSensor = getPointAtInd(obj, ind)
            if(ind > 0 && ind <= length(obj.sensors))
                indSensor = obj.sensors(ind);
            else
                indSensor = AbstractSensor.empty(1,0);
            end
        end
        
        function tf = usesGroundObj(obj, groundObj)
            tf = false;
            for(i=1:length(obj.sensors))
                tf = tf || obj.sensors(i).usesGroundObj(groundObj);
            end
        end
        
        function tf = usesGeometricPoint(obj, point)
            tf = false;
            for(i=1:length(obj.sensors))
                tf = tf || obj.sensors(i).usesGeometricPoint(point);
            end
        end
        
        function tf = usesGeometricVector(obj, vector)
            tf = false;
            for(i=1:length(obj.sensors))
                tf = tf || obj.sensors(i).usesGeometricVector(vector);
            end
        end
        
        function tf = usesGeometricCoordSys(obj, coordSys)
            tf = false;
            for(i=1:length(obj.sensors))
                tf = tf || obj.sensors(i).usesGeometricCoordSys(coordSys);
            end
        end
        
        function tf = usesGeometricRefFrame(obj, refFrame)
            tf = false;
            for(i=1:length(obj.sensors))
                tf = tf || obj.sensors(i).usesGeometricRefFrame(refFrame);
            end
        end
        
        function tf = usesGeometricAngle(obj, angle)
            tf = false;
            for(i=1:length(obj.sensors))
                tf = tf || obj.sensors(i).usesGeometricAngle(angle);
            end
        end
        
        function tf = usesGeometricPlane(obj, plane)
            tf = false;
            for(i=1:length(obj.sensors))
                tf = tf || obj.sensors(i).usesGeometricPlane(plane);
            end
        end
    end
end