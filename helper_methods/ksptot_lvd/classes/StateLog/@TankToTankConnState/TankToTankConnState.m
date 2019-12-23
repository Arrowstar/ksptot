classdef TankToTankConnState < matlab.mixin.SetGet & matlab.mixin.Copyable
    %TankToTankConnState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        conn(1,1) TankToTankConnection
        active(1,1) logical = true;
        flowRate(1,1) double = 0;
    end
    
    methods
        function obj = TankToTankConnState(conn)
            obj.conn = conn;
        end
        
        function newT2TState = deepCopy(obj)
            newT2TState = obj.copy();
        end
    end
end