classdef UnitVector < AbstractGeometricVector
    %UnitVector Output is the input vector scaled to unit length.
    %   A zero-length input yields the zero vector rather than NaN so that
    %   downstream angle/projection consumers see a finite value.
    
    properties
        vector(1,1) AbstractGeometricVector
        
        name(1,:) char
        lvdData LvdData
        
        %vector line
        lineColor(1,1) ColorSpecEnum = ColorSpecEnum.Black;
        lineSpec(1,1) LineSpecEnum = LineSpecEnum.DottedLine;
    end
    
    methods        
        function obj = UnitVector(vector, name, lvdData) 
            obj.vector = vector;
            
            obj.name = name;
            obj.lvdData = lvdData;
        end
        
        function vect = getVectorAtTime(obj, time, vehElemSet, inFrame)
            vect = obj.vector.getVectorAtTime(time, vehElemSet, inFrame);
            
            norms = vecNormARH(vect);
            norms(norms == 0) = 1; %a zero vector divided by 1 stays zero rather than becoming NaN
            vect = bsxfun(@rdivide, vect, norms);
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function setName(obj, name)
            obj.name = name;
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('%s (Unit Vector of "%s")', obj.getName(), obj.vector.getName());
        end
        
        function useTf = openEditDialog(obj)            
            output = AppDesignerGUIOutput({false});
            lvd_EditUnitVectorGUI_App(obj, obj.lvdData, output);
            useTf = output.output{1};
        end
        
        function tf = isVehDependent(obj)
            tf = obj.vector.isVehDependent();
        end
        
        function origin = getOriginPointInViewFrame(obj, time, vehElemSet, viewFrame)
            origin = obj.vector.getOriginPointInViewFrame(time, vehElemSet, viewFrame);
        end
        
        function tf = usesGroundObj(obj, groundObj)
            tf = obj.vector.usesGroundObj(groundObj);
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
        
        function tf = usesGeometricAngle(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricPlane(~, ~)
            tf = false;
        end 
        
        function tf = isInUse(obj, lvdData)
            tf = lvdData.usesGeometricVector(obj);
        end
    end
end
