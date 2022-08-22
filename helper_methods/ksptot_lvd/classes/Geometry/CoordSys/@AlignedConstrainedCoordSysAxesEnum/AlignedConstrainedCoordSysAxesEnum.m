classdef AlignedConstrainedCoordSysAxesEnum < matlab.mixin.SetGet
    %AlignedConstrainedCoordSysAxesEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        PosX('+X', [1;0;0], 'X');
        PosY('+Y', [0;1;0], 'Y');
        PosZ('+Z', [0;0;1], 'Z');
        NegX('-X', [-1;0;0], 'X');
        NegY('-Y', [0;-1;0], 'Y');
        NegZ('-Z', [0;0;-1], 'Z');
    end
    
    properties
        name(1,:) char
        vect(3,1) double
        baseAxis(1,:) char
    end
    
    methods
        function obj = AlignedConstrainedCoordSysAxesEnum(name, vect, baseAxis)
            obj.name = name;
            obj.vect = vect;
            obj.baseAxis = baseAxis;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('AlignedConstrainedCoordSysAxesEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('AlignedConstrainedCoordSysAxesEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('AlignedConstrainedCoordSysAxesEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end