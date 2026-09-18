classdef LvdCameraEasingEnum < matlab.mixin.SetGet
    %LvdCameraEasingEnum How the blend fraction is shaped during the
    %transition from one camera keyframe to the next.
    %
    %   Linear     - constant-rate blend.
    %   SmoothStep - 3s^2 - 2s^3: zero rate at both ends, so the camera
    %                starts and stops gently.

    enumeration
        Linear('Linear')
        SmoothStep('Smooth Step')
    end

    properties
        name(1,:) char = '';
    end

    methods
        function obj = LvdCameraEasingEnum(name)
            obj.name = name;
        end
    end

    methods(Static)
        function [listBoxStr, m] = getListBoxStr()
            m = enumeration('LvdCameraEasingEnum');
            listBoxStr = {m.name};
        end

        function [ind, enum] = getIndForName(name)
            m = enumeration('LvdCameraEasingEnum');
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end

        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('LvdCameraEasingEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end
