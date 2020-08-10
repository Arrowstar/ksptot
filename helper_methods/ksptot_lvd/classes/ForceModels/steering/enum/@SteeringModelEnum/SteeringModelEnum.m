classdef SteeringModelEnum < matlab.mixin.SetGet
    %SteeringModelEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        RollPitchYawPoly('Roll/Pitch/Yaw Steering','RollPitchYawPolySteeringModel');
        AeroAnglesPoly('Body Fixed Aero Angles Steering','AeroAnglesPolySteeringModel');
        InertialAeroAnglesPoly('Inertial Aero Angles Steering','InertialAeroAnglesPolySteeringModel');
        
        GenericPoly('Generic Angles Steering','GenericPolySteeringModel');
        
        GenericQuatInterp('Generic Angles Quaternion Interp','GenericQuatInterpSteeringModel');
    end
    
    properties
        nameStr char = '';
        classNameStr char = '';
    end
    
    methods
        function obj = SteeringModelEnum(nameStr,classNameStr)
            obj.nameStr = nameStr;
            obj.classNameStr = classNameStr;
        end
    end
    
    methods(Static)
        function steeringModelNameStrs = getSteeringModelTypeNameStrs()
            [m,~] = enumeration('SteeringModelEnum');
            
            steeringModelNameStrs = {};
            for(i=1:length(m)) %#ok<*NO4LP>
                steeringModelNameStrs{end+1} = m(i).nameStr; %#ok<AGROW>
            end
        end
        
        function ind = getIndOfListboxStrsForSteeringModel(steeringModel)
            [m,~] = enumeration('SteeringModelEnum');
            inputClass = class(steeringModel);
            
            ind = -1;
            for(i=1:length(m))
                if(strcmpi(m(i).classNameStr,inputClass))
                    ind = i;
                    break;
                end
            end
        end
    end
end