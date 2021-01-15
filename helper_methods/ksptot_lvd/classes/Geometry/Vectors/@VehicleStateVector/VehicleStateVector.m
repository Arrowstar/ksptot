classdef VehicleStateVector < AbstractGeometricVector
    %VehicleStateVector Scales a vector by a constant
    %   Detailed explanation goes here
    
    properties        
        type(1,1) VehicleStateVectorTypeEnum = VehicleStateVectorTypeEnum.Velocity
        scaleFactor(1,1) double = 1;
        
        name(1,:) char
        lvdData LvdData
        
        %vector line
        lineColor(1,1) ColorSpecEnum = ColorSpecEnum.Black;
        lineSpec(1,1) LineSpecEnum = LineSpecEnum.DottedLine;
    end
    
    methods        
        function obj = VehicleStateVector(type, scaleFactor, name, lvdData)   
            obj.type = type;
            obj.scaleFactor = scaleFactor;
            obj.name = name;
            obj.lvdData = lvdData;
        end
        
        function vect = getVectorAtTime(obj, ~, vehElemSet, inFrame)
            vehElemSet = convertToFrame(vehElemSet, inFrame);
            
            switch obj.type
                case VehicleStateVectorTypeEnum.AngularMomentum
                    rVect = [vehElemSet.rVect];
                    vVect = [vehElemSet.vVect];
                    vect = cross(rVect, vVect);
                    
                case VehicleStateVectorTypeEnum.East
                    rVect = [vehElemSet.rVect];
                    vect = rotSEZVectToECEFCoords(rVect, repmat([0;1;0], [1 length(vehElemSet)]));
                    
                case VehicleStateVectorTypeEnum.North
                    rVect = [vehElemSet.rVect];
                    vect = rotSEZVectToECEFCoords(rVect, repmat([-1;0;0], [1 length(vehElemSet)]));
                    
                case VehicleStateVectorTypeEnum.Radial
                    vect = [vehElemSet.rVect];
                    
                case VehicleStateVectorTypeEnum.Velocity
                    vect = [vehElemSet.vVect];
                    
                otherwise
                    error('Unknown vehicle state vector type: %s', string(obj.type));
            end
            
            vect = vect * obj.scaleFactor;
        end
        
        function name = getName(obj)
            name = obj.name;
        end
        
        function setName(obj, name)
            obj.name = name;
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = sprintf('%s (%s)', obj.getName(), obj.type.name);
        end
        
        function useTf = openEditDialog(obj)
            useTf = lvd_EditVehicleStateVectorGUI(obj, obj.lvdData);
        end
        
        function tf = isVehDependent(~)
            tf = true;
        end
        
        function origin = getOriginPointInViewFrame(~, ~, vehElemSet, viewFrame)
            vehElemSet = vehElemSet.convertToFrame(viewFrame);
            origin = vehElemSet.rVect;
        end
        
        function tf = usesGeometricPoint(~, ~)
            tf = false;
        end
        
        function tf = usesGeometricVector(~, ~)
            tf = false;
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