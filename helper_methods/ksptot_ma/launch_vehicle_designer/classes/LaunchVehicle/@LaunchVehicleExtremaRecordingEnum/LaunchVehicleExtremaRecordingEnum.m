classdef LaunchVehicleExtremaRecordingEnum < matlab.mixin.SetGet
    %LaunchVehicleExtremaRecordingEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        Recording('Recording',true);
        NotRecording('Not Recording',false);
    end
    
    properties
        nameStr(1,:) char = '';
        value(1,1) logical = false;
    end
    
    methods
        function obj = LaunchVehicleExtremaRecordingEnum(nameStr, value)
            obj.nameStr = nameStr;
            obj.value = value;
        end
    end
    
    methods(Static)
        function [recordingStateStrs, m] = getNameStrs()
            [m,~] = enumeration('LaunchVehicleExtremaRecordingEnum');
            
            recordingStateStrs = {};
            for(i=1:length(m)) %#ok<*NO4LP>
                recordingStateStrs{end+1} = m(i).nameStr; %#ok<AGROW>
            end
        end
        
        function [ind, mI] = getIndOfListboxStrs(recordingEnum)
            [m,~] = enumeration('LaunchVehicleExtremaRecordingEnum');
            
            ind = -1;
            mI = [];
            for(i=1:length(m))
                if(m(i) == recordingEnum)
                    ind = i;
                    mI = m(i);
                    break;
                end
            end
        end
    end
end