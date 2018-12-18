classdef LaunchVehicleStopwatchState < matlab.mixin.SetGet & matlab.mixin.Copyable
    %LaunchVehicleStopwatchState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stopwatch LaunchVehicleStopwatch
        value(1,1) double = 0;
        running(1,1) StopwatchRunningEnum = StopwatchRunningEnum.NotRunning;
    end
    
    methods
        function obj = LaunchVehicleStopwatchState(stopwatch)
            obj.stopwatch = stopwatch;
        end
        
        function newState = deepCopy(obj)
            newState = obj.copy();
        end
    end
end