classdef ObjFcnCompositeMethodEnum < matlab.mixin.SetGet
    %ObjFcnCompositeMethodEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        Sum('Sum (J1 + J2 + ...)');
        RSS('RSS (sqrt(J1^2 + J2^2 + ...))');
        MaxJ('Max Value (max(J1, J2, ...))');
        MinJ('Min Value (min(J1, J2, ...))');
    end
    
    properties
        name(1,:) char
    end
    
    methods
        function obj = ObjFcnCompositeMethodEnum(name)
            obj.name = name;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('ObjFcnCompositeMethodEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('ObjFcnCompositeMethodEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
    end
end