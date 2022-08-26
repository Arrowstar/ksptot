classdef GeometricPlaneSet < matlab.mixin.SetGet
    %GeometricPlaneSet Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        planes(1,:) AbstractGeometricPlane
        
        lvdData LvdData
    end
    
    methods        
        function obj = GeometricPlaneSet(lvdData)
            obj.lvdData = lvdData;
        end
        
        function addPlane(obj, plane)
            obj.planes(end+1) = plane;
        end
        
        function removePlane(obj, plane)
            obj.planes([obj.planes] == plane) = [];
        end
        
        function [listBoxStr, planes] = getListboxStr(obj)
            listBoxStr = {};
            
            for(i=1:length(obj.planes))
                listBoxStr{end+1} = obj.planes(i).getListboxStr(); %#ok<AGROW>
            end
            
            planes = obj.planes;
        end
        
        function indPlanes = getPlanesForInds(obj, inds)
            indPlanes = obj.planes(inds);
        end
        
        function inds = getIndsForPlanes(obj, indPlanes)
            inds = find(ismember(obj.planes, indPlanes));
        end
        
        function indPlane = getPlaneAtInd(obj, ind)
            if(ind > 0 && ind <= length(obj.planes))
                indPlane = obj.planes(ind);
            else
                indPlane = AbstractGeometricPlane.empty(1,0);
            end
        end
        
        function numPlanes = getNumPlanes(obj)
            numPlanes = length(obj.planes);
        end
        
        function tf = usesGroundObj(obj, groundObj)
            tf = false;
            for(i=1:length(obj.planes))
                tf = tf || obj.planes(i).usesGroundObj(groundObj);
            end
        end
        
        function tf = usesGeometricPoint(obj, point)
            tf = false;
            for(i=1:length(obj.planes))
                tf = tf || obj.planes(i).usesGeometricPoint(point);
            end
        end
        
        function tf = usesGeometricVector(obj, vector)
            tf = false;
            for(i=1:length(obj.planes))
                tf = tf || obj.planes(i).usesGeometricVector(vector);
            end
        end
        
        function tf = usesGeometricCoordSys(obj, coordSys)
            tf = false;
            for(i=1:length(obj.planes))
                tf = tf || obj.planes(i).usesGeometricCoordSys(coordSys);
            end
        end
        
        function tf = usesGeometricRefFrame(obj, refFrame)
            tf = false;
            for(i=1:length(obj.planes))
                tf = tf || obj.planes(i).usesGeometricRefFrame(refFrame);
            end
        end
        
        function tf = usesGeometricAngle(obj, angle)
            tf = false;
            for(i=1:length(obj.planes))
                tf = tf || obj.planes(i).usesGeometricAngle(angle);
            end
        end
        
        function tf = usesGeometricPlane(obj, plane)
            tf = false;
            for(i=1:length(obj.planes))
                tf = tf || obj.planes(i).usesGeometricPlane(plane);
            end
        end
        
        %%% Graphical Analysis Task String methods %%%
        function gAStr = getAllPlaneGraphAnalysisTaskStrs(obj)
            gAStr = horzcat(obj.getPlaneNormalXComponentGraphAnalysisTaskStrs(), ...
                            obj.getPlaneNormalYComponentGraphAnalysisTaskStrs(), ...
                            obj.getPlaneNormalZComponentGraphAnalysisTaskStrs());
        end

        function [gAStr, planes] = getPlaneNormalXComponentGraphAnalysisTaskStrs(obj)
            planes = obj.planes;
            
            gAStr = cell(1,length(planes));
            A = length(planes);
            formSpec = sprintf('%%0%uu',floor(log10(abs(A)+1)) + 1);
            for(i=1:length(planes))
                gAStr{i} = sprintf(sprintf('Plane %s Normal Vector X Component - "%s"',formSpec, planes(i).getName()), i);
            end
        end
        
        function [gAStr, planes] = getPlaneNormalYComponentGraphAnalysisTaskStrs(obj)
            planes = obj.planes;
            
            gAStr = cell(1,length(planes));
            A = length(planes);
            formSpec = sprintf('%%0%uu',floor(log10(abs(A)+1)) + 1);
            for(i=1:length(planes))
                gAStr{i} = sprintf(sprintf('Plane %s Normal Vector Y Component - "%s"',formSpec, planes(i).getName()), i);
            end
        end
        
        function [gAStr, planes] = getPlaneNormalZComponentGraphAnalysisTaskStrs(obj)
            planes = obj.planes;
            
            gAStr = cell(1,length(planes));
            A = length(planes);
            formSpec = sprintf('%%0%uu',floor(log10(abs(A)+1)) + 1);
            for(i=1:length(planes))
                gAStr{i} = sprintf(sprintf('Plane %s Normal Vector Z Component - "%s"',formSpec, planes(i).getName()), i);
            end
        end
    end
end