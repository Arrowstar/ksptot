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
                    
                case VehicleStateVectorTypeEnum.AscNode
                    rVect = [vehElemSet.rVect];
                    vVect = [vehElemSet.vVect];
                    hVect = cross(rVect, vVect);
                    kHat = [zeros(2, size(hVect,2));
                            ones(1, size(hVect,2))];
                        
                    vehElemSetKep = convertToKeplerianElementSet(vehElemSet);
                    sma = [vehElemSetKep.sma];
                    ecc = [vehElemSetKep.ecc];
                    
                    nHat = vect_normVector(cross(kHat, hVect));
                    RAANVectLength = abs(sma.*(1+ecc));
                    nVect = bsxfun(@times, nHat, RAANVectLength);
                    
                    vect = nVect;
                    
                case VehicleStateVectorTypeEnum.Periapsis
                    bodies = getOriginBody(vehElemSet.frame);
                    gmu = [bodies.gm];
                    
                    rVect = [vehElemSet.rVect];
                    vVect = [vehElemSet.vVect];
                    hVect = cross(rVect, vVect);
                    
                    eVect = bsxfun(@rdivide, cross(vVect, hVect), gmu) - vect_normVector(rVect);
                    eHat = vect_normVector(eVect);
                    
                    vehElemSetKep = convertToKeplerianElementSet(vehElemSet);
                    sma = [vehElemSetKep.sma];
                    ecc = [vehElemSetKep.ecc];
                    
                    rP = sma .* (1-ecc);
                    
                    vect = bsxfun(@times, eHat, rP);
                    
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
%             useTf = lvd_EditVehicleStateVectorGUI(obj, obj.lvdData);
            
            output = AppDesignerGUIOutput({false});
            lvd_EditVehicleStateVectorGUI_App(obj, obj.lvdData, output);
            useTf = output.output{1};
        end
        
        function tf = isVehDependent(~)
            tf = true;
        end
        
        function origin = getOriginPointInViewFrame(obj, time, vehElemSet, viewFrame)
            switch obj.type
                case {VehicleStateVectorTypeEnum.AngularMomentum, VehicleStateVectorTypeEnum.East, VehicleStateVectorTypeEnum.North, ...
                      VehicleStateVectorTypeEnum.Velocity}
                    vehElemSet = vehElemSet.convertToFrame(viewFrame);
                    origin = [vehElemSet.rVect];
                    
                case {VehicleStateVectorTypeEnum.AscNode, VehicleStateVectorTypeEnum.Radial, VehicleStateVectorTypeEnum.Periapsis}
                    origin = zeros(3,length(time));
                    
                otherwise
                    error('Unknown vehicle state vector type: %s', string(obj.type));
            end
        end
        
        function tf = usesGroundObj(obj, groundObj)
            tf = false;
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