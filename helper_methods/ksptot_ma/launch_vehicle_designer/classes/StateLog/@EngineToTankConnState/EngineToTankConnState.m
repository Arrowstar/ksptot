classdef EngineToTankConnState < matlab.mixin.SetGet
    %LaunchVehicleState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        conn(1,1) EngineToTankConnection
        active(1,1) logical = true;
    end
    
    methods
        function obj = EngineToTankConnState(conn)
            obj.conn = conn;
        end
        
        function newE2TState = deepCopy(obj)
            newE2TState = EngineToTankConnState(obj.conn);
            newE2TState.active = logical(obj.active);
        end
    end
end