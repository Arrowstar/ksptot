classdef GeometricVectorEnum < matlab.mixin.SetGet
    %GeometricVectorEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        FixedInFrame('Fixed in Frame');
        TwoPoint('Two Point Vector');
        Scaled('Scaled Vector');
        CrossProd('Cross Product Vector');
        VehicleState('Vehicle State Vector');
        Projected('Projected Vector');
        PlaneToPoint('Plane To Point');
        PointVelocityVector('Point Velocity Vector');
        VectorDifference('Vector Difference');
    end
    
    properties
        name(1,:) char
    end
    
    methods
        function obj = GeometricVectorEnum(name)
            obj.name = name;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('GeometricVectorEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('GeometricVectorEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('GeometricVectorEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end