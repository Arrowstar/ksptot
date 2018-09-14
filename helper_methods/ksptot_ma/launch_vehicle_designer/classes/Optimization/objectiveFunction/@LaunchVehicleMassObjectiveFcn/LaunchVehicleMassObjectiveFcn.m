classdef LaunchVehicleMassObjectiveFcn < AbstractObjectiveFcn
    %AbstractObjectiveFcn Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        event(1,:) LaunchVehicleEvent 
        
        lvdOptim LvdOptimization
        lvdData LvdData
    end
    
    methods
        function obj = LaunchVehicleMassObjectiveFcn(event, lvdOptim, lvdData)
            obj.event = event;
            obj.lvdOptim = lvdOptim;
            obj.lvdData = lvdData;
        end
        
        function [f, stateLog] = evalObjFcn(obj, x, ~,~)
            obj.lvdOptim.vars.updateObjsWithVarValues(x);
            stateLog = obj.lvdData.script.executeScript();
            
            subStateLog = stateLog.getLastStateLogForEvent(obj.event);
            f = subStateLog.getTotalVehicleMass();
        end
    end
end