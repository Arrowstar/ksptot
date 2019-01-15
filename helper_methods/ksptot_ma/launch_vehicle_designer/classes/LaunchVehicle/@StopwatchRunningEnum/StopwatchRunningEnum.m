classdef StopwatchRunningEnum < matlab.mixin.SetGet
    %StopwatchRunningEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        Running('Running',true);
        NotRunning('Not Running',false);
    end
    
    properties
        nameStr char = '';
        value(1,1) logical = false;
    end
    
    methods
        function obj = StopwatchRunningEnum(nameStr, value)
            obj.nameStr = nameStr;
            obj.value = value;
        end
    end
    
    methods(Static)
        function [runningStateStrs, m] = getNameStrs()
            [m,~] = enumeration('StopwatchRunningEnum');
            
            runningStateStrs = {};
            for(i=1:length(m)) %#ok<*NO4LP>
                runningStateStrs{end+1} = m(i).nameStr; %#ok<AGROW>
            end
        end
        
        function ind = getIndOfListboxStrs(runningEnum)
            [m,~] = enumeration('StopwatchRunningEnum');
            
            ind = -1;
            for(i=1:length(m))
                if(m(i) == runningEnum)
                    ind = i;
                    break;
                end
            end
        end
    end
end