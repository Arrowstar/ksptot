classdef LaunchVehicleEpsRtgState < AbstractLaunchVehicleElectricalPowerSrcState
    %LaunchVehicleEpsRtgState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
%         stageState = LaunchVehicleStageState.empty(1,0); %(1,1) LaunchVehicleStageState
        
        src = LaunchVehicleEpsRtg.empty(1,0); %(1,1) LaunchVehicleEpsRtg
        active(1,1) logical = true;
    end
    
    methods
        function obj = LaunchVehicleEpsRtgState(stageState, src)
            obj.stageState = stageState;
            obj.src = src;
        end
        
        function active = getActiveState(obj)
            active = obj.active;
        end
        
        function setActiveState(obj,active)
            obj.active = active;
        end
        
        function epsSrcComponent = getEpsSrcComponent(obj)
            epsSrcComponent = obj.src;
        end
        
        function pwrRate = getElectricalPwrRate(obj, elemSet, steeringModel)
            pwrRate = obj.src.getElectricalPwrRate(obj, elemSet, steeringModel);
        end
    end
end