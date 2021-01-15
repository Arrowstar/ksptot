classdef VehicleStateVectorTypeEnum < matlab.mixin.SetGet
    %VehicleStateVectorTypeEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        Radial('Radial Vector');
        Velocity('Velocity Vector');
        AngularMomentum('Angular Momentum Vector');
        North('North Vector');
        East('East Vector');
    end
    
    properties
        name(1,:) char
    end
    
    methods
        function obj = VehicleStateVectorTypeEnum(name)
            obj.name = name;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('VehicleStateVectorTypeEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('VehicleStateVectorTypeEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('VehicleStateVectorTypeEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end