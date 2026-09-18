classdef LvdCameraKeyframeRefEnum < matlab.mixin.SetGet
    %LvdCameraKeyframeRefEnum What a camera keyframe's pose is expressed in.
    %
    %   SceneFixed      - camera position, target and up vector are stored
    %                     as coordinates in the view frame.
    %   VehicleRelative - the camera sits at an azimuth/elevation/range
    %                     offset from the vehicle and looks at it (a chase
    %                     shot that moves with the vehicle).
    %   FixedAnchorTracking - the camera sits at a fixed anchor (fixed XYZ in
    %                     a chosen frame, a ground object, or a geometric
    %                     point) and continuously tracks the vehicle, exactly
    %                     like the profile-level Fixed Camera (Tracking) mode.

    enumeration
        SceneFixed('Scene-Fixed')
        VehicleRelative('Vehicle-Relative (Chase)')
        FixedAnchorTracking('Fixed Camera (Tracking)')
    end

    properties
        name(1,:) char = '';
    end

    methods
        function obj = LvdCameraKeyframeRefEnum(name)
            obj.name = name;
        end
    end

    methods(Static)
        function [listBoxStr, m] = getListBoxStr()
            m = enumeration('LvdCameraKeyframeRefEnum');
            listBoxStr = {m.name};
        end

        function [ind, enum] = getIndForName(name)
            m = enumeration('LvdCameraKeyframeRefEnum');
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end

        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('LvdCameraKeyframeRefEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end
