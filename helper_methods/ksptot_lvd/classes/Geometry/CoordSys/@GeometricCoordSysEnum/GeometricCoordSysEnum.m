classdef GeometricCoordSysEnum < matlab.mixin.SetGet
    %GeometricCoordSysEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        AlignedConstrained('Aligned/Constrained');
        ParallelToFrame('Parallel To Reference Frame');
    end
    
    properties
        name(1,:) char
    end
    
    methods
        function obj = GeometricCoordSysEnum(name)
            obj.name = name;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('GeometricCoordSysEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('GeometricCoordSysEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('GeometricCoordSysEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end