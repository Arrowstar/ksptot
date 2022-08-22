classdef GeometricPointEnum < matlab.mixin.SetGet
    %GeometricPointEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        FixedInFrame('Fixed in Frame');
        GroundObj('Ground Object Point');
        CelestialBody('Celestial Body Point');
        Vehicle('Vehicle Point');
        TwoBody('Two Body Propagated Point');
        LvdData('LVD Trajectory Point');
        LagrangePoint('Lagrange Point')
    end
    
    properties
        name(1,:) char
    end
    
    methods
        function obj = GeometricPointEnum(name)
            obj.name = name;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('GeometricPointEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('GeometricPointEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('GeometricPointEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end