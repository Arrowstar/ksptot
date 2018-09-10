classdef LaunchVehicleStateLog < matlab.mixin.SetGet
    %LaunchVehicle Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        entries(1,:) LaunchVehicleStateLogEntry
    end
    
    methods
        function obj = LaunchVehicleStateLog()
            
        end
        
        function appendStateLogEntries(obj, newStateLogEntries)
            obj.entries = horzcat(obj.entries, newStateLogEntries);
        end
        
        function clearStateLog(obj)
            obj.entries = LaunchVehicleStateLogEntry.empty(1,0);
        end
        
        function stateLog = getMAFormattedStateLogMatrix(obj)
            stateLog = zeros(length(obj.entries), 13);
            for(i=1:length(obj.entries)) %#ok<*NO4LP>
                stateLog(i,:) = obj.entries(i).getMAFormattedStateLogMatrix();
            end
        end
    end
end