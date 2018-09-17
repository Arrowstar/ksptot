classdef MaximizeLaunchVehicleMassObjectiveFcn < AbstractObjectiveFcn
    %AbstractObjectiveFcn Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        event(1,:) LaunchVehicleEvent 
        
        lvdOptim LvdOptimization
        lvdData LvdData
    end
    
    methods
        function obj = MaximizeLaunchVehicleMassObjectiveFcn(event, lvdOptim, lvdData)
            obj.event = event;
            obj.lvdOptim = lvdOptim;
            obj.lvdData = lvdData;
        end
        
        function [f, stateLog] = evalObjFcn(obj, x, ~,~)
            if(any(isnan(x)))
                a = 1;
            end
            
            obj.lvdOptim.vars.updateObjsWithVarValues(x);
            stateLog = obj.lvdData.script.executeScript();
            
            subStateLog = stateLog.getLastStateLogForEvent(obj.event);
            f = -1*subStateLog.getTotalVehicleMass();
            
            if(any(isnan(f)))
                a = 1;
            end
        end
    end
end