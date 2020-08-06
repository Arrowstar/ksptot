classdef LaunchVehicleSimplePwrSinkState < AbstractLaunchVehicleElectricalPowerSnkState
    %LaunchVehicleSimplePwrSinkState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
%         stageState = LaunchVehicleStageState.empty(1,0); %(1,1) LaunchVehicleStageState
        
        sink = LaunchVehicleSimplePwrSink.empty(1,0); %(1,1) LaunchVehicleSimplePwrSink
        active(1,1) logical = true;
    end
    
    methods
        function obj = LaunchVehicleSimplePwrSinkState(stageState, sink)
            obj.stageState = stageState;
            obj.sink = sink;
        end
        
        function active = getActiveState(obj)
            active = [obj.active];
        end
        
        function setActiveState(obj,active)
            obj.active = active;
        end
        
        function epsSinkComponent = getEpsSinkComponent(obj)
            epsSinkComponent = [obj.sink];
        end
        
        function pwrRate = getElectricalPwrRate(obj, elemSet, steeringModel, hasSunLoS, body2InertDcm, elemSetSun)
            if(obj.active)
                pwrRate = obj.sink.getElectricalPwrRate(elemSet, steeringModel, hasSunLoS, body2InertDcm, elemSetSun);
            else
                pwrRate = 0;
            end
        end
    end
end