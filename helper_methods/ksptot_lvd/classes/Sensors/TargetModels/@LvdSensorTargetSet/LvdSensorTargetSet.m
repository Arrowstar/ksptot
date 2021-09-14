classdef LvdSensorTargetSet < matlab.mixin.SetGet
    %LvdSensorTargetSet Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        targets(1,:) AbstractSensorTarget
        
        lvdData LvdData
    end
    
    methods
        function obj = LvdSensorTargetSet(lvdData)
            obj.lvdData = lvdData;
        end
        
        function addTarget(obj, target)
            obj.targets(end+1) = target;
        end
        
        function removeTarget(obj, target)
            obj.targets([obj.targets] == target) = [];
        end
        
        function [listBoxStr, targets] = getListboxStr(obj)
            listBoxStr = {};
            
            for(i=1:length(obj.targets))
                listBoxStr{end+1} = obj.targets(i).getListboxStr(); %#ok<AGROW>
            end
            
            targets = obj.targets;
        end
        
        function indPoints = getTargetsForInds(obj, inds)
            indPoints = obj.targets(inds);
        end
        
        function inds = getIndsForTarget(obj, indTarget)
            inds = [];
            for(i=1:length(indTarget))
                for(j=1:length(obj.targets))
                    if(indTarget(i) == obj.targets(j))
                        inds(end+1) = j; %#ok<AGROW>
                        break;
                    end
                end
            end
        end
        
        function indSensor = getPointAtInd(obj, ind)
            if(ind > 0 && ind <= length(obj.targets))
                indSensor = obj.targets(ind);
            else
                indSensor = AbstractSensor.empty(1,0);
            end
        end
        
        function tf = usesGroundObj(obj, groundObj)
            tf = false;
            for(i=1:length(obj.targets))
                tf = tf || obj.targets(i).usesGroundObj(groundObj);
            end
        end
        
        function tf = usesGeometricPoint(obj, point)
            tf = false;
            for(i=1:length(obj.targets))
                tf = tf || obj.targets(i).usesGeometricPoint(point);
            end
        end
        
        function tf = usesGeometricVector(obj, vector)
            tf = false;
            for(i=1:length(obj.targets))
                tf = tf || obj.targets(i).usesGeometricVector(vector);
            end
        end
        
        function tf = usesGeometricCoordSys(obj, coordSys)
            tf = false;
            for(i=1:length(obj.targets))
                tf = tf || obj.targets(i).usesGeometricCoordSys(coordSys);
            end
        end
        
        function tf = usesGeometricRefFrame(obj, refFrame)
            tf = false;
            for(i=1:length(obj.targets))
                tf = tf || obj.targets(i).usesGeometricRefFrame(refFrame);
            end
        end
        
        function tf = usesGeometricAngle(obj, angle)
            tf = false;
            for(i=1:length(obj.targets))
                tf = tf || obj.targets(i).usesGeometricAngle(angle);
            end
        end
        
        function tf = usesGeometricPlane(obj, plane)
            tf = false;
            for(i=1:length(obj.targets))
                tf = tf || obj.targets(i).usesGeometricPlane(plane);
            end
        end
    end
end