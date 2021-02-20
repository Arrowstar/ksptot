classdef SteeringModelEnum < matlab.mixin.SetGet
    %SteeringModelEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        RollPitchYawPoly('Roll/Pitch/Yaw Steering','RollPitchYawPolySteeringModel', true);
        AeroAnglesPoly('Body Fixed Aero Angles Steering','AeroAnglesPolySteeringModel', true);
        InertialAeroAnglesPoly('Inertial Aero Angles Steering','InertialAeroAnglesPolySteeringModel', true);
        GenericPoly('Generic Angles Steering','GenericPolySteeringModel', true);
        
        GenericLinTan('Generic Linear Tangent Angles Steering','GenericLinearTangentSteeringModel', false);
        GenericQuatInterp('Generic Angles Quaternion Interp','GenericQuatInterpSteeringModel', false);
        GenericSumOfSines('Generic Sum of Sines Angles Steering','GenericSumOfSinesSteeringModel', false);
    end
    
    properties
        nameStr char = '';
        classNameStr char = '';
        showInPolyUi(1,1) logical = false;
    end
    
    methods
        function obj = SteeringModelEnum(nameStr,classNameStr,showInPolyUi)
            obj.nameStr = nameStr;
            obj.classNameStr = classNameStr;
            obj.showInPolyUi = showInPolyUi;
        end
    end
    
    methods(Static)
        function steeringModelNameStrs = getSteeringModelTypeNameStrs(showInPylUiMustBe)
            [m,~] = enumeration('SteeringModelEnum');
            m = m([m.showInPolyUi] == showInPylUiMustBe);
            
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