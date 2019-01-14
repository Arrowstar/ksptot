classdef LaunchVehicleStopwatchState < matlab.mixin.SetGet & matlab.mixin.Copyable
    %LaunchVehicleStopwatchState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stopwatch LaunchVehicleStopwatch
        value(1,1) double = 0;
        running(1,1) StopwatchRunningEnum = StopwatchRunningEnum.NotRunning;
        
        id(1,1) double = 0;
    end
    
    methods
        function obj = LaunchVehicleStopwatchState(stopwatch)
            obj.stopwatch = stopwatch;
            
            obj.id = rand();
        end
        
        function newState = deepCopy(obj)
            newState = obj.copy();
            newState.id = rand();
        end
    end
end