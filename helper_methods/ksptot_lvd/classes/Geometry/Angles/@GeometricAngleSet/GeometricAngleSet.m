classdef GeometricAngleSet < matlab.mixin.SetGet
    %GeometricAngleSet Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        angles(1,:) AbstractGeometricAngle
        
        lvdData LvdData
    end
    
    methods        
        function obj = GeometricAngleSet(lvdData)
            obj.lvdData = lvdData;
        end
        
        function addAngle(obj, angle)
            obj.angles(end+1) = angle;
        end
        
        function removeAngle(obj, angle)
            obj.angles([obj.angles] == angle) = [];
        end
        
        function [listBoxStr, angles] = getListboxStr(obj)
            listBoxStr = {};
            
            for(i=1:length(obj.angles))
                listBoxStr{end+1} = obj.angles(i).getListboxStr(); %#ok<AGROW>
            end
            
            angles = obj.angles;
        end
        
        function indAngles = getAnglesForInds(obj, inds)
            indAngles = obj.angles(inds);
        end
        
        function inds = getIndsForAngles(obj, indAngles)
            inds = find(ismember(obj.angles, indAngles));
        end
        
        function indAngle = getAngleAtInd(obj, ind)
            if(ind > 0 && ind <= length(obj.angles))
                indAngle = obj.angles(ind);
            else
                indAngle = AbstractGeometricAngle.empty(1,0);
            end
        end
        
        function numAngles = getNumAngles(obj)
            numAngles = length(obj.angles);
        end
        
        function tf = usesGroundObj(obj, groundObj)
            tf = false;
            for(i=1:length(obj.angles))
                tf = tf || obj.angles(i).usesGroundObj(groundObj);
            end
        end
        
        function tf = usesGeometricPoint(obj, point)
            tf = false;
            for(i=1:length(obj.angles))
                tf = tf || obj.angles(i).usesGeometricPoint(point);
            end
        end
        
        function tf = usesGeometricVector(obj, vector)
            tf = false;
            for(i=1:length(obj.angles))
                tf = tf || obj.angles(i).usesGeometricVector(vector);
            end
        end
        
        function tf = usesGeometricCoordSys(obj, coordSys)
            tf = false;
            for(i=1:length(obj.angles))
                tf = tf || obj.angles(i).usesGeometricCoordSys(coordSys);
            end
        end
        
        function tf = usesGeometricRefFrame(obj, refFrame)
            tf = false;
            for(i=1:length(obj.angles))
                tf = tf || obj.angles(i).usesGeometricRefFrame(refFrame);
            end
        end
        
        function tf = usesGeometricAngle(obj, angle)
            tf = false;
            for(i=1:length(obj.angles))
                tf = tf || obj.angles(i).usesGeometricAngle(angle);
            end
        end
        
        function tf = usesGeometricPlane(obj, plane)
            tf = false;
            for(i=1:length(obj.angles))
                tf = tf || obj.angles(i).usesGeometricPlane(plane);
            end
        end
        
        %%% Graphical Analysis Task String methods %%%
        function gAStr = getAllAngleGraphAnalysisTaskStrs(obj)
            gAStr = horzcat(obj.getAngleMagGraphAnalysisTaskStrs());
        end

        function [gAStr, angles] = getAngleMagGraphAnalysisTaskStrs(obj)
            angles = obj.angles;
            
            gAStr = cell(1,length(angles));
            A = length(angles);
            formSpec = sprintf('%%0%uu',floor(log10(abs(A)+1)) + 1);
            for(i=1:length(angles))
                gAStr{i} = sprintf(sprintf('Angle %s Magnitude - "%s"',formSpec, angles(i).getName()), i);
            end
        end
    end
end