classdef DeltaVParamTypeEnum < matlab.mixin.SetGet
    %DeltaVParamTypeEnum How an AddDeltaVAction stores its three delta-v numbers.
    %
    %   Cartesian: deltaVVect holds the three frame components (km/s).
    %   Polar:     deltaVVect holds [magnitude (km/s); in-plane angle (rad);
    %              out-of-plane angle (rad)].  The frame components are
    %              mag*[cos(oop)*cos(ip); cos(oop)*sin(ip); sin(oop)], i.e. the
    %              in-plane angle is measured from the frame's first axis toward
    %              its second, and the out-of-plane angle toward the third.

    enumeration
        Cartesian('Cartesian Components');
        Polar('Magnitude / Angles');
    end

    properties
        nameStr char = '';
    end

    methods
        function obj = DeltaVParamTypeEnum(nameStr)
            obj.nameStr = nameStr;
        end
    end

    methods(Static)
        function [listBoxStr, m] = getListBoxStr()
            m = enumeration('DeltaVParamTypeEnum');
            listBoxStr = {m.nameStr};
        end

        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('DeltaVParamTypeEnum');
            ind = find(ismember({m.nameStr},nameStr),1,'first');
            enum = m(ind);
        end

        function [ind, enum] = getIndForName(nameStr)
            [enum, ind] = DeltaVParamTypeEnum.getEnumForListboxStr(nameStr);
        end
    end
end
