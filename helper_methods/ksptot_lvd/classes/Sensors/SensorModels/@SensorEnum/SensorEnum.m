classdef SensorEnum < matlab.mixin.SetGet
    %SensorEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        ConicalSensor('Conical Sensor');
    end
    
    properties
        name(1,:) char
    end
    
    methods
        function obj = SensorEnum(name)
            obj.name = name;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('SensorEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('SensorEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('SensorEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end