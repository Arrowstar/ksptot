classdef EventActionEnum < matlab.mixin.SetGet
    %TerminationConditionEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        SetEngineActiveState('Set Engine Active State','SetEngineActiveStateAction')
        SetStageActiveState('Set Stage Active State','SetStageActiveStateAction');
        SetSteeringModel('Set Steering Model','SetSteeringModelAction');
        SetThrottleModel('Set Throttle Model','SetThrottleModelAction');
        SetEngineToTankState('Set Engine To Tank Connection State','SetEngineTankConnActiveStateEventAction');
        SetHoldDownClampState('Set Hold Down Clamp State','SetHoldDownClampActiveStateAction');
        SetAeroDragProps('Set Drag Aero Properties','SetDragAeroPropertiesAction');
        SetAeroLiftProps('Set Lift Aero Properties','SetLiftAeroPropertiesAction');
    end
    
    properties
        nameStr(1,:) char = '';
        classNameStr(1,:) char = '';
    end
    
    methods
        function obj = EventActionEnum(nameStr, classNameStr)
            obj.nameStr = nameStr;
            obj.classNameStr = classNameStr;
        end
    end
    
    methods(Static)
        function termCondStrs = getActionTypeNameStrs()
            [m,~] = enumeration('EventActionEnum');
            
            termCondStrs = {};
            for(i=1:length(m)) %#ok<*NO4LP>
                termCondStrs{end+1} = m(i).nameStr; %#ok<AGROW>
            end
        end
        
        function ind = getIndOfListboxStrsForAction(action)
            [m,~] = enumeration('EventActionEnum');
            inputClass = class(action);
            
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