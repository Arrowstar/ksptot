classdef LaunchVehicleStopwatch < matlab.mixin.SetGet
    %LaunchVehicleStopwatch Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lvdData LvdData
        
        name(1,:) char = 'Untitled Stopwatch';
        startOn(1,1) StopwatchRunningEnum = StopwatchRunningEnum.NotRunning;
        startValue(1,1) double = 0;
        
        id(1,1) double = 0;
    end
    
    methods
        function obj = LaunchVehicleStopwatch(lvdData)
            obj.lvdData = lvdData;
            
            obj.startOn = StopwatchRunningEnum.NotRunning;
            
            obj.id = rand();
        end
        
        function initState = createInitialState(obj)
            initState = LaunchVehicleStopwatchState(obj);
            initState.running = obj.startOn;
            initState.value = obj.startValue;
        end
        
        function tf = isInUse(obj)
            tf = obj.lvdData.usesStopwatch(obj);
        end
        
        function tf = eq(A,B)
            tf = [A.id] == [B.id];
        end
    end
end