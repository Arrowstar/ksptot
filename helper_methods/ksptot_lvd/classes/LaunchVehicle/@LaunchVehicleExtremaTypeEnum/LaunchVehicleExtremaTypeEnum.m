classdef LaunchVehicleExtremaTypeEnum < matlab.mixin.SetGet
    %LaunchVehicleExtremaTypeEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        Maximum('Maximum');
        Minimum('Minimum');
    end
    
    properties
        nameStr char = '';
    end
    
    methods
        function obj = LaunchVehicleExtremaTypeEnum(nameStr)
            obj.nameStr = nameStr;
        end
    end
    
    methods(Static)
        function [nameStrs, m] = getNameStrs()
            [m,~] = enumeration('LaunchVehicleExtremaTypeEnum');
            
            nameStrs = {};
            for(i=1:length(m)) %#ok<*NO4LP>
                nameStrs{end+1} = m(i).nameStr; %#ok<AGROW>
            end
        end
        
        function [ind, mI] = getIndOfListboxStrs(recordingEnum)
            [m,~] = enumeration('LaunchVehicleExtremaTypeEnum');
            
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