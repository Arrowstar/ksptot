classdef LvdCameraModeEnum < matlab.mixin.SetGet
    %LvdCameraModeEnum How the 3-D view camera is driven while the time
    %slider moves or playback runs.
    %
    %   Manual   - today's behaviour: the mouse camera handler and the
    %              camera toolbar own the axes camera.
    %   Chase    - the camera sits at a fixed azimuth/elevation/range offset
    %              from the vehicle and looks at it.
    %   Scripted - the camera follows the profile's LvdCameraScript, a list
    %              of keyframes interpolated in time.
    %   FixedAnchor - the camera sits at a fixed anchor point (a fixed XYZ
    %              coordinate in a chosen frame, a ground object, or a
    %              geometric point) and continuously tracks the vehicle, like
    %              a camera on a launch pad or a ground tracking station.

    enumeration
        Manual('Manual')
        Chase('Chase Camera')
        Scripted('Camera Script')
        FixedAnchor('Fixed Camera (Tracking)')
    end

    properties
        name(1,:) char = '';
    end

    methods
        function obj = LvdCameraModeEnum(name)
            obj.name = name;
        end
    end

    methods(Static)
        function [listBoxStr, m] = getListBoxStr()
            m = enumeration('LvdCameraModeEnum');
            listBoxStr = {m.name};
        end

        function [ind, enum] = getIndForName(name)
            m = enumeration('LvdCameraModeEnum');
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end

        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('LvdCameraModeEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end
