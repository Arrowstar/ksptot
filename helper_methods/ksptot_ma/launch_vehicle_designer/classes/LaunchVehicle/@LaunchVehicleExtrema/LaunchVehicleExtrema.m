classdef LaunchVehicleExtrema < matlab.mixin.SetGet
    %LaunchVehicleExtrema Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lvdData LvdData
        
        quantStr char 
        type(1,1) LaunchVehicleExtremaTypeEnum = LaunchVehicleExtremaTypeEnum.Maximum;
        refBody KSPTOT_BodyInfo
        startingState(1,1) LaunchVehicleExtremaRecordingEnum = LaunchVehicleExtremaRecordingEnum.Recording;
        
        unitStr char
        
        id(1,1) double = 0;
    end
    
    methods
        function obj = LaunchVehicleExtrema(lvdData)
            obj.lvdData = lvdData;
            
            obj.id = rand();
        end
        
        function nameStr = getNameStr(obj)
            nameStr = sprintf('%s %s', obj.type.nameStr, obj.quantStr);
        end
        
        function initState = createInitialState(obj)
            initState = LaunchVehicleExtremaState(obj);
            
            initState.active = obj.startingState;
        end
        
        function tf = isInUse(obj)
            tf = obj.lvdData.usesExtremum(obj);
        end
    end
end