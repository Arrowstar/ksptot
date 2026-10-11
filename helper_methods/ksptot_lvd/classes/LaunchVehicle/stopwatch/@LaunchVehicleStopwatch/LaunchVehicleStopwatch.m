classdef LaunchVehicleStopwatch < matlab.mixin.SetGet
    %LaunchVehicleStopwatch Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lvdData LvdData
        
        name char = 'Untitled Stopwatch';
        startOn(1,1) StopwatchRunningEnum = StopwatchRunningEnum.NotRunning;
        startValue(1,1) double = 0;
        
        id(1,1) double = 0;
    end
    
    methods
        function obj = LaunchVehicleStopwatch(lvdData)
            obj.lvdData = lvdData;
            
            obj.startOn = StopwatchRunningEnum.NotRunning;
            
            obj.id = lvdGetNextUniqueId();
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
            %eq Identity by (class, id).  See lvdIdsEqual.
            tf = lvdIdsEqual(A,B);
        end

        function tf = ne(A,B)
            tf = ~lvdIdsEqual(A,B);
        end
    end
end