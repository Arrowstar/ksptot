classdef ScaledVector < AbstractGeometricVector
    %ScaledVector Scales a vector by a constant
    %   Detailed explanation goes here
    
    properties
        vector(1,1) AbstractGeometricVector
        scaleFactor(1,1) double = 1;
        
        name(1,:) char
        lvdData LvdData
        
        %vector line
        lineColor(1,1) ColorSpecEnum = ColorSpecEnum.Black;
        lineSpec(1,1) LineSpecEnum = LineSpecEnum.DottedLine;
    end
    
    methods        
        function obj = ScaledVector(vector, scaleFactor, name, lvdData) 
            obj.vector = vector;
            obj.scaleFactor = scaleFactor;
            
            obj.name = name;
            obj.lvdData = lvdData;
        end
        
        function vect = getVectorAtTime(obj, time, vehElemSet, inFrame)
            vect = obj.scaleFactor * obj.vector.getVectorAtTime(time, vehElemSet, inFrame);
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function setName(obj, name)
            obj.name = name;
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('%s ("%s" scaled by %0.3f)', obj.getName(), obj.vector.getName(), obj.scaleFactor);
        end
        
        function useTf = openEditDialog(obj)
            useTf = lvd_EditScaledVectorGUI(obj, obj.lvdData);
        end
        
        function tf = isVehDependent(obj)
            tf = obj.vector.isVehDependent();
        end
        
        function origin = getOriginPointInViewFrame(obj, time, vehElemSet, viewFrame)
            origin = obj.vector.getOriginPointInViewFrame(time, vehElemSet, viewFrame);
        end
        
        function tf = usesGeometricPoint(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricVector(obj, vector)
            tf = obj.vector == vector;
        end
        
        function tf = usesGeometricCoordSys(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricRefFrame(~, ~)
            tf = false;
        end
        
        function tf = isInUse(obj, lvdData)
            tf = lvdData.geometry.usesGeometricVector(obj);
        end
    end
end