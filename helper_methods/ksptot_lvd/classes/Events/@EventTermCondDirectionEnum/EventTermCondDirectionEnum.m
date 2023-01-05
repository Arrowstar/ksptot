classdef EventTermCondDirectionEnum < matlab.mixin.SetGet
    %EventTermCondDirectionEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        NoDir('Either Increasing or Decreasing',0)
        Increasing('Increasing at Value',1)
        Decreasing('Decreasing at Value',-1)
    end
    
    properties
        name char = '';
        direction(1,1) double = 0;
    end
    
    methods
        function obj = EventTermCondDirectionEnum(name,direction)
            obj.name = name;
            obj.direction = direction;
        end
    end
    
    methods(Static)
        function listBoxStr = getListboxStr()
            m = enumeration('EventTermCondDirectionEnum');
            listBoxStr = {m.name};
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('EventTermCondDirectionEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end