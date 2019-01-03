classdef EngineToTankConnState < matlab.mixin.SetGet & matlab.mixin.Copyable
    %LaunchVehicleState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        conn(1,1) EngineToTankConnection
        active(1,1) logical = true;
    end
    
    properties(Dependent)
        engine(1,1) LaunchVehicleEngine
    end
    
    methods
        function obj = EngineToTankConnState(conn)
            obj.conn = conn;
        end
        
        function value = get.engine(obj)
            value = obj.conn.engine;
        end
        
        function newE2TState = deepCopy(obj)
%             newE2TState = EngineToTankConnState(obj.conn);
            newE2TState = obj.copy();
            newE2TState.active = logical(obj.active);
        end
    end
end